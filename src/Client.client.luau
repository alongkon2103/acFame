local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local folder=RS:WaitForChild("ACFame")
local map=workspace:WaitForChild("ACFame_Backup")
local BrushWriter=require(folder:WaitForChild("BrushWriter"))
local ArtistController=require(folder:WaitForChild("ArtistController"))
local PhotoPainter=require(folder:WaitForChild("PhotoPainter"))
local painter=ArtistController.new(map,player)
local writing=nil
local portraitPainting=nil
local championPainting=nil
local screen=map:WaitForChild("Canvas"):WaitForChild("SurfaceGui")
local root=screen:WaitForChild("Root")
local championRoot=map:WaitForChild("ChampionCanvas"):WaitForChild("SurfaceGui"):WaitForChild("Root")
local function make(class,parent,props)
	local v=Instance.new(class) for k,x in pairs(props) do v[k]=x end v.Parent=parent return v
end
local white=Color3.fromRGB(241,248,255)
local cyan=Color3.fromRGB(40,230,214)
local pink=Color3.fromRGB(255,64,137)
local gold=Color3.fromRGB(255,209,103)
local function label(parent,text,pos,size,color)
	return make("TextLabel",parent,{BackgroundTransparency=1,Position=pos,Size=size,Text=text,TextColor3=color or white,Font=Enum.Font.GothamBold,TextScaled=true,RichText=false})
end
local gui=make("ScreenGui",player:WaitForChild("PlayerGui"),{Name="ACFameHUD",ResetOnSpawn=false,IgnoreGuiInset=false})
local status=label(gui,"AC FAME  /  DEMO",UDim2.fromScale(.025,.025),UDim2.fromScale(.3,.045),cyan)
status.TextXAlignment=Enum.TextXAlignment.Left
local function statusUpdate() status.Text="AC FAME  /  "..tostring(folder:GetAttribute("BridgeStatus") or "STARTING") end
folder:GetAttributeChangedSignal("BridgeStatus"):Connect(statusUpdate) statusUpdate()
local control=folder:WaitForChild("Connection")
local connectPanel=make("Frame",gui,{Name="TikTokConnect",Position=UDim2.fromScale(.025,.17),Size=UDim2.fromScale(.235,.31),BackgroundColor3=Color3.fromRGB(12,18,32),BackgroundTransparency=.06,Visible=false})
make("UICorner",connectPanel,{CornerRadius=UDim.new(0,14)})
local canConnect=false
local connectionToggle=make("TextButton",gui,{Name="ConnectionToggle",Position=UDim2.fromScale(.81,.025),Size=UDim2.fromScale(.17,.045),BackgroundColor3=Color3.fromRGB(25,38,55),Text="เชื่อม TikTok",TextColor3=white,TextScaled=true,Font=Enum.Font.GothamBold,Visible=false})
make("UICorner",connectionToggle,{CornerRadius=UDim.new(0,8)})
connectionToggle.Activated:Connect(function() if canConnect then connectPanel.Visible=not connectPanel.Visible end end)
label(connectPanel,"TIKTOK LIVE",UDim2.fromScale(.06,.06),UDim2.fromScale(.88,.12),cyan)
local channelInput=make("TextBox",connectPanel,{Name="ChannelInput",Position=UDim2.fromScale(.06,.25),Size=UDim2.fromScale(.88,.22),BackgroundColor3=Color3.fromRGB(30,40,61),Text="",PlaceholderText="@ชื่อช่อง TikTok",ClearTextOnFocus=false,TextColor3=white,PlaceholderColor3=Color3.fromRGB(143,160,180),Font=Enum.Font.Gotham,TextScaled=true})
make("UICorner",channelInput,{CornerRadius=UDim.new(0,8)})
local connectButton=make("TextButton",connectPanel,{Name="Connect",Position=UDim2.fromScale(.06,.53),Size=UDim2.fromScale(.53,.19),BackgroundColor3=cyan,Text="Connect",TextColor3=Color3.fromRGB(12,30,40),Font=Enum.Font.GothamBold,TextScaled=true})
local disconnectButton=make("TextButton",connectPanel,{Name="Disconnect",Position=UDim2.fromScale(.62,.53),Size=UDim2.fromScale(.32,.19),BackgroundColor3=Color3.fromRGB(72,35,54),Text="ยกเลิก",TextColor3=white,Font=Enum.Font.GothamBold,TextScaled=true})
for _,b in ipairs({connectButton,disconnectButton}) do make("UICorner",b,{CornerRadius=UDim.new(0,8)}) end
local connectionMessage=label(connectPanel,"เปิดไลฟ์ TikTok แล้วกด Connect",UDim2.fromScale(.06,.78),UDim2.fromScale(.88,.16),white)
connectionMessage.Name="ConnectionMessage"
local overlayPanel=make("Frame",connectPanel,{Name="OverlayPanel",Position=UDim2.new(0,0,1,12),Size=UDim2.new(1.6,0,0,138),BackgroundColor3=Color3.fromRGB(18,12,35),Visible=false})
make("UICorner",overlayPanel,{CornerRadius=UDim.new(0,12)})
make("UIStroke",overlayPanel,{Thickness=1,Color=Color3.fromRGB(149,75,220)})
label(overlayPanel,"OVERLAY ของคุณ · 640 × 176",UDim2.new(0,12,0,8),UDim2.new(1,-24,0,22),cyan)
local overlayLink=make("TextBox",overlayPanel,{Name="OverlayLink",Position=UDim2.new(0,12,0,36),Size=UDim2.new(1,-24,0,32),BackgroundColor3=Color3.fromRGB(31,24,49),Text="",TextColor3=white,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ClipsDescendants=true,ClearTextOnFocus=false,TextEditable=false})
make("UICorner",overlayLink,{CornerRadius=UDim.new(0,6)})
local selectOverlay=make("TextButton",overlayPanel,{Name="SelectOverlayLink",Position=UDim2.new(0,12,0,76),Size=UDim2.new(1,-24,0,28),BackgroundColor3=Color3.fromRGB(100,49,165),Text="เลือกลิงก์เพื่อคัดลอก",TextColor3=white,Font=Enum.Font.GothamBold,TextSize=14})
make("UICorner",selectOverlay,{CornerRadius=UDim.new(0,6)})
label(overlayPanel,"กด Ctrl+C / Cmd+C แล้ววางใน Browser Source",UDim2.new(0,12,0,110),UDim2.new(1,-24,0,18),Color3.fromRGB(183,166,206))
local function selectLink()
	overlayLink:CaptureFocus()
	task.defer(function() overlayLink.CursorPosition=#overlayLink.Text+1 overlayLink.SelectionStart=1 end)
end
selectOverlay.Activated:Connect(selectLink)
local messages={DISCONNECTED="เปิดไลฟ์ TikTok แล้วกด Connect",CONNECTING="กำลังเชื่อมต่อ…",LIVE="เชื่อมต่อแล้ว",OFFLINE="ช่องยังไม่เปิดไลฟ์ เปิดไลฟ์แล้วลองใหม่",ERROR="เชื่อมต่อไม่สำเร็จ กรุณาลองใหม่",RETRYING="ขาดการเชื่อมต่อ กำลังลองอีกครั้ง…",SETUP_REQUIRED="ระบบยังไม่พร้อม กรุณาติดต่อผู้ขาย"}
local function updateConnection()
	local s=folder:GetAttribute("BridgeStatus") or "DISCONNECTED"
	connectionMessage.Text=messages[s] or s
	if s=="LIVE" then connectionMessage.Text="เชื่อมต่อ @"..tostring(folder:GetAttribute("Channel") or "") end
	connectButton.Text=s=="CONNECTING" and "Connecting…" or "Connect"
	connectButton.Active=s~="CONNECTING"
	connectButton.AutoButtonColor=s~="CONNECTING"
end
local function connect()
	if folder:GetAttribute("BridgeStatus")=="CONNECTING" then return end
	connectionMessage.Text="กำลังส่งคำขอ…"
	control:FireServer("connect",channelInput.Text)
end
connectButton.Activated:Connect(connect)
channelInput.FocusLost:Connect(function(enter) if enter then connect() end end)
disconnectButton.Activated:Connect(function() control:FireServer("disconnect") end)
control.OnClientEvent:Connect(function(kind,value)
	if kind=="permission" then canConnect=value==true connectionToggle.Visible=canConnect if not canConnect then connectPanel.Visible=false end
	elseif kind=="message" then connectionMessage.Text=tostring(value) end
	if kind=="overlay" and type(value)=="string" then
		overlayLink.Text=value
		overlayPanel.Visible=true
	end
end)
folder:GetAttributeChangedSignal("BridgeStatus"):Connect(updateConnection)
folder:GetAttributeChangedSignal("Channel"):Connect(updateConnection)
updateConnection() control:FireServer("sync")
local hint=label(gui,"แสดงความคิดเห็น • ฝากชื่อไว้บนกำแพง",UDim2.fromScale(.2,.92),UDim2.fromScale(.6,.045))
local buttons=make("Frame",gui,{BackgroundColor3=Color3.fromRGB(12,18,32),BackgroundTransparency=.12,Position=UDim2.fromScale(.795,.16),Size=UDim2.fromScale(.19,.5),Visible=false})
local demoToggle=make("TextButton",gui,{Name="DemoToggle",Position=UDim2.fromScale(.81,.085),Size=UDim2.fromScale(.17,.045),BackgroundColor3=Color3.fromRGB(25,38,55),Text="ทดสอบอีเวนต์",TextColor3=white,TextScaled=true,Font=Enum.Font.GothamBold,Visible=Run:IsStudio()})
make("UICorner",demoToggle,{CornerRadius=UDim.new(0,8)})
demoToggle.Activated:Connect(function() buttons.Visible=not buttons.Visible end)
make("UICorner",buttons,{CornerRadius=UDim.new(0,14)})
label(buttons,"ทดสอบอีเวนต์",UDim2.fromScale(.05,.02),UDim2.fromScale(.9,.08),cyan)
local entries={{"comment","พิมพ์ข้อความ"},{"follow","ติดตาม"},{"rose","กุหลาบ · 1"},{"necklace","สร้อยคอ · 10"},{"donut","โดนัท · 30"},{"heart","อุ้มใจ · 100"}}
for i,item in ipairs(entries) do
	local b=make("TextButton",buttons,{Position=UDim2.fromScale(.07,.12+(i-1)*.14),Size=UDim2.fromScale(.86,.115),BackgroundColor3=i==6 and Color3.fromRGB(101,64,29) or Color3.fromRGB(30,40,61),Text=item[2],TextColor3=white,Font=Enum.Font.GothamBold,TextScaled=true})
	make("UICorner",b,{CornerRadius=UDim.new(0,8)})
	b.Activated:Connect(function() folder.Demo:FireServer(item[1]) end)
end
local camera=workspace.CurrentCamera
local viewLocked=true
local cameraVersion=0
local cinematicPanels=nil
local function boardView()
	local viewport=camera.ViewportSize
	local aspect=math.max(.5,viewport.X/math.max(1,viewport.Y))
	local tangent=math.tan(math.rad(60/2))
	local distance=math.max(78,112/(2*tangent*aspect*.92))
	return CFrame.lookAt(Vector3.new(-5,15,distance),Vector3.new(-5,18,0))
end
local viewButton=make("TextButton",gui,{Position=UDim2.fromScale(.025,.09),Size=UDim2.fromScale(.19,.045),BackgroundColor3=Color3.fromRGB(25,38,55),Text="กล้องไลฟ์ / เดินสำรวจ",TextScaled=true,TextColor3=white,Font=Enum.Font.Gotham})
make("UICorner",viewButton,{CornerRadius=UDim.new(0,8)})
local function restoreCamera()
	if cinematicPanels then
		connectPanel.Visible=cinematicPanels[1] buttons.Visible=cinematicPanels[2] hint.Visible=cinematicPanels[3] status.Visible=cinematicPanels[4]
		connectionToggle.Visible=cinematicPanels[5] demoToggle.Visible=cinematicPanels[6]
		cinematicPanels=nil
	end
	painter:setEnabled(viewLocked)
	if viewLocked then camera.CameraType=Enum.CameraType.Scriptable camera.CFrame=boardView() camera.FieldOfView=60
	else camera.CameraType=Enum.CameraType.Custom camera.FieldOfView=70 camera.CameraSubject=player.Character and player.Character:FindFirstChildOfClass("Humanoid") end
end
viewButton.Activated:Connect(function() cameraVersion+=1 viewLocked=not viewLocked restoreCamera() end)
restoreCamera()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if viewLocked and not cinematicPanels then restoreCamera() end end)
player.CharacterAdded:Connect(function() task.wait(.5) restoreCamera() end)
local function avatar(parent,e,pos,size)
	local box=make("Frame",parent,{Name="Portrait",Position=pos,Size=size,BackgroundColor3=Color3.fromRGB(28,57,67),BorderSizePixel=0,ClipsDescendants=true})
	make("UICorner",box,{CornerRadius=UDim.new(0,18)})
	if e.avatarAssetId then
		make("ImageLabel",box,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image="rbxassetid://"..e.avatarAssetId,ScaleType=Enum.ScaleType.Crop})
	elseif e.pixels then
		for i,v in ipairs(e.pixels) do
			local x=(i-1)%32 local y=math.floor((i-1)/32)
			make("Frame",box,{BorderSizePixel=0,Position=UDim2.fromScale(x/32,y/32),Size=UDim2.new(1/32,1,1/32,1),BackgroundColor3=Color3.fromRGB(math.floor(v/65536),math.floor(v/256)%256,v%256)})
		end
	else label(box,"@",UDim2.fromScale(.1,.1),UDim2.fromScale(.8,.8),cyan) end
	return box
end
local displayVersion=0
local function show(e)
	displayVersion+=1 local version=displayVersion
	root:ClearAllChildren()
	portraitPainting=nil
	local isPhoto=e.kind=="necklace" or e.kind=="donut"
	local isBig=e.kind=="donut"
	local color=isBig and pink or cyan
	label(root,isBig and "FEATURED CREATOR / 30" or (isPhoto and "CREATOR PORTRAIT / 10" or "LEAVE YOUR MARK"),UDim2.fromScale(.06,.05),UDim2.fromScale(.88,.08),color)
	if isPhoto then
		portraitPainting=PhotoPainter.new(root,e,{x=isBig and .38 or .41,y=.15,w=isBig and .24 or .18,h=isBig and .56 or .42},6)
		if isBig then make("UIStroke",portraitPainting.holder,{Thickness=7,Color=pink}) end
	end
	writing=BrushWriter.new(root,e.name,{x=.07,y=isPhoto and .72 or .37,w=.86,h=isPhoto and .14 or .27},Color3.fromRGB(243,230,255),5.5)
	local line=make("Frame",root,{BackgroundColor3=color,BorderSizePixel=0,Position=UDim2.fromScale(.12,isPhoto and .89 or .66),Size=UDim2.fromScale(0,.008)})
	Tween:Create(line,TweenInfo.new(.7,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0,false,isPhoto and 11.5 or 5.5),{Size=UDim2.fromScale(.76,.008)}):Play()
	if e.kind=="follow" then label(root,"ติดตาม",UDim2.fromScale(.2,.72),UDim2.fromScale(.6,.12),Color3.fromRGB(15,146,143)) end
	if e.kind=="rose" then label(root,"ขอบคุณสำหรับกุหลาบ",UDim2.fromScale(.2,.75),UDim2.fromScale(.6,.08),pink) end
end
local wingRest={}
local wings={}
local function showChampion(e,quiet)
	championRoot:ClearAllChildren() wings={}
	label(championRoot,"★  TOP SUPPORTER  ★",UDim2.fromScale(.2,.02),UDim2.fromScale(.6,.13),gold)
	championPainting=PhotoPainter.new(championRoot,e,{x=.32,y=.15,w=.36,h=.593,canvasHeight=850},quiet and .05 or 3)
	make("UIStroke",championPainting.holder,{Thickness=6,Color=gold})
	for _,side in ipairs({-1,1}) do
		local wing=map:FindFirstChild(side<0 and "ChampionWingLeft" or "ChampionWingRight")
		if wing then
			local pivot=CFrame.new(27+side*14.9,14,-5.6)
			local parts={}
			for _,p in wing:GetDescendants() do if p:IsA("BasePart") then wingRest[p]=wingRest[p] or p.CFrame table.insert(parts,{part=p,offset=pivot:ToObjectSpace(wingRest[p])}) end end
			table.insert(wings,{parts=parts,pivot=pivot,side=side})
		end
	end
	label(championRoot,e.name,UDim2.fromScale(.08,.77),UDim2.fromScale(.84,.11),white)
	label(championRoot,"อุ้มใจ 100 • อยู่จนกว่าจะมีผู้ส่งอุ้มใจคนถัดไป",UDim2.fromScale(.1,.9),UDim2.fromScale(.8,.07),gold)
	if quiet then return end
	if not cinematicPanels then cinematicPanels={connectPanel.Visible,buttons.Visible,hint.Visible,status.Visible,connectionToggle.Visible,demoToggle.Visible} end
	connectPanel.Visible=false buttons.Visible=false hint.Visible=false status.Visible=false
	connectionToggle.Visible=false demoToggle.Visible=false
	cameraVersion+=1 local version=cameraVersion
	camera.CameraType=Enum.CameraType.Scriptable
	local monument=map.ChampionCanvas
	local focal=monument.Position
	camera.CFrame=CFrame.lookAt(focal+Vector3.new(-22,7,35),focal)
	local flash=make("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=gold,BackgroundTransparency=.2,BorderSizePixel=0,ZIndex=10})
	Tween:Create(flash,TweenInfo.new(.8),{BackgroundTransparency=1}):Play()
	game:GetService("Debris"):AddItem(flash,1)
	local tween=Tween:Create(camera,TweenInfo.new(2.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{CFrame=CFrame.lookAt(focal+Vector3.new(0,5,48),focal+Vector3.new(0,3,0)),FieldOfView=52})
	tween:Play()
	task.delay(3.4,function() if version==cameraVersion then restoreCamera() end end)
	-- A replaced cutscene must not leave an older camera tween running.
	local conn conn=Run.RenderStepped:Connect(function() if version~=cameraVersion then tween:Cancel() conn:Disconnect() end end)
	task.delay(3.5,function() conn:Disconnect() end)
end
folder.Display.OnClientEvent:Connect(function(kind,e,quiet)
	if kind=="reset" then
		displayVersion+=1 cameraVersion+=1 wings={} writing=nil portraitPainting=nil championPainting=nil
		root:ClearAllChildren() championRoot:ClearAllChildren()
		label(root,"YOUR NAME BELONGS HERE",UDim2.fromScale(.05,.35),UDim2.fromScale(.9,.2),Color3.fromRGB(243,230,255))
		label(championRoot,"HALL OF FAME",UDim2.fromScale(.2,.3),UDim2.fromScale(.6,.3),gold)
		restoreCamera()
	elseif kind=="champion" then showChampion(e,quiet) else show(e) end
end)
Run.RenderStepped:Connect(function(dt)
	local t=os.clock()
	for _,w in ipairs(wings) do
		local pose=w.pivot*CFrame.Angles(0,w.side*math.sin(t*1.4)*.075,w.side*math.sin(t*1.4)*.018)
		for _,p in w.parts do p.part.CFrame=pose*p.offset end
	end
	local uv,lift
	if championPainting and not championPainting.done then championPainting:step(dt) end
	if portraitPainting and not portraitPainting.done then uv=portraitPainting:step(dt)
	elseif writing and not writing.done then uv,lift=writing:step(dt) end
	painter:step(dt,uv,lift)
end)
folder.Demo:FireServer("sync")
