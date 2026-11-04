import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Sessions } from './sessions.mjs';
import { normalize, username, mapping } from './normalize.mjs';
import { createServer } from './server.mjs';
import { EventEmitter } from 'node:events';
import { adapter as makeAdapter } from './adapter.mjs';

const token = 'a'.repeat(32), other = 'b'.repeat(32);
const adapter = () => ({ connect: async () => {}, close() {} });
test('normalization, username validation and streak tiers', () => {
  assert.equal(username(' @Some.User '), 'some.user');
  for (const value of ['.name', 'https://tiktok.com/a', '', 'a'.repeat(25)]) assert.equal(username(value), null);
  assert.throws(() => mapping('{"1":"admin"}'));
  const data = { user: { uniqueId: 'viewer' }, common: { msgId: '9876543210987654321' }, giftId: 1, giftType: 1, repeatCount: 100 };
  assert.equal(normalize('gift', data, { 1: 'rose' }), null);
  assert.equal(normalize('gift', { ...data, repeatEnd: true }, { 1: 'rose' }).kind, 'rose');
  const e = normalize('comment', data, {}, { viewer: '123' });
  assert.equal(e.name, '@viewer'); assert.equal(e.avatarAssetId, '123');
  assert.equal(e.id, 'comment:9876543210987654321');
  assert.equal(normalize('gift', { ...data, repeatEnd: true }, {}), null);
  assert.equal(normalize('comment', { msgId: Number.MAX_SAFE_INTEGER + 1, uniqueId: 'a' }), null);
  assert.equal(normalize('comment', null), null);
  assert.ok(Buffer.byteLength(normalize('comment', {uniqueId:'ท'.repeat(100)}).uniqueId) <= 80);
});
test('provider adapter forwards actual event names, maps gifts and terminal states', async () => {
  let upstream;
  class FakeConnection extends EventEmitter {
    constructor(name, options) { super(); assert.equal(name, 'channel'); assert.equal(options.enableExtendedGiftInfo, false, 'optional gift catalog must not block LIVE'); upstream = this; }
    async connect() {}
    disconnect() {}
  }
  const events = [], states = [], metrics = {missingIds:0,unmappedGifts:0};
  const connection = makeAdapter({'7':'heart'}, {}, FakeConnection)('channel', e => events.push(e), s => states.push(s), metrics);
  await connection.connect();
  upstream.emit('chat', {user:{uniqueId:'viewer'},common:{msgId:'1'}});
  upstream.emit('follow', {user:{uniqueId:'viewer'},common:{msgId:'2'}});
  upstream.emit('gift', {user:{uniqueId:'viewer'},common:{msgId:'3'},giftId:7});
  assert.deepEqual(events.map(e => e.kind), ['comment','follow','heart']);
  upstream.emit('streamEnd'); upstream.emit('error', Error('secret must not escape'));
  assert.deepEqual(states, ['OFFLINE','ERROR']); connection.close();
});
test('connect failure and timeout end in ERROR and clean up', async () => {
  const fail = new Sessions(() => ({connect: async () => {throw Error('provider');},close(){}}));
  fail.connect(token, 'one'); await new Promise(r => setImmediate(r));
  assert.equal(fail.poll(token,0).status,'ERROR'); fail.close();
  let closed = false;
  const timeout = new Sessions(() => ({connect: () => new Promise(() => {}),close(){closed=true;}}),{timeout:5});
  timeout.connect(token,'one'); await new Promise(r => setTimeout(r,15));
  assert.equal(timeout.poll(token,0).status,'ERROR'); assert.equal(closed,true); timeout.close();
});
test('session isolation, replay, batching, overflow, TTL and cooldown', async () => {
  let time = 10000;
  const s = new Sessions(adapter, { now: () => time });
  s.connect(token, 'one'); s.connect(other, 'two');
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(s.poll(token, 0).status, 'LIVE');
  assert.throws(() => s.connect(token, 'one'), /RATE_LIMIT/);
  for (let i = 1; i <= 120; i++) s.push(s.items.get(token), { id: String(i), kind: 'comment' });
  s.push(s.items.get(token), { id: '1' });
  assert.equal(s.metrics.duplicates, 1);
  assert.deepEqual(s.poll(token, 0), s.poll(token, 0));
  assert.equal(s.poll(token, 0).cursor, 50);
  assert.equal(s.poll(token, 50).cursor, 100);
  assert.equal(s.poll(token, 100).events.length, 20);
  assert.equal(s.poll(other, 0).events.length, 0);
  for (let i = 121; i <= 620; i++) s.push(s.items.get(token), { id: String(i) });
  assert.equal(s.poll(token, 0).gap, true); assert.equal(s.metrics.dropped, 120);
  s.disconnect(other); assert.equal(s.poll(token, 620).status, 'LIVE');
  time += 90001; s.sweep(); assert.equal(s.items.size, 0); s.close();
});
test('disconnected session cannot receive late events or revive after connect', async () => {
  let resolve, emit, closed = 0;
  const s = new Sessions((_name, callback) => { emit = callback; return { connect: () => new Promise(r => resolve = r), close: () => closed++ }; });
  s.connect(token, 'one'); await new Promise(r => setImmediate(r));
  const old = s.items.get(token); s.disconnect(token); emit({ id: 'late' }); resolve();
  await new Promise(r => setImmediate(r));
  assert.equal(old.events.length, 0); assert.equal(s.items.size, 0); assert.ok(closed); s.close();
});
test('HTTP contract: auth, JSON errors, connect, poll and idempotent disconnect', async t => {
  const sessions = new Sessions(adapter);
  const server = createServer({ key: 'secret'.repeat(6), sessions });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => { sessions.close(); server.closeAllConnections(); server.close(); });
  const base = `http://127.0.0.1:${server.address().port}`;
  const headers = { 'X-Fame-Key': 'secret'.repeat(6), 'X-Fame-Session': token };
  assert.equal((await fetch(base + '/health')).status, 200);
  assert.equal((await fetch(base + '/connect', { method: 'POST' })).status, 401);
  assert.equal((await fetch(base + '/connect', { method: 'POST', headers, body: '{' })).status, 400);
  assert.equal((await fetch(base + '/connect', { method: 'POST', headers, body: JSON.stringify({username:'@one'}) })).status, 202);
  assert.equal((await fetch(base + '/session/events?after=-1', {headers})).status, 400);
  const poll = await (await fetch(base + '/session/events?after=0', {headers})).json();
  assert.deepEqual(poll.events, []); assert.equal(poll.cursor, 0);
  for (let i = 0; i < 2; i++) assert.deepEqual(await (await fetch(base + '/disconnect', { method: 'POST', headers, body: '{}' })).json(), {status:'DISCONNECTED'});
});
