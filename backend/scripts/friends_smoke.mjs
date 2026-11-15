import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';

// Uses only public REST and the existing native STOMP client on disposable accounts.
export async function startFriendsScenario({base, register, Stomp}) {
  async function call(method, path, auth, body, status=200) {
    const headers = {Authorization: 'Bearer ' + auth.accessToken};
    if (body !== undefined) headers['Content-Type'] = 'application/json';
    const r = await fetch(base + '/api/v1' + path, {method, headers, body: body === undefined ? undefined : JSON.stringify(body), signal: AbortSignal.timeout(8000)});
    assert.equal(r.status,status,method+' '+path);
    assert.equal(r.headers.get('cache-control'),'no-store');
    return status===204 ? null : r.json();
  }
  const get=(path,a,status)=>call('GET',path,a,undefined,status);
  const post=(path,a,body,status)=>call('POST',path,a,body,status);
  const a=await register(), b=await register(), c=await register(), d=await register();
  const sa=await new Stomp(a).connect(), sb=await new Stomp(b).connect(), sc=await new Stomp(c).connect();
  const aCode=(await get('/users/me/friend-code',a)).friendCode;
  const bCode=(await get('/users/me/friend-code',b)).friendCode;
  assert.match(aCode,/^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{12}$/);
  assert.equal((await get('/users/me/friend-code',a)).friendCode,aCode);
  const request=await post('/friend-requests',a,{friendCode:bCode.toLowerCase().replace(/(.{4})(?=.)/g,'$1-')},201);
  const event=await sb.event(e=>e.type==='FRIENDSHIP_CHANGED'&&e.resourceId===request.id);
  assert.equal(event.version,event.data.version); assert.equal(event.data.status,'PENDING');
  await sa.event(e=>e.type==='FRIENDSHIP_CHANGED'&&e.resourceId===request.id);
  assert(!sc.events.some(e=>e.type==='FRIENDSHIP_CHANGED'&&e.resourceId===request.id));
  assert.deepEqual(await post('/friend-requests',a,{friendCode:bCode}),request);
  await get('/friend-requests/'+request.id,c,404);
  await post('/friend-requests/'+request.id+'/accept',a,undefined,403);
  const accepted=await post('/friend-requests/'+request.id+'/accept',b);
  assert.deepEqual(await post('/friend-requests/'+request.id+'/accept',b),accepted);
  assert.equal((await get('/friends?page=0&size=1',a)).data[0].friend.id,b.user.id);
  assert.equal((await get('/friend-requests?direction=OUTGOING',a)).data.length,0);
  function basic(profile) {
    assert.deepEqual(Object.keys(profile).sort(),['friend','friendsSince','disciplines'].sort());
    assert(!/"(?:email|birthYear|friendCode|entitlements|topicStats|ratingHistory|streak)"/.test(JSON.stringify(profile)));
    for(const discipline of profile.disciplines) {
      assert.equal(discipline.ranked.played,0);assert.equal(discipline.ranked.winRatePercent,null);
      assert.equal(discipline.ranked.accuracyPercent,null);assert.equal(discipline.ranked.avgAnswerTimeMs,null);
    }
  }
  basic(await get('/friends/'+b.user.id,a));await get('/friends/'+b.user.id,c,404);
  const cancelled=await post('/friend-requests',d,{friendCode:aCode},201);
  await call('DELETE','/friend-requests/'+cancelled.id,d,undefined,204);
  assert.equal((await get('/friend-requests/'+cancelled.id,a)).status,'CANCELLED');
  const declined=await post('/friend-requests',c,{friendCode:aCode},201);
  assert.equal((await post('/friend-requests/'+declined.id+'/decline',a)).status,'DECLINED');
  // Test both-way removal on an independent pair without waiting for cooldowns.
  const dCode=(await get('/users/me/friend-code',d)).friendCode;
  const ad=await post('/friend-requests',b,{friendCode:dCode},201);
  await post('/friend-requests/'+ad.id+'/accept',d);
  await call('DELETE','/friends/'+b.user.id,d,undefined,204);
  await get('/friends/'+d.user.id,b,404);
  const room=()=>post('/duels',a,{disciplineCode:'SAT_MATH',format:'STANDARD'},201);
  const invite=(r,requestId=randomUUID())=>post('/duels/'+r.id+'/invitations',a,{friendId:b.user.id,requestId},201);
  let r=await room();let i=await invite(r);
  await get('/duels/'+r.id,b,404);await get('/duels/'+r.id+'/invitations',b,404);
  assert.equal((await get('/users/me/duel-invitations',b)).data[0].id,i.id);
  await call('DELETE','/duel-invitations/'+i.id,a,undefined,204);
  assert.equal((await get('/duel-invitations/'+i.id,b)).reason,'SENDER_CANCELLED');
  assert.equal((await get('/duels/'+r.id,a)).status,'WAITING');
  await call('DELETE','/duels/'+r.id,a,undefined,204);
  r=await room();i=await invite(r);
  assert.equal((await post('/duel-invitations/'+i.id+'/decline',b)).status,'DECLINED');
  await call('DELETE','/duels/'+r.id,a,undefined,204);
  r=await room();const intent=randomUUID();i=await invite(r,intent);
  const notification=await sb.event(e=>e.type==='DUEL_INVITATION_CHANGED'&&e.resourceId===i.id&&e.data.status==='PENDING');
  assert.equal(notification.data.duelId,r.id);assert(!('code' in notification.data));
  assert.equal((await post('/duels/'+r.id+'/invitations',a,{friendId:b.user.id,requestId:intent})).expiresAt,i.expiresAt);
  await get('/duel-invitations/'+i.id,c,404);
  const joined=await post('/duel-invitations/'+i.id+'/accept',b);
  assert.equal(joined.duelId,r.id);assert(joined.battleId);
  assert.equal((await post('/duel-invitations/'+i.id+'/accept',b)).battleId,joined.battleId);
  assert.equal((await get('/duels/'+r.id,a)).battleId,joined.battleId);
  assert.equal((await get('/battles/'+joined.battleId,b)).phase,'WAITING_READY');
  await call('DELETE','/duel-invitations/'+i.id,a,undefined,409);
  await post('/battles/'+joined.battleId+'/surrender',a);
  const pendingRoom=await room(),pendingInvite=await invite(pendingRoom);
  const cb=await post('/friend-requests',c,{friendCode:bCode},201);await post('/friend-requests/'+cb.id+'/accept',b);
  const cRoom=await post('/duels',c,{disciplineCode:'SAT_MATH',format:'STANDARD'},201);
  const cInvite=await post('/duels/'+cRoom.id+'/invitations',c,{friendId:b.user.id,requestId:randomUUID()},201);
  const persisted=await post('/duel-invitations/'+cInvite.id+'/accept',b);
  const cCode=(await get('/users/me/friend-code',c)).friendCode;
  const pendingRequest=await post('/friend-requests',d,{friendCode:cCode},201);
  // Reconnect restores the same pending invitation without result/room subscriptions.
  await sb.close();const recovered=await new Stomp(b).connect();
  assert.equal((await get('/users/me/duel-invitations',b)).data[0].expiresAt,pendingInvite.expiresAt);
  assert(!sc.events.some(e=>e.type==='DUEL_INVITATION_CHANGED'&&e.resourceId===pendingInvite.id));
  await sa.close();await recovered.close();await sc.close();
  console.log('Friends REST/STOMP: code, pending/accepted/declined/cancelled/removed relations, basic profile privacy, personal events, existing-room invites, retry, decline/withdraw/accept and reconnect passed.');
  return async()=>{
    assert.equal((await get('/users/me/friend-code',a)).friendCode,aCode);
    assert.equal((await get('/friend-requests/'+request.id,b)).status,'ACCEPTED');
    assert.equal((await get('/friend-requests/'+pendingRequest.id,c)).status,'PENDING');
    assert((await get('/friends',a)).data.some(item=>item.friend.id===b.user.id));
    assert.equal((await get('/users/me/duel-invitations',b)).data.length,0);
    await get('/duel-invitations/'+pendingInvite.id,b,404);await get('/duels/'+pendingRoom.id,a,404);
    const state=await get('/battles/'+persisted.battleId,b);assert.equal(state.phase,'CANCELLED');assert.equal(state.result.reason,'SERVER_INTERRUPTION');
    assert.equal((await get('/users/me/activity',b)).type,'NONE');
    console.log('Friends restart: stable codes/relationships/pending requests persisted; pending rooms/invitations lost; accepted battle recovered through the existing snapshot/activity flow.');
  };
}
