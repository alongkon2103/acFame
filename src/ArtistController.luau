local Artist={}
function Artist.new(map,player)
	local self=setmetatable({map=map,player=player,enabled=true,generation=0}, {__index=Artist})
	self.target=Instance.new("Part") self.target.Name="PaintGripTarget" self.target.Size=Vector3.one*.1 self.target.Transparency=1 self.target.Anchored=true self.target.CanCollide=false self.target.CanQuery=false self.target.Parent=map
	self.brush=Instance.new("Model") self.brush.Name="CalligraphyBrush" self.brush.Parent=map
	self.lift={}
	for _,name in ipairs({"LiftBase","LiftColumn","LiftDeck"}) do
		local p=Instance.new("Part") p.Name=name p.Anchored=true p.CanCollide=false p.CanQuery=false p.Color=name=="LiftColumn" and Color3.fromRGB(80,105,115) or Color3.fromRGB(30,48,58) p.Material=Enum.Material.Metal p.Parent=self.brush self.lift[name]=p
	end
	self.pieces={}
	for _,spec in ipairs({{"WoodHandle",.14,.32,1.2,Color3.fromRGB(80,37,27)}, {"GoldFerrule",.18,.12,.32,Color3.fromRGB(224,176,81)}, {"InkBristles",.19,0,.2,Color3.fromRGB(22,29,36)}}) do
		local p=Instance.new("Part") p.Name=spec[1] p.Shape=Enum.PartType.Cylinder p.Anchored=true p.CanCollide=false p.CanQuery=false p.Material=spec[1]=="GoldFerrule" and Enum.Material.Metal or Enum.Material.SmoothPlastic p.Color=spec[5] p.Size=Vector3.new(spec[4],spec[2],spec[2]) p.Parent=self.brush
		table.insert(self.pieces,{part=p,start=spec[3],length=spec[4]})
	end
	self.x=-15 self.tip=Vector3.new(-13,5,-.6)
	self.joints={}
	self.added=player.CharacterAdded:Connect(function(character) task.spawn(function() self:bind(character) end) end)
	self.removing=player.CharacterRemoving:Connect(function(character) if self.model==character then self.generation+=1 self:release() self.root=nil end end)
	if player.Character then task.spawn(function() self:bind(player.Character) end) end
	return self
end
function Artist:release()
	if self.ik then self.ik:Destroy() self.ik=nil end
	if self.saved and self.root and self.root.Parent then
		self.root.CFrame=self.saved.cframe self.root.AssemblyLinearVelocity=Vector3.zero self.root.AssemblyAngularVelocity=Vector3.zero self.root.Anchored=self.saved.anchored
		if self.humanoid and self.humanoid.Parent then self.humanoid.AutoRotate=self.saved.autoRotate end
	end
	for joint,value in pairs(self.savedJoints or {}) do if joint.Parent then joint.Transform=value end end
	self.saved=nil self.savedJoints={}
end
function Artist:takeControl()
	if not self.root or not self.root.Parent or not self.humanoid or self.humanoid.Health<=0 then return end
	self.saved={cframe=self.root.CFrame,anchored=self.root.Anchored,autoRotate=self.humanoid.AutoRotate}
	self.savedJoints={} for _,j in pairs(self.joints) do self.savedJoints[j]=j.Transform end
	self.root.Anchored=true self.humanoid.AutoRotate=false
	local hand=self.model:FindFirstChild("RightHand") local upper=self.model:FindFirstChild("RightUpperArm")
	self.hand=hand or self.model:FindFirstChild("Right Arm")
	local lower=self.model:FindFirstChild("RightLowerArm")
	local shoulder=upper or self.model:FindFirstChild("Right Arm")
	self.reach=upper and lower and hand and (upper.Size.Y+lower.Size.Y+hand.Size.Y*.5) or (shoulder and shoulder.Size.Y or 2)
	self.shoulderOffset=shoulder and self.root.CFrame:PointToObjectSpace(shoulder.Position+Vector3.new(0,shoulder.Size.Y*.5,0)) or Vector3.new(1,1,0)
	if hand and upper then
		local ik=Instance.new("IKControl") ik.Name="FamePlayerBrushIK" ik.Type=Enum.IKControlType.Position ik.ChainRoot=upper ik.EndEffector=hand ik.Target=self.target ik.SmoothTime=.01 ik.Weight=1 ik.Parent=self.humanoid self.ik=ik
	end
	self.x=-15 self.y=nil
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={self.model,self.brush,self.target}
	local canvas=self.map.Canvas
	local hit=workspace:Raycast(Vector3.new(canvas.Position.X,3,canvas.Position.Z+6),Vector3.new(0,-12,0),params)
	self.groundY=hit and hit.Position.Y or .06
end
function Artist:bind(character)
	self.generation+=1 local version=self.generation self:release() self.root=nil
	local root=character:WaitForChild("HumanoidRootPart",15)
	local humanoid=character:WaitForChild("Humanoid",15)
	if version~=self.generation or self.player.Character~=character or not root or not humanoid then return end
	if humanoid.RigType==Enum.HumanoidRigType.R15 then character:WaitForChild("RightHand",10) character:WaitForChild("RightUpperArm",10) end
	if version~=self.generation or self.player.Character~=character then return end
	self.model=character self.root=root self.humanoid=humanoid
	self.joints={} for _,v in character:GetDescendants() do if v:IsA("Motor6D") then self.joints[v.Name]=v end end
	-- Ignore hats/accessory bounding boxes when positioning the feet on the platform.
	self.floorOffset=humanoid.HipHeight+root.Size.Y/2
	if humanoid.RigType==Enum.HumanoidRigType.R6 then self.floorOffset+=character:WaitForChild("Left Leg").Size.Y end
	if self.death then self.death:Disconnect() end
	self.death=humanoid.Died:Connect(function() self:release() self.root=nil end)
	if self.enabled then self:takeControl() end
end
function Artist:setEnabled(enabled)
	if self.enabled==enabled then return end
	self.enabled=enabled
	if enabled then self:takeControl() else self:release() end
	for _,v in self.brush:GetChildren() do if v:IsA("BasePart") then v.Transparency=enabled and 0 or 1 end end
end
function Artist:step(dt,uv,lift)
	if not self.enabled or not self.saved or not self.root or not self.root.Parent then return end
	local t=os.clock()
	local canvas=self.map.Canvas
	local target=canvas.CFrame:PointToWorldSpace(Vector3.new(uv and (uv.X-.5)*canvas.Size.X or -13,uv and (.5-uv.Y)*canvas.Size.Y or -5,canvas.Size.Z/2+.06))
	if lift then target+=Vector3.new(0,0,.22) end
	self.tip=self.tip:Lerp(target,math.min(1,dt*35))
	local direction=Vector3.new(.12,-.3,1).Unit
	local grip=self.tip+direction*1.05
	local desired=grip.X-self.shoulderOffset.X-self.reach*.25
	local oldX=self.x self.x+= (desired-self.x)*math.min(1,dt*25)
	local moving=math.abs(self.x-oldX)>dt*.2
	local groundY=self.groundY or .06
	local rootY=uv and math.max(groundY+self.floorOffset,grip.Y-self.shoulderOffset.Y+self.reach*.1) or groundY+self.floorOffset
	self.y=self.y or rootY self.y+=(rootY-self.y)*math.min(1,dt*25)
	local z=grip.Z+self.reach*.55
	self.root.CFrame=CFrame.new(self.x,self.y,z)*CFrame.Angles(0,-.18,0)
	local floorY=self.y-self.floorOffset
	self.lift.LiftBase.Size=Vector3.new(3.4,.25,2.8) self.lift.LiftBase.Position=Vector3.new(self.x,groundY+.125,z)
	self.lift.LiftDeck.Size=Vector3.new(3.4,.3,2.8) self.lift.LiftDeck.Position=Vector3.new(self.x,floorY-.15,z)
	local columnBottom=groundY+.25
	local columnTop=math.max(columnBottom+.05,floorY-.3)
	self.lift.LiftColumn.Size=Vector3.new(.8,columnTop-columnBottom,.8) self.lift.LiftColumn.Position=Vector3.new(self.x,(columnTop+columnBottom)/2,z)
	for _,part in pairs(self.lift) do part.Transparency=floorY-groundY>.35 and 0 or 1 end
	for _,piece in ipairs(self.pieces) do piece.part.Transparency=uv and 0 or 1 end
	if self.ik then self.ik.Weight=uv and 1 or 0 end
	self.target.Position=grip
	if not self.ik then
		local shoulder=self.joints["Right Shoulder"] local torso=self.model:FindFirstChild("Torso")
		if shoulder and torso then
			local at=(torso.CFrame*shoulder.C0).Position
			shoulder.Transform=shoulder.C0:Inverse()*torso.CFrame:ToObjectSpace(CFrame.lookAt(at,self.target.Position)*CFrame.Angles(math.pi/2,0,0))
		end
	end
	local brushDirection=direction local handDistance=1.05
	if self.hand and self.hand.Parent then
		local handPoint=self.hand.Position
		if self.humanoid.RigType==Enum.HumanoidRigType.R6 then handPoint-=self.hand.CFrame.UpVector*self.hand.Size.Y/2 end
		local delta=handPoint-self.tip
		if delta.Magnitude>.1 then brushDirection=delta.Unit handDistance=delta.Magnitude end
	end
	for _,v in ipairs(self.pieces) do
		local length=v.part.Name=="WoodHandle" and math.max(.35,handDistance-v.start+.35) or v.length
		v.part.Size=Vector3.new(length,v.part.Size.Y,v.part.Size.Z)
		local center=self.tip+brushDirection*(v.start+length/2)
		v.part.CFrame=CFrame.lookAt(center,center+brushDirection)*CFrame.Angles(0,math.pi/2,0)
	end
	for _,side in ipairs({"Left","Right"}) do
		local hip=self.joints[side.."Hip"]
		if hip then hip.Transform=CFrame.identity end
	end
	local neck=self.joints.Neck
	if neck then neck.Transform=CFrame.Angles(uv and -.1 or 0,uv and -.15 or math.sin(t*.8)*.07,0) end
end
return Artist
