import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {EventEmitter} from 'node:events';
import {mapping} from './normalize.mjs';
import {adapter} from './adapter.mjs';
import {Sessions} from './sessions.mjs';

test('Euler TH gift IDs and actual gift types trigger each effect without duplicates',async()=>{
  const config=readFileSync(new URL('./.env.example',import.meta.url),'utf8');
  const gifts=mapping(config.match(/^GIFT_IDS=(.*)$/m)[1]);
  assert.deepEqual(gifts,{'5655':'rose','9947':'necklace','5879':'donut','5660':'heart'});
  const catalog=JSON.parse(readFileSync(new URL('./fixtures/euler-th-gifts.json',import.meta.url),'utf8'));
  assert.deepEqual(catalog.gifts.map(g=>[g.id,g.name,g.diamond_count,g.type]),[
    [5655,'Rose',1,1],[5660,'Hand Heart',100,2],[5879,'Doughnut',30,1],[9947,'Friendship Necklace',10,1],
  ]);
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
    for(const gift of catalog.gifts){
      const id=gift.id,kind=gifts[id];
      const data={giftId:String(id),gift:{type:gift.type,name:gift.name,diamondCount:gift.diamond_count},repeatEnd:0,repeatCount:3,user:{displayId:'viewer'},common:{msgId:'gift-'+id}};
      upstream.emit('gift',data);
      assert.equal(sessions.overlayState(view).counts[kind],gift.type===1?0:1,'Only type 1 waits for streak completion');
      upstream.emit('gift',{...data,repeatEnd:1});upstream.emit('gift',{...data,repeatEnd:1});
      assert.equal(sessions.overlayState(view).counts[kind],1,'Repeated delivery must not trigger twice');
    }
    const events=sessions.poll(token,0).events;
    assert.deepEqual(events.map(e=>e.kind),catalog.gifts.map(g=>gifts[g.id]));
    assert.ok(events.every(e=>e.avatarAssetId==='123'));
    assert.equal(sessions.setOverlay(token,'heart:gift-5660',1),true);
    assert.equal(sessions.overlay(view).kind,'heart');
    upstream.emit('gift',{giftId:5586,gift:{type:1},repeatEnd:1,user:{displayId:'viewer'},common:{msgId:'old-hearts'}});
    assert.equal(sessions.poll(token,0).events.length,4,'Unconfigured Hearts must not trigger Hand Hearts');
  } finally {sessions.close();}
});
