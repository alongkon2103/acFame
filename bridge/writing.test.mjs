import {test} from 'node:test';
import assert from 'node:assert/strict';
import {cleanWritingName,writingPaths} from './writing.mjs';
test('emoji clusters are excluded without removing Thai marks, accents or numbers',()=>{
 assert.equal(cleanWritingName('น้ำฝน👩🏽‍🎨 ❤️ Á 123 🇹🇭'),'น้ำฝน  Á 123');
 assert.equal(cleanWritingName('1️⃣🌟'),'');
});
test('multilingual names produce bounded connected pen strokes instead of a text reveal',async()=>{
 for(const name of ['Alice','น้ำฝน','中文','日本語','한국어','العربية','हिन्दी','Émilie_123']){
  const p=await writingPaths(name);assert.ok(p.strokes.length>0,name);
  assert.ok(p.width<=1028&&p.height<=132);
  let count=0;for(const stroke of p.strokes){assert.ok(stroke.length>=2);for(const [x,y]of stroke){assert.ok(x>=0&&x<p.width&&y>=0&&y<p.height);count++;}}
  assert.ok(count<=16000);
 }
});
