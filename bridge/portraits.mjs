import sharp from 'sharp';

export function avatarURL(value) {
  const url = new URL(value);
  if (url.protocol !== 'https:' || url.username || url.password || (url.port && url.port !== '443') ||
      !/(^|\.)tiktokcdn(?:-us)?\.com$/.test(url.hostname)) throw Error('Untrusted avatar URL');
  return url;
}
export async function avatarPixels(raw) {
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
export function portraits(emit,metrics,load=avatarPixels) {
  const queue=[],seen=new Set();let closed=false,active=0;
  function pump(){
    while(!closed&&active<2&&queue.length){
      const event=queue.shift();active++;
      Promise.resolve().then(()=>load(event.profile.avatarUrl)).then(pixels=>{
        if(!Array.isArray(pixels)||pixels.length!==1024||!pixels.every(v=>Number.isInteger(v)&&v>=0&&v<=16777215))throw Error('Invalid portrait pixels');
        event.pixels=pixels;
      }).catch(()=>{metrics.avatarFailures=(metrics.avatarFailures||0)+1;}).finally(()=>{
        active--;if(!closed)emit(event);pump();
      });
    }
  }
  return {
    accept(event){
      if(closed||seen.has(event.id))return;
      seen.add(event.id);if(seen.size>4000)seen.delete(seen.values().next().value);
      if(!['necklace','donut','heart'].includes(event.kind)||event.avatarAssetId){emit(event);return;}
      if(!event.profile?.avatarUrl||queue.length>=64){metrics.avatarFailures=(metrics.avatarFailures||0)+1;emit(event);return;}
      queue.push(event);pump();
    },
    close(){closed=true;queue.length=0;seen.clear();},
  };
}
