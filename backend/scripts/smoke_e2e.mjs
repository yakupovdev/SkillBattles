// Internal runner for verify_e2e.py. Only public gameplay APIs and native STOMP are used.
import assert from 'node:assert/strict';
import {readFile, writeFile} from 'node:fs/promises';
import {createInterface} from 'node:readline';
import {randomUUID} from 'node:crypto';

const base = process.env.SKILLBATTLES_E2E_BASE_URL;
if (!base || !process.env.SKILLBATTLES_E2E_FIXTURE || !process.env.SKILLBATTLES_E2E_REVISION) {
  throw new Error('Run scripts/verify_e2e.py to create the isolated test environment.');
}
assert(['127.0.0.1', 'localhost'].includes(new URL(base).hostname));
const fixture = JSON.parse(await readFile(process.env.SKILLBATTLES_E2E_FIXTURE, 'utf8'));
const input = createInterface({input: process.stdin});
const sockets = [];
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
const token = auth => typeof auth === 'string' ? auth : auth?.accessToken;

async function raw(method, path, auth, body) {
  const headers = {};
  if (auth) headers.Authorization = 'Bearer ' + token(auth);
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  const response = await fetch(base + path, {method, headers, body: body === undefined ? undefined : JSON.stringify(body), signal: AbortSignal.timeout(8000)});
  const text = await response.text();
  return {status: response.status, data: text ? JSON.parse(text) : null};
}
async function request(method, path, auth, body, expected = 200) {
  const response = await raw(method, path, auth, body);
  if (response.status !== expected) throw new Error(`${method} ${path}: ${response.status}, expected ${expected}; ${response.data?.code ?? ''}`);
  return response.data;
}
async function register() {
  const suffix = randomUUID().replaceAll('-', '').slice(0, 12);
  return request('POST', '/api/v1/auth/register', null, {email: suffix + '@example.com', nickname: 'Demo_' + suffix, password: 'IsolatedDemo123!'}, 201);
}
class Stomp {
  constructor(auth) {
    this.events = []; this.frames = []; this.pending = ''; this.auth = auth;
    this.ws = new WebSocket(base.replace(/^http/, 'ws') + '/ws/v1/events', ['v12.stomp']);
    this.ws.addEventListener('open', () => this.ws.send('CONNECT\naccept-version:1.2\nhost:localhost\nheart-beat:5000,5000\nAuthorization:Bearer ' + auth.accessToken + '\n\n\0'));
    this.ws.addEventListener('message', message => {
      this.pending += message.data;
      let end;
      while ((end = this.pending.indexOf('\0')) >= 0) {
        const frame = this.pending.slice(0, end).trimStart().replaceAll('\r\n', '\n');
        this.pending = this.pending.slice(end + 1);
        if (!frame) continue;
        const split = frame.indexOf('\n\n');
        const command = frame.split('\n')[0];
        const body = split < 0 ? '' : frame.slice(split + 2);
        if (command === 'MESSAGE') this.events.push(JSON.parse(body));
        else this.frames.push({command, body});
      }
      if (!this.pending.trim()) this.pending = '';
    });
    this.ws.addEventListener('error', () => { this.failed = true; });
    this.ws.addEventListener('close', () => { this.closed = true; clearInterval(this.heartbeat); });
    sockets.push(this);
  }
  async connect() {
    await this.until(() => this.frames.find(frame => frame.command === 'CONNECTED'));
    this.heartbeat = setInterval(() => { if (this.ws.readyState === WebSocket.OPEN) this.ws.send('\n'); }, 1000);
    this.ws.send('SUBSCRIBE\nid:events\ndestination:/user/queue/events\nack:auto\n\n\0');
    return this;
  }
  async until(predicate) {
    const until = Date.now() + 8000;
    while (Date.now() < until) {
      const error = this.frames.find(frame => frame.command === 'ERROR');
      if (error) throw new Error('STOMP ERROR: ' + JSON.parse(error.body).code);
      const result = predicate();
      if (result) return result;
      if (this.failed) throw new Error('WebSocket connection failed');
      await pause(10);
    }
    throw new Error('Timed out waiting for STOMP transition');
  }
  async event(predicate) {
    return this.until(() => { const index = this.events.findIndex(predicate); return index < 0 ? null : this.events.splice(index, 1)[0]; });
  }
  async close() {
    clearInterval(this.heartbeat);
    if (this.ws.readyState === WebSocket.OPEN) this.ws.close();
    await this.until(() => this.closed);
  }
}
const get = (path, auth, expected = 200) => request('GET', path, auth, undefined, expected);
const snapshot = (id, auth) => get('/api/v1/battles/' + id, auth);
const battleEvent = (socket, id, phase, number) => socket.event(event => event.type === 'BATTLE_CHANGED' && event.resourceId === id && event.data.phase === phase && (number === undefined || event.data.round?.number === number));
async function ready(id, auth) {
  const until = Date.now() + 5000;
  do {
    const response = await raw('POST', '/api/v1/battles/' + id + '/readiness', auth, {ready: true});
    if (response.status === 200) return response.data;
    if (response.data?.code !== 'REALTIME_CONNECTION_REQUIRED') throw new Error('Readiness failed: ' + response.data?.code);
    await pause(10);
  } while (Date.now() < until);
  throw new Error('Subscription did not establish readiness presence');
}
function answerBody(state, correct) {
  const source = fixture.find(item => item.prompt === state.round.question.prompt);
  assert(source, 'Question must come from the explicit test-only fixture');
  const correctText = source.options.find(option => option.key === source.correctOptionKey).text;
  const option = state.round.question.options.find(option => (option.text === correctText) === correct);
  return {roundId: state.round.id, optionId: option.id, submissionId: randomUUID()};
}
const submit = (id, auth, body, expected = 200) => request('POST', '/api/v1/battles/' + id + '/answers', auth, body, expected);
const result = (id, auth) => get('/api/v1/battles/' + id + '/result', auth);
const review = (id, auth) => get('/api/v1/battles/' + id + '/review', auth);
const history = auth => get('/api/v1/users/me/battles', auth);
const activity = auth => get('/api/v1/users/me/activity', auth);
const ownResult = (value, auth) => value.players.find(player => player.id === auth.user.id);
function privateShape(value) {
  const serialized = JSON.stringify(value);
  assert(!/"(?:email|password|passwordHash|accessToken|refreshToken|sessionId|submissionId|acceptedAt)"/.test(serialized));
}
async function consistency(id, auth) {
  const saved = await result(id, auth);
  const item = (await history(auth)).data.find(item => item.battleId === id);
  const own = ownResult(saved, auth);
  assert(item); assert.equal(item.outcome, saved.myOutcome); assert.equal(item.reason, saved.reason);
  assert.equal(item.myScore, own.score); assert.equal(item.ratingDelta, own.ratingDelta); assert.equal(item.finishedAt, saved.finishedAt);
  privateShape(saved); privateShape(item); privateShape(await review(id, auth));
  return saved;
}

try {
  const api = await get('/v3/api-docs', null);
  for (const path of ['/api/v1/users/me/battles', '/api/v1/battles/{id}/review']) {
    assert(api.paths[path].get.responses['200']); assert(api.paths[path].get.security.some(item => 'accessBearer' in item));
  }
  for (const [name, fields] of Object.entries({
    BattleReview: ['battleId', 'subject', 'mode', 'rounds'],
    BattleHistoryItem: ['battleId', 'subject', 'mode', 'outcome', 'reason', 'opponent', 'myScore', 'opponentScore', 'ratingDelta', 'createdAt', 'finishedAt'],
    BattleHistoryPage: ['data', 'pagination']
  })) {
    assert.deepEqual(Object.keys(api.components.schemas[name].properties).sort(), [...fields].sort());
    assert.deepEqual([...api.components.schemas[name].required].sort(), [...fields].sort());
  }
  await get('/api/v1/users/me/battles', null, 401);
  const a = await register(), b = await register(), third = await register();
  assert.equal((await get('/api/v1/users/me', a)).id, a.user.id);
  let sa = await new Stomp(a).connect(); const sb = await new Stomp(b).connect(); const sc = await new Stomp(third).connect();
  const entry = await request('POST', '/api/v1/matchmaking/entries', a, {subject: 'MATH'}, 201);
  const match = await request('POST', '/api/v1/matchmaking/entries', b, {subject: 'MATH'}, 201);
  const ranked = match.battleId;
  assert.equal(match.status, 'MATCHED');
  for (const auth of [a, b]) assert.deepEqual(await activity(auth), {type: 'BATTLE', resourceId: ranked, battleId: ranked});
  assert.equal((await get('/api/v1/matchmaking/entries/' + entry.id, a)).battleId, ranked);
  await ready(ranked, a); await ready(ranked, b);
  await battleEvent(sa, ranked, 'COUNTDOWN');
  for (let number = 1; number <= 2; number++) {
    await battleEvent(sa, ranked, 'QUESTION', number);
    const state = await snapshot(ranked, a); const other = await snapshot(ranked, b);
    assert.deepEqual(state.round.question, other.round.question);
    assert.equal(state.round.deadline, other.round.deadline);
    const answer = answerBody(state, true);
    const receipt = await submit(ranked, a, answer);
    assert.deepEqual(await submit(ranked, a, answer), receipt);
    assert(!('correct' in receipt));
    const changed = {...answer, optionId: answerBody(state, false).optionId};
    assert.equal((await submit(ranked, a, changed, 409)).code, 'IDEMPOTENCY_CONFLICT');
    assert.equal((await submit(ranked, a, {...changed, submissionId: randomUUID()}, 409)).code, 'ANSWER_ALREADY_SUBMITTED');
    const hidden = await sb.event(event => event.type === 'BATTLE_CHANGED' && event.resourceId === ranked && event.data.phase === 'QUESTION' && event.data.round.number === number && event.data.players.find(player => player.id === a.user.id).answeredCurrentRound);
    assert.equal(hidden.data.round.reveal, null); assert.equal(hidden.data.round.mySelectedOptionId, null);
    assert(!JSON.stringify(hidden).includes('correctOptionId'));
    await get('/api/v1/battles/' + ranked + '/review', a, 409);
    if (number === 2) {
      const deadline = state.round.deadline;
      await sa.close();
      await sb.event(event => event.resourceId === ranked && event.data.players?.find(player => player.id === a.user.id)?.connected === false);
      sa = await new Stomp(a).connect();
      await sb.event(event => event.resourceId === ranked && event.data.players?.find(player => player.id === a.user.id)?.connected === true);
      assert.equal((await activity(a)).battleId, ranked);
      const resumed = await snapshot(ranked, a);
      assert.equal(resumed.round.deadline, deadline); assert.equal(resumed.round.mySelectedOptionId, answer.optionId);
      assert.deepEqual(await submit(ranked, a, answer), receipt);
    }
    await submit(ranked, b, answerBody(state, false));
    const reveal = await battleEvent(sb, ranked, 'REVEAL', number);
    assert.equal(reveal.data.round.reveal.answers.length, 2);
  }
  await battleEvent(sb, ranked, 'FINISHED');
  const rankedResult = await consistency(ranked, a);
  assert.equal(rankedResult.myOutcome, 'WIN'); assert.equal(ownResult(rankedResult, a).ratingDelta, 16);
  assert.equal(ownResult(await consistency(ranked, b), b).ratingDelta, -16);
  assert.equal((await history(a)).data.length, 1);
  for (const path of ['review', 'result']) await get('/api/v1/battles/' + ranked + '/' + path, third, 404);
  await get('/api/v1/battles/' + ranked, third, 404);
  assert.equal((await history(third)).data.length, 0); assert.equal(sc.events.length, 0);
  console.log('Ranked REST/STOMP: search, ready, questions, reveal, retry/conflict, reconnect, result/history/review and privacy passed.');

  const room = await request('POST', '/api/v1/duels', a, {subject: 'MATH'}, 201);
  const joined = await request('POST', '/api/v1/duels/join', b, {code: ' ' + room.code.toLowerCase() + ' '});
  const privateId = joined.battleId;
  await ready(privateId, a); await ready(privateId, b);
  for (let number = 1; number <= 2; number++) {
    await battleEvent(sa, privateId, 'QUESTION', number);
    const state = await snapshot(privateId, a);
    await submit(privateId, a, answerBody(state, true)); await submit(privateId, b, answerBody(state, true));
    await battleEvent(sb, privateId, 'REVEAL', number);
  }
  await battleEvent(sb, privateId, 'FINISHED');
  for (const auth of [a, b]) assert((await consistency(privateId, auth)).players.every(player => player.ratingDelta === 0));
  const surrenderRoom = await request('POST', '/api/v1/duels', a, {subject: 'ENGLISH'}, 201);
  const surrenderId = (await request('POST', '/api/v1/duels/join', b, {code: surrenderRoom.code})).battleId;
  await ready(surrenderId, a); await ready(surrenderId, b); await battleEvent(sa, surrenderId, 'QUESTION', 1);
  const unfinished = await snapshot(surrenderId, a);
  await submit(surrenderId, a, answerBody(unfinished, true));
  await request('POST', '/api/v1/battles/' + surrenderId + '/surrender', b);
  const partial = await review(surrenderId, a);
  assert.equal(partial.rounds.length, 1); assert.equal(partial.rounds[0].completed, false); assert.equal(partial.rounds[0].answers.length, 1);
  assert(partial.rounds[0].answers[0].points >= 1000);
  const surrendered = await consistency(surrenderId, a);
  assert.equal(surrendered.reason, 'SURRENDER'); assert(surrendered.players.every(player => player.score === 0 && player.ratingDelta === 0));
  const savedHistory = await history(a);
  const savedReviews = new Map(); const savedResults = new Map();
  for (const id of [ranked, privateId, surrenderId]) { savedReviews.set(id, await review(id, a)); savedResults.set(id, await result(id, a)); }
  const statsBefore = await get('/api/v1/users/me/statistics', a);
  assert.equal(statsBefore.subjects.find(item => item.subject === 'MATH').rating, 1016);
  assert.equal(statsBefore.subjects.find(item => item.subject === 'MATH').ranked.wins, 1);
  assert.equal(statsBefore.subjects.find(item => item.subject === 'MATH').privateMatches.played, 1);
  assert.equal(statsBefore.subjects.find(item => item.subject === 'ENGLISH').rating, 1000);
  console.log('Private REST/STOMP: normal completion, surrender, incomplete-round review and unchanged Elo passed.');

  const lostEntry = await request('POST', '/api/v1/matchmaking/entries', third, {subject: 'ENGLISH'}, 201);
  const host = await register(); const lostRoom = await request('POST', '/api/v1/duels', host, {subject: 'MATH'}, 201);
  const pendingA = await register(), pendingB = await register();
  const pendingSocket = await new Stomp(pendingA).connect(); await new Stomp(pendingB).connect();
  await request('POST', '/api/v1/matchmaking/entries', pendingA, {subject: 'MATH'}, 201);
  const pendingId = (await request('POST', '/api/v1/matchmaking/entries', pendingB, {subject: 'MATH'}, 201)).battleId;
  await ready(pendingId, pendingA); await ready(pendingId, pendingB); await battleEvent(pendingSocket, pendingId, 'QUESTION', 1);
  const source = fixture.find(item => item.prompt === savedReviews.get(ranked).rounds[0].question.prompt);
  await writeFile(process.env.SKILLBATTLES_E2E_REVISION, JSON.stringify([{...source, contentVersion: 2, prompt: 'TEST ONLY revised prompt after completed battle', explanation: 'TEST ONLY revised explanation'}]));
  const restarted = new Promise(resolve => input.once('line', resolve));
  console.log('REVISE_AND_RESTART');
  assert.equal(await restarted, 'RESTARTED');
  assert.deepEqual(await history(a), savedHistory);
  assert.deepEqual(await get('/api/v1/users/me/statistics', a), statsBefore);
  for (const id of [ranked, privateId, surrenderId]) {
    assert.deepEqual(await review(id, a), savedReviews.get(id)); assert.deepEqual(await result(id, a), savedResults.get(id));
  }
  assert.equal((await activity(third)).type, 'NONE'); assert.equal((await activity(host)).type, 'NONE');
  await get('/api/v1/matchmaking/entries/' + lostEntry.id, third, 404); await get('/api/v1/duels/' + lostRoom.id, host, 404);
  const interrupted = await consistency(pendingId, pendingA);
  assert.equal(interrupted.reason, 'SERVER_INTERRUPTION'); assert.equal(interrupted.myOutcome, 'CANCELLED');
  assert(interrupted.players.every(player => player.ratingDelta === 0));
  const interruptedReview = await review(pendingId, pendingA);
  assert(interruptedReview.rounds.length >= 1 && interruptedReview.rounds.length <= 2);
  assert.equal((await activity(pendingA)).type, 'NONE');
  console.log('Restart: immutable history/result/review, changed source revision, statistics, lost waiting activities and interrupted-battle recovery passed.');

  const pair = await request('POST', '/api/v1/auth/refresh', third.refreshToken);
  assert(pair.accessToken !== third.accessToken);
  await request('POST', '/api/v1/auth/refresh', third.refreshToken, undefined, 401);
  await get('/api/v1/users/me/battles', pair.accessToken);
  await get('/api/v1/users/me/battles', pair.refreshToken, 401);
  await request('POST', '/api/v1/auth/logout', pair.refreshToken, undefined, 204);
  await request('POST', '/api/v1/auth/refresh', pair.refreshToken, undefined, 401);
  console.log('Authentication: access, refresh rotation/replay, logout and refresh-purpose isolation passed.');
} finally {
  for (const socket of sockets) { clearInterval(socket.heartbeat); if (socket.ws.readyState === WebSocket.OPEN) socket.ws.close(); }
  input.close();
}
