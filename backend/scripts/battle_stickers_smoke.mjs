// Public REST/native STOMP only; called by the isolated JAR and Compose runners.
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';

export async function verifyBattleStickers({base, register, Stomp, request, snapshot}) {
  const a = await register(), b = await register(), outsider = await register();
  const sa = await new Stomp(a).connect(), sb = await new Stomp(b).connect(), sc = await new Stomp(outsider).connect();
  const create = async () => {
    const room = await request('POST', '/api/v1/duels', a, {disciplineCode: 'SAT_RW', format: 'STANDARD'}, 201);
    return (await request('POST', '/api/v1/duels/join', b, {code: room.code})).battleId;
  };
  const id = await create(), path = `/api/v1/battles/${id}/stickers`;
  const before = await snapshot(id, a), submission = {stickerId: 'gg', submissionId: randomUUID()};
  await request('POST', path, null, submission, 401);
  await request('POST', path, outsider, submission, 404);
  assert.equal((await request('POST', path, a, {...submission, stickerId: 'GG'}, 400)).code, 'INVALID_STICKER_ID');
  await request('POST', path, a, {...submission, targetUserId: outsider.user.id}, 400);
  const response = await fetch(base + path, {method: 'POST', headers: {Authorization: 'Bearer ' + a.accessToken, 'Content-Type': 'application/json'}, body: JSON.stringify(submission)});
  assert.equal(response.status, 200); assert.equal(response.headers.get('cache-control'), 'no-store');
  const ack = await response.json();
  assert.deepEqual(Object.keys(ack).sort(), ['battleId', 'submissionId', 'senderUserId', 'stickerId', 'sentAt', 'nextAllowedAt'].sort());
  assert.equal(Date.parse(ack.nextAllowedAt) - Date.parse(ack.sentAt), 4000);
  const isSticker = e => e.type === 'BATTLE_STICKER';
  const event = await sb.event(isSticker);
  assert.equal(event.version, 1); assert.equal(event.resourceId, id); assert.equal(event.occurredAt, ack.sentAt);
  assert.deepEqual(event.data, {battleId: id, submissionId: submission.submissionId, senderUserId: a.user.id, stickerId: 'gg', sentAt: ack.sentAt});
  assert.deepEqual(await request('POST', path, a, submission), ack);
  assert.equal((await request('POST', path, a, {...submission, stickerId: 'lol'}, 409)).code, 'IDEMPOTENCY_CONFLICT');
  const early = await fetch(base + path, {method: 'POST', headers: {Authorization: 'Bearer ' + a.accessToken, 'Content-Type': 'application/json'}, body: JSON.stringify({stickerId: 'fire', submissionId: randomUUID()})});
  assert.equal(early.status, 429); assert(Number(early.headers.get('retry-after')) >= 1);
  const error = await early.json(); assert.equal(error.code, 'STICKER_COOLDOWN'); assert.equal(error.resetsAt, ack.nextAllowedAt);
  await request('POST', path, b, {stickerId: 'fire', submissionId: randomUUID()});
  assert.equal((await sa.event(isSticker)).version, 2);
  const after = await snapshot(id, a);
  delete before.serverTime; delete after.serverTime;
  assert.deepEqual(after, before);
  await request('POST', `/api/v1/battles/${id}/surrender`, a);
  assert.deepEqual(await request('POST', path, a, submission), ack);
  assert.equal((await request('POST', path, b, {stickerId: 'gg', submissionId: randomUUID()}, 409)).code, 'STICKERS_NOT_ALLOWED');
  // All preceding HTTP round trips let the local broker drain; no sender retry echo or public delivery.
  assert(!sa.events.some(isSticker)); assert(!sb.events.some(isSticker)); assert(!sc.events.some(isSticker));
  await sa.close(); await sb.close(); await sc.close();
  console.log('Stickers: REST ACK/429/no-store, native opponent-only STOMP, independent sequence, retries/conflict/terminal and unchanged snapshot passed.');
  return async () => {
    assert.equal((await request('POST', path, a, submission, 409)).code, 'STICKERS_NOT_ALLOWED');
    const freshBattle = await create();
    const fresh = await request('POST', `/api/v1/battles/${freshBattle}/stickers`, a, submission);
    assert.equal(fresh.battleId, freshBattle);
    await request('POST', `/api/v1/battles/${freshBattle}/surrender`, a);
    console.log('Stickers: JAR restart cleared retained receipts; persisted terminal battle still rejects new sends, no history/replay.');
  };
}
