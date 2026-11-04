import http from 'node:http';
import { timingSafeEqual } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { Sessions } from './sessions.mjs';
import { username, mapping } from './normalize.mjs';

export function createServer({ key, sessions }) {
  if (typeof key !== 'string' || key.length < 20) throw Error('FAME_KEY must contain at least 20 characters');
  const secret = Buffer.from(key);
  const server = http.createServer(async (req, res) => {
    const send = (status, value) => { res.writeHead(status, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(value)); };
    try {
      const url = new URL(req.url, 'http://localhost');
      if (url.pathname === '/health' && req.method === 'GET') return send(200, { status: 'ok' });
      const supplied = Buffer.from(req.headers['x-fame-key'] || '');
      if (supplied.length !== secret.length || !timingSafeEqual(secret, supplied)) return send(401, { error: 'Unauthorized' });
      if (url.pathname === '/metrics' && req.method === 'GET') return send(200, { activeSessions: sessions.items.size, ...sessions.metrics });
      const token = req.headers['x-fame-session'];
      if (typeof token !== 'string' || !/^[a-zA-Z0-9-]{32,100}$/.test(token)) return send(400, { error: 'INVALID_SESSION' });
      if (!['/connect','/disconnect','/session/events'].includes(url.pathname)) return send(404, { error: 'Not found' });
      if (req.method !== (url.pathname === '/session/events' ? 'GET' : 'POST')) return send(405, { error: 'METHOD_NOT_ALLOWED' });
      if (req.method === 'POST') {
        let size = 0; const chunks = [];
        for await (const chunk of req) { size += chunk.length; if (size > 8192) return send(413, { error: 'BODY_TOO_LARGE' }); chunks.push(chunk); }
        let body;
        try { body = JSON.parse(Buffer.concat(chunks).toString()); } catch { return send(400, { error: 'INVALID_JSON' }); }
        if (url.pathname === '/disconnect') { sessions.disconnect(token); return send(200, { status: 'DISCONNECTED' }); }
        const name = username(body?.username);
        if (!name) return send(400, { error: 'INVALID_USERNAME' });
        return send(202, sessions.connect(token, name));
      }
      const raw = url.searchParams.get('after');
      if (raw === null || !/^\d+$/.test(raw) || !Number.isSafeInteger(Number(raw))) return send(400, { error: 'INVALID_CURSOR' });
      return send(200, sessions.poll(token, Number(raw)));
    } catch (error) { if (!res.headersSent) send(error.status || 500, { error: error.status ? error.message : 'INTERNAL_ERROR' }); }
  });
  server.requestTimeout = 10000; server.headersTimeout = 10000;
  return server;
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const { adapter } = await import('./adapter.mjs');
  const sessions = new Sessions(adapter(mapping(process.env.GIFT_IDS), mapping(process.env.AVATAR_ASSETS, true)));
  const server = createServer({ key: process.env.FAME_KEY, sessions });
  const sweep = setInterval(() => sessions.sweep(), 30000); sweep.unref();
  server.listen(Number(process.env.PORT || 3210), process.env.HOST || '127.0.0.1', () => console.log('AC Fame bridge listening'));
  for (const signal of ['SIGINT','SIGTERM']) process.once(signal, () => {
    clearInterval(sweep); sessions.close(); server.close();
    setTimeout(() => process.exit(0), 5000).unref();
  });
}
