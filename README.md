# AC Fame — TikTok LIVE bridge

สร้างจากแมพ AC Fame place `97287232901840` และ BACKEND_TIKTOK_GUIDE.md วันที่ 4 พฤศจิกายน 2026

## โครงสร้างแมพที่ตรวจพบ

- `Workspace.ACFame_Backup`: 3,507 descendants, Canvas, ChampionCanvas, ปีก ChampionWingLeft/Right, SakuraPlanters, CherryBlossomTrees, Spawn และงานสถาปัตยกรรม/ไฟนีออน
- `Lighting`: FameAtmosphere, FameBloom, FameColor, FameSun, Sky
- `ReplicatedStorage.ACFame`: Display, Demo และโมดูล BrushWriter, ArtistController, PhotoPainter; FameServer สร้าง Connection ตอนรัน
- `ServerScriptService`: FameConfig และ FameServer
- `StarterPlayer.StarterPlayerScripts.FameClient`: สร้าง HUD, Connect UI, demo, ภาพและคัตซีนตอนรัน จึงไม่มี GUI ตั้งต้นใน StarterGui
- `ServerStorage`: แบบร่างและสำรองงานเดิม เช่น PreviousSupporterWings, MuralArtist, PlazaArchitectureDraft, BeforeNeonReference และ NeonLightingDraft ไม่ใช่ฉากที่กำลังเล่น

`src/` เป็นสำเนา scripts ที่อ่านจาก Studio ไม่ใช่ระบบ sync อัตโนมัติ อย่าใส่ key จริงลง Git
ตอนตรวจพบ LiveEnabled=true แต่ BridgeUrl/BridgeKey ว่าง, AllowedUserIds ว่าง และ HTTP Requests ปิดอยู่

## Linux + PM2 + Cloudflare Tunnel

บน VPS ใช้ Node.js 22, โฟลเดอร์ `/var/www/acFame/bridge` และ `.env` สิทธิ์ 600

```sh
cd /var/www/acFame/bridge
npm ci
npm test
# ครั้งแรก: คัดลอก .env.example เป็น .env และตั้ง FAME_KEY แบบสุ่มก่อน
pm2 start npm --name ac-fame-bridge -- start
pm2 save
curl --fail http://127.0.0.1:3210/health
```

Cloudflare Tunnel ต้องชี้ hostname ที่อนุมัติไป `http://127.0.0.1:3210` ไม่ต้องเปิดพอร์ต 3210 ออกอินเทอร์เน็ต และไม่จำเป็นต้องมี Docker/Caddy
ถ้ารัน cloudflared ผ่าน PM2 ใช้ `--interpreter none` และตรวจว่า PM2 startup service เปิดแล้ว
อย่าใส่ Cloudflare Access login หรือ browser challenge บน API นี้ เพราะ Roblox Server ไม่มี browser สำหรับยืนยันตัวตน; endpoint private ตรวจ X-Fame-Key แทน

อัปเดตโค้ดภายหลัง: `git pull --ff-only`, `npm ci`, `npm test`, `pm2 restart ac-fame-bridge`
การ restart ทำ RAM sessions หาย ผู้ใช้ต้อง Connect ใหม่

## ทางเลือก: ติดตั้งบน VPS (Linux + Docker + โดเมน)

1. ชี้ DNS โดเมน เช่น `live.your-domain.com` ไป VPS และเปิดพอร์ต 80/443
2. อัปโหลดโฟลเดอร์โปรเจกต์ไป VPS แล้วเข้า `bridge/`
3. `cp .env.example .env` และ `chmod 600 .env`
4. สร้าง key ด้วย `openssl rand -hex 32` แล้วใส่ FAME_KEY ใน `.env` อย่าส่ง key ลงแชต
5. ตั้ง GIFT_IDS ด้วย ID ที่ตรวจจากช่องจริง เช่น JSON ที่จับคู่ ID กับ rose/necklace/donut/heart ไม่มี gift ID ที่เดาสุ่มมาให้
6. ตั้ง AVATAR_ASSETS เป็น JSON handle -> asset ID ที่ experience มีสิทธิ์โหลด ถ้าไม่มีรูปจะใช้ @ ตาม client เดิม
7. `npm ci` (ถ้ายังไม่มี package-lock.json ให้ใช้ `npm install` เพื่อสร้าง lockfile ก่อน) แล้ว `npm test`
8. `docker build -t ac-fame-bridge .`
9. `docker run -d --name ac-fame-bridge --restart unless-stopped --env-file .env -p 127.0.0.1:3210:3210 ac-fame-bridge`
10. ตั้ง reverse proxy HTTPS ด้วย Caddy ตามไฟล์ deploy/Caddyfile.example (ตัวอย่างนี้ Caddy รันบน host)

ใช้ Node 22 ถ้ารันโดยไม่ใช้ Docker: `npm ci` แล้ว `npm start` ซึ่งโหลด `.env` โดยตรง
Docker รับ env ผ่าน --env-file ไม่ต้อง COPY secret เข้า image

## ตั้ง Roblox หลัง deploy

ใน `ServerScriptService.FameConfig` ตั้ง BridgeUrl เป็น HTTPS URL ไม่มี / ท้าย และ BridgeKey ตรง FAME_KEY ตั้ง AllowedUserIds เป็น Roblox UserId ผู้ควบคุม ถ้า experience เป็นของ group ต้องใส่ allowlist
เปิด Game Settings / Security / Allow HTTP Requests แล้ว Save/Publish เมื่อพร้อม อย่าวาง key ใน ReplicatedStorage หรือ LocalScript
ตอนนี้ยังไม่ได้ตั้ง URL/key หรือ publish แมพให้

## API และการทดสอบ

API private ทุกตัวใช้ X-Fame-Key และ X-Fame-Session (token สุ่ม 32–100 ตัวอักษร a-z A-Z 0-9 -)

- POST /connect: {"username":"channel"} -> 202 CONNECTING เชื่อม provider เบื้องหลัง
- GET /session/events?after=0: status/events/cursor สูงสุด 50 รายการ อ่านซ้ำได้ แยกตาม token
- POST /disconnect: {} -> JSON DISCONNECTED เรียกซ้ำได้
- GET /health: public liveness เท่านั้น ไม่รับรองว่า TikTok เชื่อมได้
- GET /metrics: ต้องใช้ key แสดง activeSessions/dropped/duplicates/connectFailures/missingIds/unmappedGifts ไม่เผยชื่อช่องหรือ token

session TTL 90 วินาที, connect cooldown 3 วินาที, 100 sessions, history 500 และ dedup 4,000 ต่อ session
gap=true บอก cursor เก่ากว่า retention แต่ Roblox เดิมยังไม่ได้แสดงคำเตือนนี้
สถานะ terminal ไม่ reconnect อัตโนมัติ ผู้ใช้กด Connect ใหม่

ทดสอบอัตโนมัติด้วย `cd bridge && npm test`: username, gift tier/streak, mapping, ID ขนาดใหญ่, replay/dedup, cursor/backlog, isolation, overflow, TTL, late callbacks, HTTP auth และ lifecycle
ก่อนส่งขายต้องทดสอบช่อง LIVE จริงครบ 6 actions, 2 Roblox servers, ตัดเน็ต/ปิดไลฟ์/restart และภาพใน published experience

## ขอบเขตเวอร์ชันนี้

- ใช้ TikTok-Live-Connector 2.5.0 พร้อม lockfile แทน 2.0.0 ในคู่มือ เพราะ npm audit พบช่องโหว่ใน dependency รุ่นเก่า; หลังอัปเดต npm รายงาน 0 vulnerabilities แยก provider ไว้ adapter.mjs และตรวจ import/methods ได้แล้ว แต่ต้องทดสอบ payload LIVE จริง ตัว connector เป็น third party ไม่ใช่ TikTok API ที่รับประกันความเสถียร
- ยอมรับเฉพาะ GIFT_IDS ที่ตั้งชัดเจน ไม่เดาจากจำนวนเหรียญหรือชื่อของขวัญ เพราะราคา/ชื่อเปลี่ยนได้
- ไม่มี downloader ของ avatar URL หรือ Studio pixels จาก TikTok; ใช้ AVATAR_ASSETS ก่อน ไม่มี pipeline upload/moderation อัตโนมัติ ต้องมีข้อมูลบัญชีและสิทธิ์ Roblox ก่อนทำส่วนนี้
- ไม่มี endpoint legacy /event หรือ /events เพราะ client ปัจจุบันไม่อ่าน
- RAM เท่านั้น: restart ทำ session/คิวหาย ใช้ instance เดียว ยังไม่มี tenant/license/billing และห้ามแจก shared key นี้ให้ลูกค้าหลายราย
- upstream ไม่มี ID จะสร้าง UUID พร้อมนับ missingIds จึงกัน replay upstream กรณีนี้ไม่ได้
- รูปแปลงช้าไม่บล็อกคิวเพราะรุ่นนี้ไม่โหลดรูปภายนอก; อีเวนต์เกิน retention จะหายและนับ dropped
- ต้องวัดโหลดจริงและตรวจ provider credentials/signing requirement จาก VPS ก่อนอ้างว่าพร้อมขาย

ดูคู่มือ provider: https://github.com/zerodytrash/TikTok-Live-Connector

## ผลทดสอบ 4 พฤศจิกายน 2026

### UI แบบ atelier

- `src/FameUI.luau` -> ModuleScript `ReplicatedStorage.ACFame.FameUI`; ใช้ร่วมกับ FameClient รุ่นใหม่
- งานภาพหัวแผง `assets/ui/atelier-header.png` สร้างด้วย ImageGen และอัปโหลดเป็น Roblox image `123889866400587`; prompt และข้อมูล asset อยู่ใน `assets/ui/README.md`
- HUD ปกติเป็นแถบเล็ก แผงเชื่อมต่อ/Overlay รวมกัน และแผง Demo แสดงเฉพาะ Studio ใช้ native text/controls ทั้งหมด จอสั้นเลื่อน body ได้ จอสัมผัสย้ายปุ่มกล้องออกจากจอยเดิน
- `tests/FameUI.spec.luau` เป็น assert self-check สำหรับรันผ่าน Studio Client ตรวจสถานะ permission, loading/error/live, overlay, camera labels และการซ่อน/คืน chrome โดยไม่เรียกเครือข่าย
- ตรวจภาพจริงที่ desktop viewport 957×598, iPhone 17 Pro simulator แนวนอน 749×381 และแนวตั้ง 401×777; คืน simulator เป็น default หลังทดสอบ ไม่ใช่ผลทดสอบบนโทรศัพท์จริง
- ทดสอบ Connect LIVE จริง, empty-input recovery, เลือก URL ครบ, สลับกล้อง, เปิดแผง Demo และซ่อน/คืน HUD ระหว่างคัตซีนแล้ว

### Streaming Overlay

แมพใช้ 1 คนต่อเซิร์ฟเวอร์ เมื่อกด Connect เกมส่ง Roblox UserId ฝั่ง Server ไป backend แล้วส่งลิงก์ `/overlay?view=...` กลับให้ผู้เล่นคนนั้นเท่านั้น ในหน้า Connect มีช่องลิงก์กับปุ่มเลือกลิงก์ จากนั้นกด Ctrl+C / Cmd+C เพื่อนำไปวางใน OBS Browser Source หรือแหล่งเว็บใน TikTok LIVE Studio ขนาด 640 x 176
ลิงก์ผูกกับผู้เล่นด้วย HMAC ไม่ใส่ UserId, FAME_KEY หรือ session token ลงใน URL; คนเดิมเข้าใหม่/เปลี่ยนช่องได้ลิงก์เดิม และ backend ปิด session เก่าของเจ้าของเดียวกัน สองคนใช้ TikTok ช่องเดียวกันไม่ปะปนกัน
ตั้ง OVERLAY_SIGNING_KEY แบบสุ่มและเก็บเป็น secret ใน bridge/.env (ถ้าไม่ตั้งจะใช้ FAME_KEY เป็น signing key) เปลี่ยน signing key แล้วลิงก์เดิมจะเปลี่ยน OVERLAY_TOKEN แบบรวมและลิงก์ channel/token รุ่นเก่าเลิกใช้แล้ว
FameServer แจ้ง POST /overlay/current เมื่อเริ่ม display/champion จริง Overlay จึงแสดงคนที่กำลังวาด ไม่ใช่คนล่าสุดที่กดไลก์เข้า backend (มีระยะ polling ประมาณ 0.5 วินาที)
แสดง nickname, @handle, avatar, following/follower counts ที่ TikTok ส่งมา ถ้าไม่มีจำนวนแสดง — ไม่เดาค่า; ไม่มีงาน/ตัดการเชื่อมต่อจะซ่อน Overlay
ใช้ `?preview=1` แทน query อื่นเพื่อดูดีไซน์ตัวอย่าง ไม่มีข้อมูลผู้ชมจริง ผู้ถือ view link อ่านได้เฉพาะ Overlay ของเจ้าของนั้น ไม่สามารถสั่ง Connect หรืออ่านคิวคนอื่น การ restart backend จะล้าง session; Connect ใหม่แล้วลิงก์เดิมกลับมาใช้ได้
หลังเปลี่ยน FameServer ใน Studio ต้อง Save/Publish ให้เกมจริงใช้สคริปต์ใหม่; ห้ามนำ src/Config.luau key ว่างไปทับ config ที่ตั้งไว้

### โหมดทดสอบใจ 15 ครั้ง -> รูป

ตั้ง `TEST_LIKES_PHOTO=true` ใน bridge/.env แล้ว restart Backend และ Connect ใหม่
สะสม `count`/`likeCount` จาก TikTok แยกตามผู้ชม เมื่อครบ 15 ส่งอีเวนต์รูปแบบ necklace พร้อมชื่อและรูปโปรไฟล์ของคนกดใจ ภาพเป็น 32x32 pixels จาก HTTPS TikTok CDN, จำกัดขนาดไฟล์/เวลา/งานพร้อมกัน; ถ้าโหลดรูปไม่ได้จะนับ avatarFailures และไม่ปลอมรูปมาแทน
แต่ละอีเวนต์ที่ข้าม 15 สร้างได้หนึ่งรูป เก็บยอดที่เหลือ modulo 15 และนับใหม่เมื่อ reconnect
ใช้ทดสอบใน Studio ที่ AllowStudioPixels=true; published experience ยังไม่รับ pixels และต้องใช้ AVATAR_ASSETS ที่มี asset จริง โหมดนี้พักการส่ง comment เพื่อไม่ให้รูปติดคิวชื่อเก่า ต้อง Connect ใหม่หลังเปลี่ยนโหมด ปิดด้วย TEST_LIKES_PHOTO=false แล้ว restart/Connect ใหม่
ชื่อป้ายจอยังเป็น CREATOR PORTRAIT / 10 เพราะใช้การแสดงผล necklace เดิม ไม่ได้หมายถึงส่งของขวัญจริง

- Linux VPS Node 22: automated tests 8/8 ผ่าน หลัง deploy commit 53dd06c
- Studio กด Connect จริงไป @huntsos: CONNECTING -> LIVE และรับ comment ผ่าน VPS/HTTPS/poll/RemoteEvent ถึง client; จอ Canvas สร้างองค์ประกอบวาดชื่อได้
- Studio Demo ผ่าน client -> server -> client ครบ comment/follow/rose/necklace/donut/heart; จอปกติและ ChampionCanvas สร้างผลแสดงครบ พร้อมข้อความ TOP SUPPORTER การทดสอบนี้ใช้ Studio pixels ไม่ใช่รูป TikTok production
- ตรวจ auth จริง: health 200, session poll ที่มี key 200, metrics ไม่มี key 401
- แก้ enableExtendedGiftInfo=false เพราะการดึง catalog ก่อน connect ถูก provider ปฏิเสธ; ไม่จำเป็นต่อ mapping แบบ gift ID
- รองรับ user.displayId และ gift.type ตาม protobuf ที่พบจริง พร้อม regression tests
- ยืนยันจาก LIVE: gift 5655 / Rose / 1 diamond / type 1; ตั้ง GIFT_IDS บน VPS ให้ 5655 -> rose แล้ว รอบสุดท้าย client รับและแสดง comment 7, follow 1 และ rose 2 รวม 10 รายการ ขณะสถานะยังเป็น LIVE
- ยังไม่ยืนยัน LIVE จริงสำหรับ necklace/donut/heart, gift IDs อีก 3 แบบ, avatar assets ใน published experience, permission ของผู้เล่นจริง, สอง Roblox servers พร้อมกัน และการตัดเน็ตจริง
- ยังไม่ได้ Publish แมพ; ไม่มี secret ใน repository และ src/Config.luau ยังเป็น template key ว่าง อย่านำ template ไปทับ config ที่ตั้งใน Studio
