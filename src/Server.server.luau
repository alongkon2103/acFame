local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Players = game:GetService("Players")
local Text = game:GetService("TextService")
local Config = require(script.Parent.FameConfig)
local folder = RS:WaitForChild("ACFame")
local event = folder:WaitForChild("Display")
local demo = folder:WaitForChild("Demo")
local queue, seen, seenOrder, cooldown = {}, {}, {}, {}
local champion, current = nil, nil
local kinds = {comment=true, follow=true, rose=true, necklace=true, donut=true, heart=true}
local serial = 0
local control=folder:FindFirstChild("Connection") or Instance.new("RemoteEvent")
control.Name="Connection" control.Parent=folder
local connectionOwner=nil
local sessionToken=nil
local generation=0
local busy=false
local connectCooldown={}
local function canControl(p)
	if Run:IsStudio() then return true end
	if game.PrivateServerOwnerId>0 and p.UserId==game.PrivateServerOwnerId then return true end
	if game.CreatorType==Enum.CreatorType.User and p.UserId==game.CreatorId then return true end
	return table.find(Config.AllowedUserIds or {},p.UserId)~=nil
end
local function connectionState(state,channel)
	folder:SetAttribute("BridgeStatus",state)
	if channel~=nil then folder:SetAttribute("Channel",channel) end
end
local function request(path,method,token,body)
	local options={Url=Config.BridgeUrl..path,Method=method,Headers={["X-Fame-Key"]=Config.BridgeKey,["X-Fame-Session"]=token}}
	if body then options.Headers["Content-Type"]="application/json" options.Body=Http:JSONEncode(body) end
	local res=Http:RequestAsync(options)
	assert(res.Success,"Bridge HTTP "..res.StatusCode)
	return Http:JSONDecode(res.Body)
end
local function disconnect()
	generation+=1
	local old=sessionToken sessionToken=nil connectionOwner=nil busy=false
	queue={} seen={} seenOrder={} champion=nil current=nil
	connectionState("DISCONNECTED","") event:FireAllClients("reset")
	if old then task.spawn(function() pcall(request,"/disconnect","POST",old,{}) end) end
end
local function normalize(raw, trustedDemo)
	if type(raw) ~= "table" or not kinds[raw.kind] then return end
	local id = tostring(raw.id or ""):sub(1,120)
	if id == "" or seen[id] then return end
	local name = tostring(raw.name or raw.uniqueId or "viewer"):sub(1,160)
	if not utf8.len(name) then name = "viewer" end
	if not trustedDemo and not Run:IsStudio() then
		local host = Players:GetPlayers()[1]
		if not host then return end
		local ok, filtered = pcall(function()
			return Text:FilterStringAsync(name, host.UserId):GetNonChatStringForBroadcastAsync()
		end)
		name = ok and filtered or "viewer"
	end
	local e = {id=id,kind=raw.kind,name=name,uniqueId=tostring(raw.uniqueId or ""):sub(1,80)}
	local asset = tostring(raw.avatarAssetId or "")
	if asset:match("^%d+$") then e.avatarAssetId = asset end
	if Run:IsStudio() and Config.AllowStudioPixels and type(raw.pixels)=="table" and #raw.pixels==1024 then
		local valid=true
		for _,v in ipairs(raw.pixels) do if type(v)~="number" or v~=math.floor(v) or v<0 or v>16777215 then valid=false break end end
		if valid then e.pixels=raw.pixels end
	end
	seen[id]=true table.insert(seenOrder,id)
	if #seenOrder>2000 then seen[table.remove(seenOrder,1)]=nil end
	return e
end
local function accept(raw, trustedDemo, expectedGeneration)
	local e=normalize(raw,trustedDemo)
	if expectedGeneration and generation~=expectedGeneration then return end
	if not e then return end
	if e.kind=="heart" then champion=e event:FireAllClients("champion",e) return end
	if #queue >= Config.MaxQueue then
		-- Prefer gifts over comments under load; memory stays bounded.
		local removeIndex
		for i,v in ipairs(queue) do if v.kind=="comment" then removeIndex=i break end end
		if not removeIndex then return end
		table.remove(queue,removeIndex)
	end
	table.insert(queue,e)
end
demo.OnServerEvent:Connect(function(player,kind)
	if kind=="sync" then
		if current then event:FireClient(player,"display",current) end
		if champion then event:FireClient(player,"champion",champion,true) end
		return
	end
	if not Run:IsStudio() or not kinds[kind] then return end
	if os.clock()-(cooldown[player] or 0)<0.4 then return end
	cooldown[player]=os.clock() serial+=1
	local pixels={}
	for y=0,31 do for x=0,31 do
		local face=(x-16)^2+(y-16)^2<150
		local eye=(y>=11 and y<=14) and ((x>=10 and x<=12) or (x>=20 and x<=22))
		local smile=y>=21 and y<=23 and x>=11 and x<=21
		pixels[#pixels+1]=(eye or smile) and 0x182135 or (face and 0xFFE0AA or 0x27DCC5)
	end end
	accept({id="demo-"..serial,kind=kind,name="@"..player.DisplayName, pixels=pixels},true)
end)
Players.PlayerRemoving:Connect(function(p)
	cooldown[p]=nil connectCooldown[p]=nil
	if connectionOwner==p then disconnect() end
end)
control.OnServerEvent:Connect(function(p,action,username)
	if action=="sync" then control:FireClient(p,"permission",canControl(p)) return end
	if not canControl(p) then control:FireClient(p,"message","เฉพาะเจ้าของแมพหรือเจ้าของเซิร์ฟเวอร์ส่วนตัวเท่านั้น") return end
	if os.clock()-(connectCooldown[p] or -10)<3 then return end
	connectCooldown[p]=os.clock()
	if action=="disconnect" then disconnect() return end
	if action~="connect" or busy then return end
	if type(username)~="string" then return end
	username=username:match("^%s*(.-)%s*$"):gsub("^@",""):lower()
	if #username<1 or #username>24 or not username:match("^[%w_][%w_%.]*$") then
		control:FireClient(p,"message","กรอกชื่อช่อง TikTok เช่น @yourname ไม่ใช่ลิงก์") return
	end
	if not Config.LiveEnabled or Config.BridgeUrl=="" or #Config.BridgeKey<20 then
		connectionState("SETUP_REQUIRED") control:FireClient(p,"message","ระบบเชื่อมต่อยังไม่พร้อม กรุณาติดต่อผู้ขาย") return
	end
	if not Run:IsStudio() and not Config.BridgeUrl:match("^https://") then
		connectionState("SETUP_REQUIRED") return
	end
	disconnect()
	busy=true connectionOwner=p sessionToken=Http:GenerateGUID(false)
	local token=sessionToken local version=generation
	connectionState("CONNECTING",username)
	local ok=pcall(request,"/connect","POST",token,{username=username})
	if generation~=version then
		pcall(request,"/disconnect","POST",token,{}) return
	end
	busy=false
	if not ok then sessionToken=nil connectionState("ERROR") return end
	local cursor=0
	task.spawn(function()
		while sessionToken==token and generation==version do
			local success,body=pcall(request,"/session/events?after="..cursor,"GET",token)
			if generation~=version then return end
			if success and type(body)=="table" and type(body.events)=="table" and type(body.cursor)=="number" then
				connectionState(body.status or "ERROR")
				for i,e in ipairs(body.events) do if i>50 or generation~=version then break end accept(e,false,version) end
				cursor=body.cursor
				if body.status=="OFFLINE" or body.status=="ERROR" or body.status=="DISCONNECTED" then
					sessionToken=nil task.spawn(function() pcall(request,"/disconnect","POST",token,{}) end) return
				end
			else connectionState("RETRYING") end
			task.wait(Config.PollSeconds)
		end
	end)
end)
game:BindToClose(function() if sessionToken then pcall(request,"/disconnect","POST",sessionToken,{}) end end)
task.spawn(function()
	while true do
		if #queue>0 then
			current=table.remove(queue,1)
			event:FireAllClients("display",current)
			task.wait((current.kind=="necklace" or current.kind=="donut") and (Config.PhotoDisplaySeconds or 14) or Config.DisplaySeconds)
		else task.wait(0.2) end
	end
end)
connectionState("DISCONNECTED","")
print("AC Fame ready — Studio demo buttons enabled; live="..tostring(Config.LiveEnabled))
