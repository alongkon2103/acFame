local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local folder=RS:WaitForChild("ACFame")
local FameUI=require(folder:WaitForChild("FameUI"))
local ui=FameUI.new(player)
local gui=ui.gui
local control=folder:WaitForChild("Connection")
local function updateConnection()
	ui:setConnection(folder:GetAttribute("BridgeStatus") or "DISCONNECTED",folder:GetAttribute("Channel"))
end
local function connect()
	if folder:GetAttribute("BridgeStatus")=="CONNECTING" then return end
	if ui.channelInput.Text:match("^%s*$") then
		ui.connectionMessage.Text="กรอกชื่อช่อง TikTok ก่อนเชื่อมต่อ"
		ui.channelInput:CaptureFocus()
		return
	end
	ui.connectionMessage.Text="กำลังส่งคำขอ…"
	control:FireServer("connect",ui.channelInput.Text)
end
ui.connectButton.Activated:Connect(connect)
ui.channelInput.FocusLost:Connect(function(enter) if enter then connect() end end)
ui.disconnectButton.Activated:Connect(function() control:FireServer("disconnect") end)
control.OnClientEvent:Connect(function(kind,value)
	if kind=="permission" then ui:setPermission(value==true)
	elseif kind=="message" then ui.connectionMessage.Text=tostring(value)
	elseif kind=="overlay" and type(value)=="string" then ui:setOverlay(value) end
end)
folder:GetAttributeChangedSignal("BridgeStatus"):Connect(updateConnection)
folder:GetAttributeChangedSignal("Channel"):Connect(updateConnection)
updateConnection() control:FireServer("sync")
for kind,b in pairs(ui.demoButtons) do
	b.Activated:Connect(function() folder.Demo:FireServer(kind) end)
end
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
local viewButton=ui.viewButton
local function restoreCamera()
	if cinematicPanels then ui:setCinematic(false) cinematicPanels=nil end
	ui:setView(viewLocked)
	painter:setEnabled(viewLocked)
	if viewLocked then camera.CameraType=Enum.CameraType.Scriptable camera.CFrame=boardView() camera.FieldOfView=60
	else camera.CameraType=Enum.CameraType.Custom camera.FieldOfView=70 camera.CameraSubject=player.Character and player.Character:FindFirstChildOfClass("Humanoid") end
end
viewButton.Activated:Connect(function() cameraVersion+=1 viewLocked=not viewLocked restoreCamera() end)
restoreCamera()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if viewLocked and not cinematicPanels then restoreCamera() end end)
player.CharacterAdded:Connect(function() task.wait(.5) restoreCamera() end)
local displayVersion=0
local function idleBoards()
	root:ClearAllChildren() championRoot:ClearAllChildren()
	label(root,"ฝากชื่อไว้บนกำแพง",UDim2.fromScale(.12,.38),UDim2.fromScale(.76,.18),Color3.fromRGB(224,211,244))
	label(root,"เขียนชื่อ · วาดภาพ · เก็บความทรงจำ",UDim2.fromScale(.2,.61),UDim2.fromScale(.6,.055),Color3.fromRGB(151,133,179))
	label(championRoot,"HALL OF FAME",UDim2.fromScale(.16,.4),UDim2.fromScale(.68,.12),gold)
end
local function show(e)
	ui:setCurrent(e)
	displayVersion+=1 local version=displayVersion
	root:ClearAllChildren()
	portraitPainting=nil
	local isPhoto=e.kind=="necklace" or e.kind=="donut"
	local isBig=e.kind=="donut"
	local color=isBig and pink or cyan
	local heading=e.id:sub(1,11)=="like-photo:" and "LIKE PORTRAIT  /  15" or (isBig and "FEATURED PORTRAIT" or (isPhoto and "CREATOR PORTRAIT" or "THE NAME WALL"))
	label(root,heading,UDim2.fromScale(.1,.06),UDim2.fromScale(.8,.055),color)
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
	ui:setCurrent(e)
	championRoot:ClearAllChildren() wings={}
	label(championRoot,"TOP SUPPORTER",UDim2.fromScale(.2,.04),UDim2.fromScale(.6,.09),gold)
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
	cinematicPanels=true
	ui:setCinematic(true)
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
		ui.hint.Text="ฝากชื่อไว้บนกำแพงแห่งนี้"
		displayVersion+=1 cameraVersion+=1 wings={} writing=nil portraitPainting=nil championPainting=nil
		idleBoards()
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
idleBoards()
folder.Demo:FireServer("sync")
