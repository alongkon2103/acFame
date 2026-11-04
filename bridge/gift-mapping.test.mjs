import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {EventEmitter} from 'node:events';
import {mapping} from './normalize.mjs';
import {adapter} from './adapter.mjs';
import {Sessions} from './sessions.mjs';

test('verified gift IDs map to the correct effect once per finished streak',async()=>{
  const config=readFileSync(new URL('./.env.example',import.meta.url),'utf8');
  const gifts=mapping(config.match(/^GIFT_IDS=(.*)$/m)[1]);
  assert.deepEqual(gifts,{'5655':'rose','9947':'necklace','5879':'donut','5660':'heart'});
  let upstream;
  class Provider extends EventEmitter {
    constructor(){super();upstream=this;}
    async connect(){}
    disconnect(){}
  }
  const sessions=new Sessions(adapter(gifts,{viewer:'123'},Provider));
  try {
    const token='gift-test-'.padEnd(32,'a'),view='1'.repeat(64);
    sessions.connect(token,'channel',view);await new Promise(r=>setImmediate(r));
    for(const [id,kind] of Object.entries(gifts)){
      const data={giftId:Number(id),gift:{type:1},repeatEnd:0,repeatCount:3,user:{displayId:'viewer'},common:{msgId:'gift-'+id}};
      upstream.emit('gift',data);
      assert.equal(sessions.overlayState(view).counts[kind],0,'Unfinished streak must not trigger');
      upstream.emit('gift',{...data,repeatEnd:1});upstream.emit('gift',{...data,repeatEnd:1});
      assert.equal(sessions.overlayState(view).counts[kind],1,'Repeated delivery must not trigger twice');
    }
    const events=sessions.poll(token,0).events;
    assert.deepEqual(events.map(e=>e.kind),Object.values(gifts));
    assert.ok(events.every(e=>e.avatarAssetId==='123'));
    assert.equal(sessions.setOverlay(token,'heart:gift-5660',1),true);
    assert.equal(sessions.overlay(view).kind,'heart');
    upstream.emit('gift',{giftId:5586,gift:{type:1},repeatEnd:1,user:{displayId:'viewer'},common:{msgId:'old-hearts'}});
    assert.equal(sessions.poll(token,0).events.length,4,'Unconfigured Hearts must not trigger Hand Hearts');
  } finally {sessions.close();}
});
