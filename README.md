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

## ติดตั้งบน VPS (Linux + Docker + โดเมน)

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
