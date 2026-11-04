import {test} from 'node:test';
import assert from 'node:assert/strict';
import {avatarURL,avatarPixels,likePhotos} from './like-photo.mjs';
import sharp from 'sharp';

test('15 likes per viewer triggers their portrait; batches, remainder and replay stay isolated',async()=>{
  const events=[],metrics={};let loads=0;
  const qa=likePhotos(e=>events.push(e),{},metrics,async()=>{loads++;return Array(1024).fill(0x123456);});
  const like=(handle,count,id)=>({user:{displayId:handle},count,common:{msgId:id}});
  await qa.accept(like('a',8,'1'));await qa.accept(like('b',14,'2'));
  await qa.accept(like('a',8,'1'));assert.equal(events.length,0);
  await qa.accept(like('a',7,'3'));assert.equal(events.length,1);
  assert.equal(events[0].name,'@a');assert.equal(events[0].pixels.length,1024);
  await qa.accept(like('b',1,'4'));assert.equal(events[1].name,'@b');
  await qa.accept(like('a',18,'5'));await qa.accept(like('a',12,'6'));assert.equal(events.length,4);
  await qa.accept(like('a',-1,'7'));assert.equal(loads,4);
  qa.close();await qa.accept(like('a',15,'8'));assert.equal(events.length,4);
});
test('avatar failures do not emit fake pictures; pending work cannot cross disconnect',async()=>{
  const events=[],metrics={};const qa=likePhotos(e=>events.push(e),{},metrics,async()=>{throw Error('network');});
  await qa.accept({user:{displayId:'a'},count:15});assert.equal(events.length,0);assert.equal(metrics.avatarFailures,1);
  let done;const late=likePhotos(e=>events.push(e),{},metrics,()=>new Promise(r=>done=r));
  const p=late.accept({user:{displayId:'a'},count:15});late.close();done(Array(1024).fill(0));await p;assert.equal(events.length,0);
});
test('avatar downloader accepts only HTTPS TikTok CDN URLs',()=>{
  assert.equal(avatarURL('https://p16-common-sign.tiktokcdn.com/a').hostname,'p16-common-sign.tiktokcdn.com');
  for(const url of ['http://p16.tiktokcdn.com/a','https://127.0.0.1/a','https://tiktokcdn.com.evil.com/a','https://user:pass@p16.tiktokcdn.com/a','https://p16.tiktokcdn.com:123/a']) assert.throws(()=>avatarURL(url));
});
test('downloaded image becomes exactly 1024 packed RGB pixels',async t=>{
  const image=await sharp({create:{width:2,height:2,channels:3,background:'#123456'}}).png().toBuffer();
  const original=globalThis.fetch;t.after(()=>globalThis.fetch=original);
  globalThis.fetch=async(_url,options)=>{assert.equal(options.redirect,'error');return new Response(image);};
  const pixels=await avatarPixels({avatarThumb:{urlList:['https://p16-common-sign.tiktokcdn.com/avatar']}});
  assert.equal(pixels.length,1024);assert.ok(pixels.every(p=>p===0x123456));
});
