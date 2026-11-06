local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Players = game:GetService("Players")
local Text = game:GetService("TextService")
local Config = require(script.Parent.FameConfig)
local Access=require(script.Parent:WaitForChild("AccessControl"))
local folder = RS:WaitForChild("ACFame")
local EventQueue=require(folder:WaitForChild("EventQueue"))
local ViewerIdentity=require(folder:WaitForChild("ViewerIdentity"))
local WritingPayload=require(folder:WaitForChild("WritingPayload"))
local PortraitPayload=require(folder:WaitForChild("PortraitPayload"))
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
local overlayUrl=nil
local overlayOwnerId=nil
local overlayRequests={}
local function canControl(p)
	if not Access.allowed(p) then return false end
	if Run:IsStudio() then return true end
	if #Players:GetPlayers()==1 or connectionOwner==p then return true end
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
local function prepareOverlay(p)
	if not canControl(p) then return end
	if overlayOwnerId==p.UserId and overlayUrl then control:FireClient(p,"overlay",overlayUrl) return end
	if overlayRequests[p.UserId] then return end
	if Config.BridgeUrl=="" or #Config.BridgeKey<20 or (not Run:IsStudio() and not Config.BridgeUrl:match("^https://")) then return end
	overlayRequests[p.UserId]=true
	task.spawn(function()
		local ok,body=pcall(request,"/overlay/link","POST",Http:GenerateGUID(false),{ownerId=p.UserId})
		overlayRequests[p.UserId]=nil
		if p.Parent~=Players or not canControl(p) then return end
		if ok and type(body)=="table" and type(body.overlayPath)=="string" and body.overlayPath:match("^/overlay%?view=%x+$") then
			overlayUrl=Config.BridgeUrl..body.overlayPath overlayOwnerId=p.UserId
			control:FireClient(p,"overlay",overlayUrl)
		else control:FireClient(p,"message","Could not prepare overlay links. Reopen Live setup to retry.") end
	end)
end
local displayRevision=0
local function updateOverlay(e)
	local token=sessionToken
	if not token then return end
	displayRevision+=1
	local revision=displayRevision
	task.spawn(function()
		local ok=pcall(request,"/overlay/current","POST",token,{id=e.id,revision=revision})
		if not ok and sessionToken==token and displayRevision==revision then
			task.wait(.5)
			if sessionToken==token and displayRevision==revision then pcall(request,"/overlay/current","POST",token,{id=e.id,revision=revision}) end
		end
	end)
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
local host=Players:GetPlayers()[1]
	if not trustedDemo and not Run:IsStudio() and not host then return end
	local name=ViewerIdentity.name(raw,function(candidate)
		if trustedDemo or Run:IsStudio() then return candidate end
		return Text:FilterStringAsync(candidate,host.UserId):GetNonChatStringForBroadcastAsync()
	end)
	local e={id=id,kind=raw.kind,name=name,uniqueId=tostring(raw.uniqueId or ""):sub(1,80)}
	if Config.BridgeUrl~="" and #Config.BridgeKey>=20 then
		local ok,result=pcall(request,"/writing/paths","POST",Http:GenerateGUID(false),{text=name})
		if ok then
			e.writing=WritingPayload.read(result)
			if e.writing and type(result.text)=="string" and utf8.len(result.text) and #result.text<=640 then e.name=result.text end
		end
		folder:SetAttribute("LastWritingStatus",e.writing and "STROKES_READY" or "PATH_UNAVAILABLE")
	end
	e.avatarAssetId=ViewerIdentity.asset(raw.avatarAssetId)
	e.pixels=PortraitPayload.read(raw.pixels,Config.AllowProfilePixels==true or (Run:IsStudio() and Config.AllowStudioPixels))
	if raw.kind=="necklace" or raw.kind=="donut" or raw.kind=="heart" then
		folder:SetAttribute("LastPortraitStatus",e.pixels and "PIXELS_READY" or e.avatarAssetId and "ASSET_PROVIDED" or "NO_IMAGE_FROM_BACKEND")
	end
	seen[id]=true table.insert(seenOrder,id)
	if #seenOrder>2000 then seen[table.remove(seenOrder,1)]=nil end
	return e
end
local function accept(raw, trustedDemo, expectedGeneration)
	local e=normalize(raw,trustedDemo)
	if expectedGeneration and generation~=expectedGeneration then return end
	if not e then return end
	if #queue >= Config.MaxQueue then
		-- Prefer gifts over comments under load; memory stays bounded.
		local removeIndex
		for i,v in ipairs(queue) do if v.kind=="comment" then removeIndex=i break end end
		if not removeIndex then return end
		table.remove(queue,removeIndex)
	end
	EventQueue.push(queue,e)
end
demo.OnServerEvent:Connect(function(player,kind)
	if not Access.allowed(player) then return end
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
	if action=="sync" then
		control:FireClient(p,"permission",canControl(p))
		prepareOverlay(p)
		return
	end
	if not canControl(p) then control:FireClient(p,"message","Only this server's controller can connect.") return end
	if os.clock()-(connectCooldown[p] or -10)<3 then return end
	connectCooldown[p]=os.clock()
	if action=="disconnect" then disconnect() return end
	if action~="connect" or busy then return end
	if type(username)~="string" then return end
	username=username:match("^%s*(.-)%s*$"):gsub("^@",""):lower()
	if #username<1 or #username>24 or not username:match("^[%w_][%w_%.]*$") then
		control:FireClient(p,"message","Enter a TikTok handle, such as @yourname, not a URL.") return
	end
	if not Config.LiveEnabled or Config.BridgeUrl=="" or #Config.BridgeKey<20 then
		connectionState("SETUP_REQUIRED") control:FireClient(p,"message","Connection setup is missing. Contact the host.") return
	end
	if not Run:IsStudio() and not Config.BridgeUrl:match("^https://") then
		connectionState("SETUP_REQUIRED") return
	end
	disconnect()
	busy=true connectionOwner=p sessionToken=Http:GenerateGUID(false)
	local token=sessionToken local version=generation
	connectionState("CONNECTING",username)
	local ok,body=pcall(request,"/connect","POST",token,{username=username,ownerId=p.UserId})
	if generation~=version then
		pcall(request,"/disconnect","POST",token,{}) return
	end
	busy=false
	if not ok then sessionToken=nil connectionState("ERROR") return end
	if type(body)=="table" and type(body.overlayPath)=="string" and body.overlayPath:match("^/overlay%?view=%x+$") then
		overlayUrl=Config.BridgeUrl..body.overlayPath
		overlayOwnerId=p.UserId
		control:FireClient(p,"overlay",overlayUrl)
	end
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
Access.changed.Event:Connect(function(player)
	if player.Parent~=Players then return end
	control:FireClient(player,"permission",canControl(player))
	if Access.allowed(player) then prepareOverlay(player)
	elseif connectionOwner==player then disconnect() end
end)
game:BindToClose(function() if sessionToken then pcall(request,"/disconnect","POST",sessionToken,{}) end end)
task.spawn(function()
	while true do
		if #queue>0 then
			local nextEvent=table.remove(queue,1)
			if nextEvent.kind=="heart" then
				champion=nextEvent event:FireAllClients("champion",nextEvent) updateOverlay(nextEvent)
				task.wait(7.2)
			else
				current=nextEvent event:FireAllClients("display",current) updateOverlay(current)
				task.wait(current.kind=="donut" and (Config.LargePhotoDisplaySeconds or 9.7) or current.kind=="necklace" and (Config.PhotoDisplaySeconds or 7.7) or (Config.DisplaySeconds or 3.7))
			end
		else task.wait(0.2) end
	end
end)
connectionState("DISCONNECTED","")
print("AC Fame ready — Studio demo buttons enabled; live="..tostring(Config.LiveEnabled))
