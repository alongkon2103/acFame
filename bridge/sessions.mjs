const activityKinds=['comment','follow','rose','necklace','donut','heart','like'];
const emptyCounts=()=>Object.fromEntries(activityKinds.map(kind=>[kind,0]));
export class Sessions {
  constructor(adapter, { now = Date.now, ttl = 90000, timeout = 20000, capacity = 100 } = {}) {
    this.adapter = adapter; this.now = now; this.ttl = ttl; this.timeout = timeout; this.capacity = capacity;
    // shortcut: state lives in one process; use shared ownership/state before adding replicas.
    this.items = new Map(); this.recent = new Map();
    this.metrics = { dropped: 0, duplicates: 0, connectFailures: 0, missingIds: 0, unmappedGifts: 0 };
  }
  connect(token, name, overlayId = null) {
    this.sweep();
    if (this.recent.has(token) && this.now() - this.recent.get(token) < 3000) throw Object.assign(Error('RATE_LIMIT'), { status: 429 });
    const previous = overlayId && [...this.items].find(([,s])=>s.overlayId===overlayId);
    if (!this.items.has(token) && !previous && this.items.size >= this.capacity) throw Object.assign(Error('CAPACITY'), { status: 429 });
    if(previous) this.disconnect(previous[0]);
    this.disconnect(token);
    this.recent.set(token, this.now());
    const s = { username: name, overlayId, status: 'CONNECTING', touched: this.now(), cursor: 0, events: [], seen: new Set(), activitySeen:new Set(), counts:emptyCounts(), closed: false };
    this.items.set(token, s);
    const terminal = status => {
      if (s.closed) return;
      s.status = status;
      if (status === 'ERROR') this.metrics.connectFailures++;
      clearTimeout(s.timer);
      s.closed = true;
      try { s.connection?.close(); } catch { /* Socket cleanup must not crash HTTP. */ }
    };
    s.timer = setTimeout(() => terminal('ERROR'), this.timeout); s.timer.unref?.();
    Promise.resolve().then(async () => {
      if (s.closed) return;
      const connection = this.adapter(name, event => this.push(s, event), terminal, this.metrics, event=>this.recordActivity(s,event));
      s.connection = connection;
      await connection.connect();
      if (s.closed) { connection.close(); return; }
      clearTimeout(s.timer); s.status = 'LIVE';
    }).catch(() => terminal('ERROR'));
    return { status: s.status, username: name };
  }
  push(s, event) {
    if (s.closed || !event) return;
    if (s.seen.has(event.id)) { this.metrics.duplicates++; return; }
    s.seen.add(event.id);
    this.recordActivity(s,event);
    if (s.seen.size > 4000) s.seen.delete(s.seen.values().next().value);
    s.events.push({ ...event, seq: ++s.cursor });
    if (s.events.length > 500) { s.events.shift(); this.metrics.dropped++; }
  }
  poll(token, after) {
    this.sweep();
    const s = this.items.get(token);
    if (!s) return { status: 'DISCONNECTED', events: [], cursor: 0 };
    s.touched = this.now();
    if (after > s.cursor) after = 0;
    const events = s.events.filter(e => e.seq > after).slice(0, 50);
    return { status: s.status, username: s.username, events, cursor: events.at(-1)?.seq ?? s.cursor,
      gap: !!s.events.length && after < s.events[0].seq - 1 };
  }
  disconnect(token) {
    const s = this.items.get(token);
    if (s) { s.closed = true; clearTimeout(s.timer); try { s.connection?.close(); } catch {} this.items.delete(token); }
  }
  setOverlay(token,id,revision) {
    const s=this.items.get(token);
    if(!s || s.closed || !Number.isSafeInteger(revision) || revision<1 || revision<=(s.overlayRevision||0)) return false;
    const event=s.events.find(e=>e.id===id);
    if(!event?.profile) return false;
    s.overlayRevision=revision;
    s.currentOverlay={id:event.id,kind:event.kind,profile:event.profile,pixels:event.pixels,updatedAt:this.now()};
    return true;
  }
  overlay(view) {
    return this.overlayState(view).current;
  }
  recordActivity(s,event) {
    if(s.closed || !event || typeof event.id!=='string' || event.id.startsWith('like-photo:') || !activityKinds.includes(event.kind) || s.activitySeen.has(event.id)) return;
    const amount=event.kind==='like' ? Number(event.count) : 1;
    if(!Number.isSafeInteger(amount) || amount<1 || amount>10000) return;
    s.activitySeen.add(event.id);
    if(s.activitySeen.size>4000) s.activitySeen.delete(s.activitySeen.values().next().value);
    s.counts[event.kind]+=amount;
  }
  overlayState(view) {
    this.sweep();
    if(view) for(const s of this.items.values()) if(!s.closed && s.overlayId===view) return {current:s.currentOverlay||null,status:s.status,counts:s.counts};
    return {current:null,status:'DISCONNECTED',counts:emptyCounts()};
  }
  sweep() {
    for (const [token, s] of this.items) if (this.now() - s.touched >= this.ttl) this.disconnect(token);
    for (const [token, time] of this.recent) if (this.now() - time >= 3000) this.recent.delete(token);
  }
  close() { for (const token of this.items.keys()) this.disconnect(token); }
}
