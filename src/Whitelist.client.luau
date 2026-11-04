-- A denied or pending account cannot reach any game controls.
local Players=game:GetService("Players")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local gui=Instance.new("ScreenGui")
gui.Name="WhitelistEliteUI"gui.IgnoreGuiInset=true gui.ScreenInsets=Enum.ScreenInsets.None
gui.DisplayOrder=2147483647 gui.ResetOnSpawn=false gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local TweenService=game:GetService("TweenService")
local function corner(object,radius)
 local item=Instance.new("UICorner")
 item.CornerRadius=UDim.new(0,radius)item.Parent=object
end
local function stroke(object,color,transparency,thickness)
 local item=Instance.new("UIStroke")
 item.Color=color item.Transparency=transparency item.Thickness=thickness item.Parent=object
 return item
end
local cover=Instance.new("TextButton")
cover.Name="AccessLocked"cover.Size=UDim2.fromScale(1,1)
cover.BackgroundColor3=Color3.fromRGB(6,7,10)cover.BackgroundTransparency=.4
cover.BorderSizePixel=0 cover.Text=""cover.AutoButtonColor=false cover.Active=true cover.Modal=true cover.Parent=gui
local card=Instance.new("Frame")
card.Name="AccessCard"card.Size=UDim2.fromOffset(322,204)
card.AnchorPoint=Vector2.new(.5,.5)card.Position=UDim2.fromScale(.5,.5)
card.BackgroundColor3=Color3.fromRGB(31,21,24)card.BorderSizePixel=0 card.Parent=cover
corner(card,18)stroke(card,Color3.fromRGB(239,83,80),.5,1.5)
local gradient=Instance.new("UIGradient")
gradient.Color=ColorSequence.new(Color3.fromRGB(43,28,33),Color3.fromRGB(31,21,24))
gradient.Rotation=90 gradient.Parent=card
local cardScale=Instance.new("UIScale")
cardScale.Scale=.88 cardScale.Parent=card
TweenService:Create(cardScale,TweenInfo.new(.38,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
local ring=Instance.new("Frame")
ring.Name="AvatarRing"ring.Size=UDim2.fromOffset(88,88)
ring.AnchorPoint=Vector2.new(.5,0)ring.Position=UDim2.new(.5,0,0,26)
ring.BackgroundTransparency=1 ring.Parent=card
corner(ring,999)stroke(ring,Color3.fromRGB(42,46,58),.15,3)
local arc=Instance.new("Frame")
arc.Size=UDim2.fromScale(1,1)arc.BackgroundTransparency=1 arc.Parent=ring
corner(arc,999)
local arcStroke=stroke(arc,Color3.fromRGB(239,83,80),0,3)
local arcGradient=Instance.new("UIGradient")
arcGradient.Transparency=NumberSequence.new({
 NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.16,.05),
 NumberSequenceKeypoint.new(.42,1),NumberSequenceKeypoint.new(1,1)})
arcGradient.Parent=arcStroke
local holder=Instance.new("Frame")
holder.Size=UDim2.fromOffset(72,72)holder.AnchorPoint=Vector2.new(.5,.5)
holder.Position=UDim2.fromScale(.5,.5)holder.BackgroundColor3=Color3.fromRGB(14,15,20)
holder.BorderSizePixel=0 holder.ClipsDescendants=true holder.Parent=ring
corner(holder,999)stroke(holder,Color3.fromRGB(42,46,58),0,1.5)
local avatar=Instance.new("ImageLabel")
avatar.Name="Avatar"avatar.Size=UDim2.fromScale(1,1)avatar.BackgroundTransparency=1
avatar.Image="rbxasset://textures/ui/GuiImagePlaceholder.png"
avatar.ScaleType=Enum.ScaleType.Crop avatar.Parent=holder
task.spawn(function()
 local ok,url=pcall(function()
  return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420)
 end)
 if ok and avatar.Parent then avatar.Image=url end
end)
local badge=Instance.new("Frame")
badge.Size=UDim2.fromOffset(24,24)badge.AnchorPoint=Vector2.new(.5,.5)
badge.Position=UDim2.fromScale(.85,.85)badge.BackgroundColor3=Color3.fromRGB(239,83,80)
badge.BorderSizePixel=0 badge.ZIndex=5 badge.Parent=ring
corner(badge,999)stroke(badge,Color3.fromRGB(21,23,31),0,3)
local dot=Instance.new("Frame")
dot.Size=UDim2.fromOffset(9,9)dot.AnchorPoint=Vector2.new(.5,.5)
dot.Position=UDim2.fromScale(.5,.5)dot.BackgroundColor3=Color3.new(1,1,1)
dot.BorderSizePixel=0 dot.ZIndex=6 dot.Parent=badge corner(dot,999)
local statusLabel=Instance.new("TextLabel")
statusLabel.Name="AccessStatus"statusLabel.AnchorPoint=Vector2.new(.5,0)
statusLabel.Position=UDim2.new(.5,0,0,125)statusLabel.Size=UDim2.new(1,-44,0,26)
statusLabel.BackgroundTransparency=1 statusLabel.Text="ACCESS DENIED"
statusLabel.TextColor3=Color3.fromRGB(239,83,80)statusLabel.Font=Enum.Font.GothamBlack
statusLabel.TextSize=22 statusLabel.Parent=card
local label=Instance.new("TextLabel")
label.Name="StoreAddress"label.AnchorPoint=Vector2.new(.5,0)label.Position=UDim2.new(.5,0,0,158)
label.Size=UDim2.new(1,-44,0,24)label.BackgroundTransparency=1 label.Text="aclassstore.com"
label.TextColor3=Color3.fromRGB(242,210,212)label.Font=Enum.Font.GothamBold label.TextSize=18 label.Parent=card
local hidden={}local watched={}local blocked=true
local function suppress(other)
 if other==gui or not other:IsA("ScreenGui")then return end
 if not watched[other]then
  watched[other]=other:GetPropertyChangedSignal("Enabled"):Connect(function()
   if blocked and other.Enabled then other.Enabled=false end
  end)
 end
 if blocked then
  if hidden[other]==nil then hidden[other]=other.Enabled end
  other.Enabled=false
 end
end
local function update()
 blocked=player:GetAttribute("GameAccessAllowed")~=true
 _G.WhitelistDone=not blocked
 local status=player:GetAttribute("GameAccessStatus")
 statusLabel.Text=(status==nil or status=="Pending") and "VERIFYING ACCESS" or status=="Expired" and "ACCESS EXPIRED" or status=="Error" and "CHECK UNAVAILABLE" or "ACCESS DENIED"
 label.Text=status=="Expired" and "Renew at aclassstore.com" or status=="Error" and "Please retry · aclassstore.com" or "aclassstore.com"
 label.TextSize=status=="Error" and 13 or status=="Expired" and 16 or 18
 gui.Enabled=blocked
 if blocked then
  for _,other in playerGui:GetDescendants()do suppress(other)end
  CAS:BindActionAtPriority("WhitelistBlockInput",function()return Enum.ContextActionResult.Sink end,false,10000,
   Enum.UserInputType.Keyboard,Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseWheel)
 else
  CAS:UnbindAction("WhitelistBlockInput")
  for other,enabled in hidden do if other.Parent then other.Enabled=enabled end end
  table.clear(hidden)
  _G.WhitelistDone=true
 end
end
playerGui.DescendantAdded:Connect(suppress)
player:GetAttributeChangedSignal("GameAccessAllowed"):Connect(update)
player:GetAttributeChangedSignal("GameAccessStatus"):Connect(update)
gui.Parent=playerGui
update()
script.Destroying:Connect(function()
 CAS:UnbindAction("WhitelistBlockInput")
 for _,connection in watched do connection:Disconnect()end
 for other,enabled in hidden do if other.Parent then other.Enabled=enabled end end
 gui:Destroy()
end)

