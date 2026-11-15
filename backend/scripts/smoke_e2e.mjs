// Internal runner for verify_e2e.py. Only public gameplay APIs and native STOMP are used.
import assert from 'node:assert/strict';
import {readFile, writeFile} from 'node:fs/promises';
import {createInterface} from 'node:readline';
import {randomUUID} from 'node:crypto';
import {verifyQuestionImages} from './question_images_smoke.mjs';

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
  return {status: response.status, data: text ? JSON.parse(text) : null, cacheControl: response.headers.get('cache-control')};
}
async function request(method, path, auth, body, expected = 200) {
  const response = await raw(method, path, auth, body);
  if (response.status !== expected) throw new Error(`${method} ${path}: ${response.status}, expected ${expected}; ${response.data?.code ?? ''}`);
  return response.data;
}
async function register() {
  const suffix = randomUUID().replaceAll('-', '').slice(0, 12);
  return request('POST', '/api/v1/auth/register', null, {birthYear: 2000, birthMonth: 1, email: suffix + '@example.com', nickname: 'Demo_' + suffix, password: 'IsolatedDemo123!'}, 201);
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
function questionImage(question) {
  const source = fixture.find(item => item.prompt === question.prompt);
  assert(source);
  assert.equal(question.imageUrl, source.imageKey ? '/media/questions/' + source.imageKey : null);
  assert(!('imageKey' in question));
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
  assert.equal(Object.entries(api.paths).filter(([url]) => url.startsWith('/api/v1/')).reduce((count, [, path]) => count + Object.keys(path).filter(method => ['get', 'post', 'patch', 'delete'].includes(method)).length, 0), 40);
  await verifyQuestionImages(base);
  assert(!JSON.stringify(api).includes('canPracticeSimilar'));
  assert(!Object.keys(api.paths).some(path => path.includes('/practice')));
  for (const path of ['/api/v1/users/me/battles', '/api/v1/battles/{id}/review']) {
    assert(api.paths[path].get.responses['200']); assert(api.paths[path].get.security.some(item => 'accessBearer' in item));
  }
  for (const [name, fields] of Object.entries({
    BattleReview: ['battleId', 'disciplineCode', 'mode', 'rulesVersion', 'rounds', 'answerAccess', 'mistakesOnly'],
    BattleHistoryItem: ['battleId', 'disciplineCode', 'format', 'mode', 'outcome', 'reason', 'opponent', 'myScore', 'opponentScore', 'ratingDelta', 'seasonId', 'overtimePlayed', 'createdAt', 'finishedAt'],
    BattleHistoryPage: ['data', 'pagination', 'historyLimit']
  })) {
    assert.deepEqual(Object.keys(api.components.schemas[name].properties).sort(), [...fields].sort());
    assert.deepEqual([...api.components.schemas[name].required].sort(), [...fields].sort());
  }
  await get('/api/v1/users/me/battles', null, 401);
  const a = await register(), b = await register(), third = await register();
  assert.equal((await get('/api/v1/users/me', a)).id, a.user.id);
  const catalogue = await get('/api/v1/battle-modes', a);
  const mainCount = catalogue.find(item => item.disciplineCode === 'SAT_MATH').questionCount;
  assert.equal(mainCount, 5); assert.equal((await get('/api/v1/ranks', a)).length, 27);
  assert.equal(api.info.version, '0.3.0');
  const plans = await get('/api/v1/subscriptions/plans', null);
  assert.deepEqual(plans.map(plan => plan.amountCents), [0, 799, 4799]); assert(plans.every(plan => plan.checkoutAvailable === false));
  assert.equal((await get('/api/v1/subscriptions/me', a)).entitlements.isPro, false);
  assert.equal((await get('/api/v1/users/me/limits', a)).freeRankedRemaining, 5);
  assert.equal((await request('POST', '/api/v1/subscriptions/checkout', a, {planCode:'PRO_MONTHLY', requestId:randomUUID()}, 503)).code, 'BILLING_UNAVAILABLE');
  const currentSeason = await get('/api/v1/seasons/current', a);
  assert.equal(currentSeason.timezone, 'America/New_York');
  assert.equal((await get('/api/v1/users/me/seasons', a)).data.length, 0);
  let sa = await new Stomp(a).connect(); const sb = await new Stomp(b).connect(); const sc = await new Stomp(third).connect();
  const entry = await request('POST', '/api/v1/matchmaking/entries', a, {disciplineCode: 'SAT_MATH', format: 'STANDARD'}, 201);
  const match = await request('POST', '/api/v1/matchmaking/entries', b, {disciplineCode: 'SAT_MATH', format: 'STANDARD'}, 201);
  const ranked = match.battleId;
  assert.equal(match.status, 'MATCHED');
  for (const auth of [a, b]) assert.deepEqual(await activity(auth), {type: 'BATTLE', resourceId: ranked, resourceKind: null, battleId: ranked});
  assert.equal((await get('/api/v1/matchmaking/entries/' + entry.id, a)).battleId, ranked);
  await ready(ranked, a); await ready(ranked, b);
  await battleEvent(sa, ranked, 'COUNTDOWN');
  for (let number = 1; number <= mainCount; number++) {
    const questionEvent = await battleEvent(sa, ranked, 'QUESTION', number);
    if (number === 1) {
      const account = await sa.event(event => event.type === 'ACCOUNT_CHANGED' && event.resourceId === a.user.id && event.data.limits.rankedStartedToday === 1);
      assert.equal(account.data.subscription.entitlements.isPro, false);
    }
    const state = await snapshot(ranked, a); const other = await snapshot(ranked, b);
    assert.deepEqual(state.round.question, other.round.question);
    assert.deepEqual(questionEvent.data.round.question, state.round.question);
    questionImage(state.round.question);
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
  assert.equal(rankedResult.myOutcome, 'WIN'); assert.equal(ownResult(rankedResult, a).ratingDelta, 32);
  assert.equal(ownResult(await consistency(ranked, b), b).ratingDelta, -32);
  assert.equal(rankedResult.seasonId, currentSeason.id); assert.equal(rankedResult.rulesVersion, '0.3');
  assert.equal(ownResult(rankedResult, a).kFactor, 64); assert.equal(ownResult(rankedResult, a).calibrationMatchesRemaining, 4);
  assert.equal((await history(a)).data.length, 1);
  for (const path of ['review', 'result']) await get('/api/v1/battles/' + ranked + '/' + path, third, 404);
  await get('/api/v1/battles/' + ranked, third, 404);
  assert.equal((await history(third)).data.length, 0); assert.equal(sc.events.length, 0);
  console.log('Ranked REST/STOMP: search, ready, questions, reveal, retry/conflict, reconnect, result/history/review and privacy passed.');

  const room = await request('POST', '/api/v1/duels', a, {disciplineCode: 'SAT_MATH', format: 'STANDARD'}, 201);
  const joined = await request('POST', '/api/v1/duels/join', b, {code: ' ' + room.code.toLowerCase() + ' '});
  const privateId = joined.battleId;
  await ready(privateId, a); await ready(privateId, b);
  for (let number = 1; number <= mainCount; number++) {
    await battleEvent(sa, privateId, 'QUESTION', number);
    const state = await snapshot(privateId, a);
    await submit(privateId, a, answerBody(state, false)); await submit(privateId, b, answerBody(state, false));
    await battleEvent(sb, privateId, 'REVEAL', number);
  }
  await battleEvent(sa, privateId, 'QUESTION', 6);
  const overtime = await snapshot(privateId, a);
  assert.equal(overtime.questionCount, 5); assert.equal(overtime.overtimePlayed, true); assert.equal(overtime.round.isOvertimeRound, true);
  questionImage(overtime.round.question);
  assert.equal(overtime.round.limitSeconds, catalogue.find(item => item.disciplineCode === 'SAT_MATH').overtimeSeconds);
  const overtimeAnswer = answerBody(overtime, true);
  const overtimeReceipt = await submit(privateId, a, overtimeAnswer);
  assert.deepEqual(await submit(privateId, a, overtimeAnswer), overtimeReceipt);
  const overtimeHidden = await snapshot(privateId, b);
  assert.equal(overtimeHidden.phase, 'QUESTION'); assert.equal(overtimeHidden.round.reveal, null);
  assert(overtimeHidden.players.every(player => player.score === 0));
  await submit(privateId, b, answerBody(overtime, false));
  const overtimeReveal = await battleEvent(sb, privateId, 'REVEAL', 6);
  assert(overtimeReveal.data.round.reveal.answers.every(answer => answer.basePoints + answer.speedBonus + answer.streakBonus === 0));
  await battleEvent(sb, privateId, 'FINISHED');
  const overtimeResult = await result(privateId, a);
  assert.equal(overtimeResult.reason, 'OVERTIME_WIN'); assert.equal(ownResult(overtimeResult, a).score, 1);
  assert.equal(overtimeResult.seasonId, null); assert.equal(ownResult(overtimeResult, a).kFactor, 0);
  for (const auth of [a, b]) assert((await consistency(privateId, auth)).players.every(player => player.ratingDelta === 0));
  const surrenderRoom = await request('POST', '/api/v1/duels', a, {disciplineCode: 'SAT_RW', format: 'STANDARD'}, 201);
  const surrenderId = (await request('POST', '/api/v1/duels/join', b, {code: surrenderRoom.code})).battleId;
  await ready(surrenderId, a); await ready(surrenderId, b); await battleEvent(sa, surrenderId, 'QUESTION', 1);
  const unfinished = await snapshot(surrenderId, a);
  await submit(surrenderId, a, answerBody(unfinished, true));
  await request('POST', '/api/v1/battles/' + surrenderId + '/surrender', b);
  const partial = await review(surrenderId, a);
  assert.equal(partial.rounds.length, 1); assert.equal(partial.rounds[0].completed, false); assert.equal(partial.rounds[0].answers.length, 1);
  assert(partial.rounds[0].answers[0].points >= 800);
  const surrendered = await consistency(surrenderId, a);
  assert.equal(surrendered.reason, 'SURRENDER'); assert(surrendered.players.every(player => player.score === 0 && player.ratingDelta === 0));
  let savedHistory = await history(a);
  assert.equal(savedHistory.historyLimit, 10);
  const freeReview = await review(ranked, a);
  assert(freeReview.rounds.every(round => round.question.correctOptionId === null && round.question.explanation === null));
  freeReview.rounds.forEach(round => questionImage(round.question));
  assert(freeReview.rounds.every(round => round.answers.filter(answer => answer.userId !== a.user.id).every(answer => answer.selectedOptionId === null)));
  assert.equal((await get('/api/v1/users/me/limits', a)).rankedStartedToday, 1);
  const savedReviews = new Map(); const savedResults = new Map();
  for (const id of [ranked, privateId, surrenderId]) { savedReviews.set(id, await review(id, a)); savedResults.set(id, await result(id, a)); }
  // Stage D/E: real HTTP/STOMP checks stay Free and never call a live mail/payment provider.
  const reviewRound = (await review(surrenderId, a)).rounds[0];
  const reportPath = `/api/v1/battles/${surrenderId}/rounds/${reviewRound.roundId}/report`;
  const reportPayload = {reason: 'TYPO', comment: 'TEST ONLY smoke report'};
  const report = await request('POST', reportPath, a, reportPayload, 201);
  assert.deepEqual(await request('POST', reportPath, a, reportPayload), report);
  assert.equal((await request('POST', reportPath, a, {reason: 'OTHER', comment: 'Different TEST ONLY report'}, 409)).code, 'REPORT_ALREADY_EXISTS');
  assert.equal((await get(`/api/v1/battles/${surrenderId}/review?mistakesOnly=true`, a, 403)).code, 'PRO_REQUIRED');
  const board = await get('/api/v1/leaderboards/SAT_MATH', a);
  assert.equal(board.me.player.id, a.user.id); assert.equal(board.me.rating, 1032); privateShape(board);
  const rematchPath = `/api/v1/battles/${privateId}/rematch`;
  const invitations = auth => get('/api/v1/users/me/rematch-invitations', auth);
  await get('/api/v1/users/me/rematch-invitations', null, 401);
  // A connected recipient can be elsewhere in the app; no result-screen subscription.
  await get('/api/v1/users/me', b);
  const consent = await request('POST', rematchPath, a);
  assert.deepEqual(await request('POST', rematchPath, a), consent);
  assert.equal((await activity(a)).resourceKind, 'REMATCH');
  const rematchEvent = await sa.event(event => event.type === 'REMATCH_CHANGED' && event.resourceId === privateId && event.data.status === 'WAITING');
  assert.equal(rematchEvent.version, consent.version);
  const recipientEvent = await sb.event(event => event.type === 'REMATCH_CHANGED' && event.resourceId === privateId && event.data.status === 'WAITING');
  assert.deepEqual(recipientEvent.data, consent);
  const incoming = await raw('GET', '/api/v1/users/me/rematch-invitations', b);
  assert.equal(incoming.status, 200); assert.equal(incoming.cacheControl, 'no-store');
  assert.deepEqual(Object.keys(incoming.data).sort(), ['data', 'serverTime']);
  assert.deepEqual(incoming.data.data, [{sourceBattleId: privateId, requester: {id: a.user.id, isPro: false, nickname: a.user.nickname}, disciplineCode: 'SAT_MATH', expiresAt: consent.expiresAt, version: consent.version}]);
  assert(new Date(incoming.data.serverTime) < new Date(consent.expiresAt));
  assert.deepEqual((await invitations(a)).data, []); assert.deepEqual((await invitations(third)).data, []);
  assert(!sc.events.some(event => event.type === 'REMATCH_CHANGED'));
  await sb.close();
  const recoveredRecipient = await new Stomp(b).connect();
  assert.deepEqual((await invitations(b)).data, incoming.data.data);
  const rematch = await request('POST', rematchPath, b);
  assert.equal(rematch.status, 'MATCHED');
  assert.equal((await request('POST', rematchPath, b)).battleId, rematch.battleId);
  assert.deepEqual((await invitations(b)).data, []);
  assert.equal((await activity(b)).battleId, rematch.battleId);
  await recoveredRecipient.event(event => event.type === 'REMATCH_CHANGED' && event.resourceId === privateId && event.data.status === 'MATCHED');
  assert.equal((await request('DELETE', rematchPath, b, undefined, 409)).code, 'MATCH_ALREADY_FOUND');
  assert.equal((await snapshot(rematch.battleId, a)).phase, 'WAITING_READY');
  await request('POST', '/api/v1/battles/' + rematch.battleId + '/surrender', a);
  const cancelPath = `/api/v1/battles/${surrenderId}/rematch`;
  await request('POST', cancelPath, a); await request('DELETE', cancelPath, b, undefined, 204);
  assert.equal((await get(cancelPath, a)).status, 'CANCELLED'); assert.equal((await activity(a)).type, 'NONE');
  assert.deepEqual((await invitations(b)).data, []);
  const profile = await register();
  const changed = await request('PATCH', '/api/v1/users/me', profile, {nickname: 'Updated_' + randomUUID().replaceAll('-', '').slice(0, 10), currentPassword: 'IsolatedDemo123!', newPassword: 'UpdatedDemo123!'});
  assert.equal(changed.passwordChanged, true); assert.equal(changed.reauthenticationRequired, true);
  await request('POST', '/api/v1/auth/refresh', profile.refreshToken, undefined, 401);
  await get('/api/v1/users/me', profile);
  const reset = await request('POST', '/api/v1/auth/password-reset/request', null, {email: profile.user.email}, 503);
  assert.equal(reset.code, 'EMAIL_SERVICE_UNAVAILABLE');
  console.log('D/E REST/STOMP: profile/password refresh revocation, leaderboard, reports, Pro gates, rematch consent/activity/events/cancel passed.');

  savedHistory = await history(a);
  const statsBefore = await get('/api/v1/users/me/statistics', a);
  assert.equal(statsBefore.disciplines.find(item => item.disciplineCode === 'SAT_MATH').rating, 1032);
  assert.equal(statsBefore.disciplines.find(item => item.disciplineCode === 'SAT_MATH').ranked.wins, 1);
  assert.equal(statsBefore.disciplines.find(item => item.disciplineCode === 'SAT_MATH').privateMatches.played, 1);
  assert.equal(statsBefore.disciplines.find(item => item.disciplineCode === 'SAT_RW').rating, 1000);
  assert.equal(statsBefore.streaks.dailyCurrent, 1); assert.equal(statsBefore.entitlements.isPro, false);
  console.log('Private REST/STOMP: overtime, one tieBreakPoint, surrender, incomplete-round review and unchanged Elo passed.');

  const lostEntry = await request('POST', '/api/v1/matchmaking/entries', third, {disciplineCode: 'SAT_RW', format: 'STANDARD'}, 201);
  const host = await register(); const lostRoom = await request('POST', '/api/v1/duels', host, {disciplineCode: 'SAT_MATH', format: 'STANDARD'}, 201);
  const pendingA = await register(), pendingB = await register();
  const pendingSocket = await new Stomp(pendingA).connect(); await new Stomp(pendingB).connect();
  await request('POST', '/api/v1/matchmaking/entries', pendingA, {disciplineCode: 'SAT_MATH', format: 'STANDARD'}, 201);
  const pendingId = (await request('POST', '/api/v1/matchmaking/entries', pendingB, {disciplineCode: 'SAT_MATH', format: 'STANDARD'}, 201)).battleId;
  await ready(pendingId, pendingA); await ready(pendingId, pendingB); await battleEvent(pendingSocket, pendingId, 'QUESTION', 1);
  assert.equal((await get('/api/v1/users/me/limits', pendingA)).rankedStartedToday, 1);
  const forgottenPath = `/api/v1/battles/${rematch.battleId}/rematch`;
  await request('POST', forgottenPath, a);
  assert.equal((await invitations(b)).data[0].sourceBattleId, rematch.battleId);
  // Separate accounts keep immutable-history assertions above independent of recovery.
  const recoveryA = await register(), recoveryB = await register();
  const recoveryRoom = await request('POST', '/api/v1/duels', recoveryA, {disciplineCode:'SAT_MATH',format:'STANDARD'}, 201);
  const recoverySource = (await request('POST', '/api/v1/duels/join', recoveryB, {code:recoveryRoom.code})).battleId;
  await request('POST', `/api/v1/battles/${recoverySource}/surrender`, recoveryA);
  await request('POST', `/api/v1/battles/${recoverySource}/rematch`, recoveryA);
  const acceptedRecovery = await request('POST', `/api/v1/battles/${recoverySource}/rematch`, recoveryB);
  assert.equal((await activity(recoveryB)).battleId, acceptedRecovery.battleId);
  const source = fixture.find(item => item.prompt === savedReviews.get(ranked).rounds[0].question.prompt);
  await writeFile(process.env.SKILLBATTLES_E2E_REVISION, JSON.stringify([{...source, contentVersion: source.contentVersion + 1, imageKey: null, prompt: 'TEST ONLY revised prompt after completed battle', explanation: 'TEST ONLY revised explanation'}]));
  const restarted = new Promise(resolve => input.once('line', resolve));
  console.log('REVISE_AND_RESTART');
  assert.equal(await restarted, 'RESTARTED');
  await verifyQuestionImages(base);
  assert.deepEqual((await invitations(b)).data, []);
  assert.equal((await get(forgottenPath, a, 404)).code, 'REMATCH_NOT_FOUND');
  const recoveredBattle = await snapshot(acceptedRecovery.battleId, recoveryB);
  assert.equal(recoveredBattle.phase, 'CANCELLED');
  assert.equal(recoveredBattle.result.reason, 'SERVER_INTERRUPTION');
  assert.equal((await activity(recoveryB)).type, 'NONE');
  console.log('Rematch invitations: personal no-store snapshot, WAITING to both sessions, reconnect, accept/decline, pending loss and accepted-battle recovery after restart passed.');
  assert.deepEqual(await history(a), savedHistory);
  assert.deepEqual(await get('/api/v1/users/me/statistics', a), statsBefore);
  assert.deepEqual(await get('/api/v1/seasons/current', a), currentSeason);
  assert.equal((await get('/api/v1/users/me/seasons', a)).data.length, 0);
  for (const id of [ranked, privateId, surrenderId]) {
    assert.deepEqual(await review(id, a), savedReviews.get(id)); assert.deepEqual(await result(id, a), savedResults.get(id));
  }
  assert.equal((await activity(third)).type, 'NONE'); assert.equal((await activity(host)).type, 'NONE');
  await get('/api/v1/matchmaking/entries/' + lostEntry.id, third, 404); await get('/api/v1/duels/' + lostRoom.id, host, 404);
  const interrupted = await consistency(pendingId, pendingA);
  assert.equal(interrupted.reason, 'SERVER_INTERRUPTION'); assert.equal(interrupted.myOutcome, 'CANCELLED');
  assert(interrupted.players.every(player => player.ratingDelta === 0));
  assert.equal((await get('/api/v1/users/me/limits', pendingA)).rankedStartedToday, 0);
  assert.equal((await get('/api/v1/users/me/limits', pendingB)).rankedStartedToday, 0);
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
