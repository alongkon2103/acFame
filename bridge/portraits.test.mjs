import {test} from 'node:test';
import assert from 'node:assert/strict';
import {portraits,avatarURL,avatarPixels} from './portraits.mjs';
import sharp from 'sharp';
test('avatar decoder restricts network hosts and returns 1024 RGB pixels',async t=>{
  for(const url of ['http://p16.tiktokcdn.com/a','https://127.0.0.1/a','https://tiktokcdn.com.evil.com/a','https://u:p@p16.tiktokcdn.com/a'])assert.throws(()=>avatarURL(url));
  const image=await sharp({create:{width:2,height:2,channels:3,background:'#123456'}}).png().toBuffer();
  const original=globalThis.fetch;t.after(()=>globalThis.fetch=original);
  globalThis.fetch=async(_url,options)=>{assert.equal(options.redirect,'error');return new Response(image);};
  const pixels=await avatarPixels('https://p16.tiktokcdn.com/a');
  assert.equal(pixels.length,1024);assert.ok(pixels.every(p=>p===0x123456));
});
test('gift portraits carry pixels once; comments do not wait and disconnect cancels pending output',async()=>{
  let finish;const events=[],metrics={};
  const painter=portraits(e=>events.push(e),metrics,()=>new Promise(r=>finish=r));
  const gift={id:'gift:1',kind:'heart',profile:{avatarUrl:'https://p16.tiktokcdn.com/a'}};
  painter.accept(gift);painter.accept(gift);await new Promise(r=>setImmediate(r));
  painter.accept({id:'comment:1',kind:'comment'});
  assert.equal(events[0].kind,'comment');
  finish(Array(1024).fill(0x123456));await new Promise(r=>setImmediate(r));
  assert.equal(events.length,2);assert.equal(events[1].pixels.length,1024);
  painter.accept({...gift,id:'gift:2',pixels:undefined});await new Promise(r=>setImmediate(r));painter.close();finish(Array(1024).fill(0));
  await new Promise(r=>setImmediate(r));assert.equal(events.length,2);
});
test('failed portrait downloads retain name events and count failure',async()=>{
  const events=[],metrics={};const painter=portraits(e=>events.push(e),metrics,async()=>{throw Error('unavailable');});
  painter.accept({id:'gift:1',kind:'necklace',name:'Alice',profile:{avatarUrl:'https://p16.tiktokcdn.com/a'}});
  await new Promise(r=>setImmediate(r));assert.equal(events[0].name,'Alice');assert.equal(metrics.avatarFailures,1);painter.close();
});
