import sharp from 'sharp';
import { normalize } from './normalize.mjs';

export function avatarURL(value) {
  const url = new URL(value);
  if (url.protocol !== 'https:' || url.username || url.password || (url.port && url.port !== '443') ||
      !/(^|\.)tiktokcdn(?:-us)?\.com$/.test(url.hostname)) throw Error('Untrusted avatar URL');
  return url;
}
export async function avatarPixels(user) {
  const raw = user.avatarThumb?.urlList?.[0] || user.profilePicture?.urls?.[0] || user.profilePictureUrl;
  const url = avatarURL(raw);
  const response = await fetch(url, { redirect: 'error', signal: AbortSignal.timeout(4000) });
  if (!response.ok || Number(response.headers.get('content-length')) > 2_000_000) throw Error('Avatar fetch failed');
  const chunks = []; let bytes = 0;
  for await (const chunk of response.body) {
    bytes += chunk.length;
    if (bytes > 2_000_000) { await response.body.cancel().catch(() => {}); throw Error('Avatar too large'); }
    chunks.push(chunk);
  }
  const data = await sharp(Buffer.concat(chunks), {limitInputPixels:16_000_000}).timeout({seconds:4})
    .resize(32,32,{fit:'cover'}).flatten({background:'#ffffff'}).toColourspace('srgb').removeAlpha().raw().toBuffer();
  const pixels = [];
  for (let i=0;i<data.length;i+=3) pixels.push(data[i]*65536+data[i+1]*256+data[i+2]);
  if (pixels.length !== 1024) throw Error('Invalid portrait size');
  return pixels;
}
export function likePhotos(emit, assets, metrics, load = avatarPixels) {
  const counts = new Map(), seen = new Set(), pending = new Set();
  let closed = false, active = 0;
  return {
    async accept(data) {
      if (closed || !data || !data.user) return;
      const handle = data.user.uniqueId || data.user.displayId;
      const count = Number(data.count ?? data.likeCount);
      if (typeof handle !== 'string' || !handle || !Number.isSafeInteger(count) || count < 1 || count > 10000) return;
      const id = data.common?.msgId ?? data.msgId;
      if (id && seen.has(String(id))) return;
      if (id) { seen.add(String(id)); if(seen.size>1000) seen.delete(seen.values().next().value); }
      const total = (counts.get(handle) || 0) + count;
      counts.set(handle, total);
      if (counts.size>500) counts.delete(counts.keys().next().value);
      if(total<15 || pending.has(handle) || active>=2) return;
      counts.set(handle,total%15);
      const event = normalize('necklace',data,{},assets);
      if(!event) return;
      event.id = 'like-photo:' + event.id.slice('necklace:'.length);
      pending.add(handle); active++;
      try {
        if(!event.avatarAssetId) event.pixels=await load(data.user);
        if(!closed) {emit(event);metrics.likePhotos=(metrics.likePhotos||0)+1;}
      } catch { metrics.avatarFailures=(metrics.avatarFailures||0)+1; }
      finally {pending.delete(handle);active--;}
    },
    close() {closed=true;counts.clear();seen.clear();},
  };
}
