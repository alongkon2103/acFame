local Tween=game:GetService("TweenService")
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local UI={}
UI.__index=UI

local C={paper=Color3.fromRGB(238,233,246),muted=Color3.fromRGB(158,149,176),base=Color3.fromRGB(17,14,26),field=Color3.fromRGB(28,24,40),edge=Color3.fromRGB(63,53,79),cyan=Color3.fromRGB(86,229,208),purple=Color3.fromRGB(139,105,202),gold=Color3.fromRGB(231,194,121),red=Color3.fromRGB(240,134,156)}
local function make(class,parent,props)
	local v=Instance.new(class)
	for k,value in pairs(props) do v[k]=value end
	v.Parent=parent
	return v
end
local function corner(parent,radius) make("UICorner",parent,{CornerRadius=UDim.new(0,radius or 10)}) end
local function stroke(parent,color) return make("UIStroke",parent,{Color=color or C.edge,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
local function text(parent,name,value,size,color,pos,dimensions,bold)
	return make("TextLabel",parent,{Name=name,Text=value,TextSize=size,TextColor3=color or C.paper,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,BackgroundTransparency=1,Position=pos,Size=dimensions,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd})
end
local function button(parent,name,value,pos,size,fill,color)
	local b=make("TextButton",parent,{Name=name,Text=value,TextSize=15,Font=Enum.Font.GothamMedium,TextColor3=color or C.paper,Position=pos,Size=size,BackgroundColor3=fill or C.field,BorderSizePixel=0,AutoButtonColor=false})
	corner(b,8)
	local base=b.BackgroundColor3
	b.MouseEnter:Connect(function() if b.Active then Tween:Create(b,TweenInfo.new(.12),{BackgroundColor3=base:Lerp(Color3.new(1,1,1),.07)}):Play() end end)
	b.MouseLeave:Connect(function() Tween:Create(b,TweenInfo.new(.12),{BackgroundColor3=base}):Play() end)
	return b
end
local function section(parent,name,height,order)
	return make("Frame",parent,{Name=name,Size=UDim2.new(1,0,0,height),LayoutOrder=order,BackgroundTransparency=1})
end

function UI.new(player)
	local self=setmetatable({},UI)
	local old=player.PlayerGui:FindFirstChild("ACFameHUD")
	if old then old:Destroy() end
	self.gui=make("ScreenGui",player.PlayerGui,{Name="ACFameHUD",ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=10,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
	self.chrome=make("Frame",self.gui,{Name="Chrome",Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
	local chrome=self.chrome
	local brand=make("Frame",chrome,{Name="Brand",Position=UDim2.fromOffset(24,20),Size=UDim2.fromOffset(190,48),BackgroundTransparency=1})
	text(brand,"Wordmark","AC  FAME",18,C.paper,UDim2.fromOffset(0,0),UDim2.fromOffset(160,24),true)
	self.statusDot=make("Frame",brand,{Name="StatusDot",Position=UDim2.fromOffset(1,34),Size=UDim2.fromOffset(5,5),BackgroundColor3=C.muted,BorderSizePixel=0}) corner(self.statusDot,3)
	self.status=text(brand,"Status","Ready to create",11,C.muted,UDim2.fromOffset(13,26),UDim2.fromOffset(168,20))
	local actions=make("Frame",chrome,{Name="Actions",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-24,0,22),Size=UDim2.fromOffset(Run:IsStudio() and 212 or 132,42),BackgroundTransparency=1})
	self.connectionToggle=button(actions,"ConnectionToggle","Live setup",UDim2.fromOffset(0,0),UDim2.fromOffset(132,42),C.field)
	self.connectionToggle.Visible=false
	stroke(self.connectionToggle)
	self.demoToggle=button(actions,"DemoToggle","Test",UDim2.fromOffset(140,0),UDim2.fromOffset(72,42),C.base,C.muted)
	self.demoToggle.Visible=Run:IsStudio()
	self.viewButton=button(chrome,"ViewMode","Explore",UDim2.new(0,24,1,-64),UDim2.fromOffset(142,40),C.base,C.paper)
	self.viewButton.Text="Loading scene…" self.viewButton.Active=false self.viewButton.Selectable=false
	stroke(self.viewButton)
	self.hint=text(chrome,"WorkHint","Leave your name on the wall.",12,C.muted,UDim2.new(.5,-210,1,-58),UDim2.fromOffset(420,28))
	self.hint.TextXAlignment=Enum.TextXAlignment.Center

	local panel=make("Frame",chrome,{Name="TikTokConnect",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-24,0,80),Size=UDim2.fromOffset(392,564),BackgroundColor3=C.base,BorderSizePixel=0,Visible=false,ClipsDescendants=true,Active=true})
	self.connectPanel=panel corner(panel,14) stroke(panel)
	local art=make("ImageLabel",panel,{Name="AtelierArt",Image="rbxassetid://123889866400587",Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,140),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Crop,ImageTransparency=.05})
	make("UIGradient",art,{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.62,.1),NumberSequenceKeypoint.new(1,1)})})
	text(panel,"Eyebrow","CREATOR STUDIO",10,C.cyan,UDim2.fromOffset(24,24),UDim2.new(1,-80,0,16),true)
	text(panel,"Title","Your LIVE, in art.",24,C.paper,UDim2.fromOffset(24,48),UDim2.new(1,-48,0,36),true)
	text(panel,"Subtitle","Set up your overlays before going live.",12,C.muted,UDim2.fromOffset(24,88),UDim2.new(1,-48,0,20))
	local close=button(panel,"Close","×",UDim2.new(1,-44,0,12),UDim2.fromOffset(32,32),C.base,C.muted) close.TextSize=22
	local body=make("ScrollingFrame",panel,{Name="Body",Position=UDim2.fromOffset(0,132),Size=UDim2.new(1,0,1,-132),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.purple,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y})
	local bodyPadding=make("UIPadding",body,{PaddingLeft=UDim.new(0,24),PaddingRight=UDim.new(0,24),PaddingBottom=UDim.new(0,24)})
	local bodyLayout=make("UIListLayout",body,{Padding=UDim.new(0,14),SortOrder=Enum.SortOrder.LayoutOrder})
	local channel=section(body,"ChannelSection",84,1)
	text(channel,"Label","TIKTOK CHANNEL",11,C.muted,UDim2.fromOffset(0,0),UDim2.new(1,0,0,18),true)
	local inputWrap=make("Frame",channel,{Name="Input",Position=UDim2.fromOffset(0,26),Size=UDim2.new(1,0,0,52),BackgroundColor3=C.field,BorderSizePixel=0}) corner(inputWrap,8)
	local inputStroke=stroke(inputWrap)
	text(inputWrap,"Prefix","@",20,C.muted,UDim2.fromOffset(14,0),UDim2.fromOffset(24,52))
	self.channelInput=make("TextBox",inputWrap,{Name="ChannelInput",Position=UDim2.fromOffset(42,0),Size=UDim2.new(1,-56,1,0),BackgroundTransparency=1,Text="",PlaceholderText="your_handle",ClearTextOnFocus=false,TextColor3=C.paper,PlaceholderColor3=Color3.fromRGB(114,105,131),Font=Enum.Font.Gotham,TextSize=17,TextXAlignment=Enum.TextXAlignment.Left})
	self.channelInput.Focused:Connect(function() inputStroke.Color=C.cyan end)
	self.channelInput.FocusLost:Connect(function() inputStroke.Color=C.edge end)
	local controls=section(body,"ConnectActions",46,2)
	self.connectButton=button(controls,"Connect","Connect TikTok",UDim2.fromOffset(0,0),UDim2.new(1,0,1,0),C.cyan,C.base)
	self.disconnectButton=button(controls,"Disconnect","Disconnect",UDim2.new(1,-96,0,0),UDim2.fromOffset(96,46),C.field,C.red)
	self.disconnectButton.Visible=false
	local message=section(body,"ConnectionStatus",40,3)
	self.connectionMessage=text(message,"ConnectionMessage","Go LIVE on TikTok, then connect here.",14,C.muted,UDim2.fromOffset(0,0),UDim2.new(1,0,1,0))
	self.connectionMessage.TextTruncate=Enum.TextTruncate.None self.connectionMessage.TextWrapped=true self.connectionMessage.TextYAlignment=Enum.TextYAlignment.Top
	self.overlayPanel=section(body,"OverlayPanel",228,4)
	make("Frame",self.overlayPanel,{Name="Divider",Size=UDim2.new(1,0,0,1),BackgroundColor3=C.edge,BorderSizePixel=0})
	text(self.overlayPanel,"Title","STREAM OVERLAYS",11,C.muted,UDim2.fromOffset(0,12),UDim2.new(1,0,0,20),true)
	local function overlayRow(name,title,dimensions,y)
		text(self.overlayPanel,name.."Label",title,14,C.paper,UDim2.fromOffset(0,y),UDim2.new(1,-90,0,20),true)
		local size=text(self.overlayPanel,name.."Size",dimensions,10,C.muted,UDim2.new(1,-90,0,y),UDim2.fromOffset(90,20)) size.TextXAlignment=Enum.TextXAlignment.Right
		local box=make("TextBox",self.overlayPanel,{Name=name=="Profile" and "OverlayLink" or "ActivityLink",Position=UDim2.fromOffset(0,y+24),Size=UDim2.new(1,-80,0,36),BackgroundColor3=C.field,BorderSizePixel=0,Text="",PlaceholderText="Preparing your link…",PlaceholderColor3=C.muted,TextColor3=C.paper,Font=Enum.Font.Code,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ClipsDescendants=true,ClearTextOnFocus=false,TextEditable=false}) corner(box,6)
		local selectButton=button(self.overlayPanel,name=="Profile" and "SelectOverlayLink" or "SelectActivityLink","Select",UDim2.new(1,-72,0,y+24),UDim2.fromOffset(72,36),C.field,C.muted) stroke(selectButton)
		selectButton.Active=false selectButton.Selectable=false
		selectButton.Activated:Connect(function()
			if box.Text=="" then return end
			box:CaptureFocus()
			task.defer(function() box.CursorPosition=#box.Text+1 box.SelectionStart=1 end)
			self.copyHint.Text=Input.TouchEnabled and "Touch and hold the link to copy." or "Selected · press Ctrl+C / Cmd+C to copy."
		end)
		return box,selectButton
	end
	self.overlayLink,self.selectOverlay=overlayRow("Profile","Now Creating","640 × 176",40)
	self.activityLink,self.selectActivity=overlayRow("Activity","Activity Guide","320 × 640",116)
	self.copyHint=text(self.overlayPanel,"CopyHint","Arrange your Browser Sources before going live.",11,C.muted,UDim2.fromOffset(0,192),UDim2.new(1,0,0,28))
	self.copyHint.TextWrapped=true self.copyHint.TextTruncate=Enum.TextTruncate.None self.copyHint.TextYAlignment=Enum.TextYAlignment.Top
	self.buttons=make("Frame",chrome,{Name="DemoPanel",Position=UDim2.fromOffset(24,80),Size=UDim2.fromOffset(264,452),BackgroundColor3=C.base,BorderSizePixel=0,Visible=false,ClipsDescendants=true,Active=true}) corner(self.buttons,14) stroke(self.buttons)
	text(self.buttons,"Eyebrow","STUDIO SANDBOX",10,C.purple,UDim2.fromOffset(20,18),UDim2.fromOffset(200,16),true)
	text(self.buttons,"Title","Try an effect",20,C.paper,UDim2.fromOffset(20,40),UDim2.fromOffset(210,30),true)
	local demoClose=button(self.buttons,"Close","×",UDim2.new(1,-40,0,12),UDim2.fromOffset(28,28),C.base,C.muted) demoClose.TextSize=22
	local demoList=make("ScrollingFrame",self.buttons,{Name="Events",Position=UDim2.fromOffset(12,86),Size=UDim2.new(1,-24,1,-98),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=C.purple,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y})
	make("UIListLayout",demoList,{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
	self.demoButtons={}
	local entries={{"comment","Your name","Comment",C.paper},{"follow","New follower","Name + follow highlight",C.cyan},{"rose","Rose","Thank-you · 1 coin",C.red},{"necklace","Your photo","Necklace · 10 coins",C.purple},{"donut","Featured portrait","Donut · 30 coins",C.red},{"heart","TOP SUPPORTER","Hand Hearts · 100 coins",C.gold}}
	for i,entry in ipairs(entries) do
		local b=button(demoList,entry[1],"",UDim2.new(),UDim2.new(1,0,0,52),C.field) b.LayoutOrder=i
		text(b,"Index",string.format("%02d",i),11,entry[4],UDim2.fromOffset(12,0),UDim2.fromOffset(24,52),true)
		text(b,"Title",entry[2],14,C.paper,UDim2.fromOffset(48,7),UDim2.new(1,-60,0,20),true)
		text(b,"Detail",entry[3],10,C.muted,UDim2.fromOffset(48,28),UDim2.new(1,-60,0,16))
		self.demoButtons[entry[1]]=b
	end
	local function updateChromeVisibility()
		local clear=not panel.Visible and not self.buttons.Visible
		self.hint.Visible=clear and chrome.AbsoluteSize.X>=720 and chrome.AbsoluteSize.Y>=440 and not Input.TouchEnabled
		self.viewButton.Visible=not Input.TouchEnabled or clear
	end
	panel:GetPropertyChangedSignal("Visible"):Connect(updateChromeVisibility)
	self.buttons:GetPropertyChangedSignal("Visible"):Connect(updateChromeVisibility)
	local function showConnect(show)
		if show and not self.canConnect then return end
		self.connectPanel.Visible=show
		if show then self.buttons.Visible=false end
	end
	self.connectionToggle.Activated:Connect(function() showConnect(not panel.Visible) end)
	close.Activated:Connect(function() showConnect(false) end)
	self.demoToggle.Activated:Connect(function() self.buttons.Visible=not self.buttons.Visible if self.buttons.Visible then panel.Visible=false end end)
	demoClose.Activated:Connect(function() self.buttons.Visible=false end)
	local function layout()
		if not self.gui:IsDescendantOf(game) then return end
		local w,h=chrome.AbsoluteSize.X,chrome.AbsoluteSize.Y
		local margin=w<620 and 16 or 24
		local compact=h<700
		local short=h<440
		local connectWidth=w<520 and 112 or 132
		local demoWidth=w<520 and 60 or 72
		brand.Position=UDim2.fromOffset(margin,16)
		actions.Position=UDim2.new(1,-margin,0,18)
		actions.Size=UDim2.fromOffset(Run:IsStudio() and connectWidth+8+demoWidth or connectWidth,42)
		self.connectionToggle.Size=UDim2.fromOffset(connectWidth,42)
		self.demoToggle.Position=UDim2.fromOffset(connectWidth+8,0)
		self.demoToggle.Size=UDim2.fromOffset(demoWidth,42)
		self.status.Size=UDim2.fromOffset(w<620 and 110 or 168,20)
		panel.Position=UDim2.new(1,-margin,0,76)
		panel.Size=UDim2.fromOffset(math.max(220,math.min(392,w-2*margin)),math.min(564,math.max(150,h-92)))
		local headerHeight=short and 80 or (compact and 112 or 132)
		panel.Eyebrow.Position=UDim2.fromOffset(24,short and 12 or 24)
		panel.Title.Position=UDim2.fromOffset(24,short and 32 or 48)
		panel.Subtitle.Visible=not short
		art.Size=UDim2.new(1,0,0,short and 100 or 140)
		body.Position=UDim2.fromOffset(0,headerHeight) body.Size=UDim2.new(1,0,1,-headerHeight)
		bodyLayout.Padding=UDim.new(0,compact and 10 or 14) bodyPadding.PaddingBottom=UDim.new(0,compact and 16 or 24)
		channel.Size=UDim2.new(1,0,0,compact and 76 or 84)
		message.Size=UDim2.new(1,0,0,compact and 36 or 40)
		self.overlayPanel.Size=UDim2.new(1,0,0,228)
		self.buttons.Position=UDim2.fromOffset(margin,76)
		self.buttons.Size=UDim2.fromOffset(math.max(220,math.min(264,w-2*margin)),math.min(452,math.max(150,h-92)))
		self.viewButton.Position=Input.TouchEnabled and UDim2.new(.5,-71,1,-56) or UDim2.new(0,margin,1,-56)
		updateChromeVisibility()
	end
	chrome:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	return self
end

function UI:setPermission(allowed)
	self.canConnect=allowed
	self.connectionToggle.Visible=allowed
	if not allowed then self.connectPanel.Visible=false end
end
function UI:setConnection(state,channel)
	local busy=state=="CONNECTING"
	local connected=state=="LIVE"
	local cancel=busy or connected or state=="RETRYING"
	local colors={LIVE=C.cyan,CONNECTING=C.gold,RETRYING=C.gold,ERROR=C.red,OFFLINE=C.muted,SETUP_REQUIRED=C.red}
	local short={LIVE="LIVE  ·  @"..(channel or ""),CONNECTING="Connecting",RETRYING="Reconnecting",ERROR="Could not connect",OFFLINE="Channel offline",SETUP_REQUIRED="Setup required"}
	local messages={DISCONNECTED="Go LIVE on TikTok, then connect here.",CONNECTING="Connecting to TikTok. Please wait…",LIVE="Connected. Close this panel when you are ready.",OFFLINE="This channel is offline. Go LIVE and try again.",ERROR="Could not connect. Check the handle and try again.",RETRYING="Connection interrupted. Retrying…",SETUP_REQUIRED="Connection setup is missing. Contact the host."}
	self.status.Text=short[state] or "Ready to create"
	self.status.TextColor3=colors[state] or C.muted self.statusDot.BackgroundColor3=colors[state] or C.muted
	self.connectionMessage.Text=messages[state] or messages.DISCONNECTED
	self.connectionMessage.TextColor3=(state=="ERROR" or state=="SETUP_REQUIRED") and C.red or C.muted
	self.connectButton.Text=busy and "Connecting…" or (connected and "Reconnect" or "Connect TikTok")
	self.connectButton.Active=not busy self.connectButton.Selectable=not busy self.connectButton.TextTransparency=busy and .35 or 0
	self.connectButton.Size=cancel and UDim2.new(1,-108,1,0) or UDim2.fromScale(1,1)
	self.disconnectButton.Visible=cancel self.channelInput.TextEditable=not busy
	self.connectionToggle.Text=connected and "Live settings" or "Live setup"
end
function UI:setOverlay(url)
	self.overlayLink.Text=url
	self.activityLink.Text=url:gsub("/overlay%?view=","/overlay/activity?view=",1)
	self.selectOverlay.Active=true self.selectOverlay.Selectable=true self.selectOverlay.TextColor3=C.paper
	self.selectActivity.Active=true self.selectActivity.Selectable=true self.selectActivity.TextColor3=C.paper
	self.copyHint.Text="Copy either Browser Source before connecting TikTok."
end
function UI:setView(locked)
	self.viewButton.Text=locked and "Explore" or "Live camera"
	self.viewButton.Active=true self.viewButton.Selectable=true
end
function UI:setCurrent(event)
	local photo=event.kind=="necklace" or event.kind=="donut" or event.kind=="heart"
	self.hint.Text=(photo and "Painting  ·  " or "Writing  ·  ")..event.name
end
function UI:setCinematic(active) self.chrome.Visible=not active end
return UI
