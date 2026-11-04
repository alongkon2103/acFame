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
		ui.connectionMessage.Text="Enter your TikTok handle first."
		ui.channelInput:CaptureFocus()
		return
	end
	ui.connectionMessage.Text="Sending request…"
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
ui.connectionToggle.Activated:Connect(function() control:FireServer("sync") end)
for kind,b in pairs(ui.demoButtons) do
	b.Activated:Connect(function() folder.Demo:FireServer(kind) end)
end
local map=workspace:WaitForChild("ACFame_Backup")
local BrushWriter=require(folder:WaitForChild("BrushWriter"))
local ArtistController=require(folder:WaitForChild("ArtistController"))
local PhotoPainter=require(folder:WaitForChild("PhotoPainter"))
while player:GetAttribute("GameAccessAllowed")~=true do player:GetAttributeChangedSignal("GameAccessAllowed"):Wait() end
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
local activeCard=nil
local history={}
local pendingDisplays={}
local archiving=false
local function idleBoards()
	root:ClearAllChildren() championRoot:ClearAllChildren()
	label(root,"Your name belongs here.",UDim2.fromScale(.12,.38),UDim2.fromScale(.76,.18),Color3.fromRGB(224,211,244))
	label(root,"Names. Portraits. Memories.",UDim2.fromScale(.2,.61),UDim2.fromScale(.6,.055),Color3.fromRGB(151,133,179))
	label(championRoot,"HALL OF FAME",UDim2.fromScale(.16,.4),UDim2.fromScale(.68,.12),gold)
end
local function startWriting(e)
	ui:setCurrent(e)
	displayVersion+=1 local version=displayVersion
	if #history==0 then root:ClearAllChildren() end
	activeCard=make("Frame",root,{Name="ActiveWriting",BackgroundTransparency=1,Size=UDim2.fromOffset(1400,600)})
	local card=activeCard
	make("UIScale",card,{Scale=1})
	portraitPainting=nil
	local isPhoto=e.kind=="necklace" or e.kind=="donut"
	local isBig=e.kind=="donut"
	local color=isBig and pink or cyan
	if isPhoto then
		portraitPainting=PhotoPainter.new(card,e,{x=isBig and .40 or .42,y=.32,w=isBig and .20 or .16,h=isBig and .4667 or .3733},6)
		if isBig then make("UIStroke",portraitPainting.holder,{Thickness=7,Color=pink}) end
	end
	writing=BrushWriter.new(card,e.name,{x=.07,y=isPhoto and .80 or .46,w=.86,h=isPhoto and .12 or .24},Color3.fromRGB(243,230,255),5.5)
	local line=make("Frame",card,{BackgroundColor3=color,BorderSizePixel=0,Position=UDim2.fromScale(.12,isPhoto and .94 or .74),Size=UDim2.fromScale(0,.008)})
	Tween:Create(line,TweenInfo.new(.7,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0,false,isPhoto and 11.5 or 5.5),{Size=UDim2.fromScale(.76,.008)}):Play()
	if e.kind=="follow" then label(card,"Following",UDim2.fromScale(.2,.79),UDim2.fromScale(.6,.12),Color3.fromRGB(15,146,143)) end
	if e.kind=="rose" then label(card,"Thanks for the Rose!",UDim2.fromScale(.2,.82),UDim2.fromScale(.6,.08),pink) end
end

local function archiveWriting()
	if not activeCard or archiving then return end
	archiving=true
	local version=displayVersion
	local card=activeCard
	card.Name="CompletedWriting"
	table.insert(history,1,card)
	if #history>3 then table.remove(history):Destroy() end
	for i,item in ipairs(history) do
		Tween:Create(item,TweenInfo.new(.65,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.fromScale(.04+(i-1)*.32,.015)}):Play()
		Tween:Create(item.UIScale,TweenInfo.new(.65,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Scale=.28}):Play()
	end
	writing=nil portraitPainting=nil
	task.delay(.65,function()
		if version~=displayVersion then return end
		activeCard=nil archiving=false
		if #pendingDisplays>0 then startWriting(table.remove(pendingDisplays,1)) end
	end)
end
local function show(e)
	if activeCard or archiving then
		if #pendingDisplays<150 then table.insert(pendingDisplays,e) end
	else startWriting(e) end
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
	label(championRoot,"Heart 100 · Replaced by the next Top Supporter",UDim2.fromScale(.1,.9),UDim2.fromScale(.8,.07),gold)
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
		ui.hint.Text="Leave your name on the wall."
		displayVersion+=1 cameraVersion+=1 wings={} writing=nil portraitPainting=nil championPainting=nil
		activeCard=nil archiving=false history={} pendingDisplays={}
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
	if writing and writing.done and (not portraitPainting or portraitPainting.done) then archiveWriting() uv=nil lift=nil end
	painter:step(dt,uv,lift)
end)
idleBoards()
folder.Demo:FireServer("sync")
