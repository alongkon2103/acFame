local Http=game:GetService("HttpService")
local Players=game:GetService("Players")
local Config=require(script.Parent.FameConfig)
local Access=require(script.Parent:WaitForChild("AccessControl"))
local Policy=require(script.Parent:WaitForChild("WhitelistPolicy"))
local api=Config.WhitelistUrl or "https://aclassstore.com/api/whitelist/check"
local key=Config.WhitelistKey or ""
local product=Config.WhitelistProductId or ""
local remotes=game.ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name="Remotes" remotes.Parent=game.ReplicatedStorage
local function remote(name)
	local event=remotes:FindFirstChild(name) or Instance.new("RemoteEvent")
	event.Name=name event.Parent=remotes return event
end
local trialResult=remote("FreeTrialResult")
remote("FreeTrialRequest").OnServerEvent:Connect(function(player) trialResult:FireClient(player,"NotAllowed") end)
local saved=setmetatable({},{__mode="k"})
local function applyCharacter(player)
	local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	if not Access.allowed(player) then
		if not saved[humanoid] then saved[humanoid]={humanoid.WalkSpeed,humanoid.JumpPower,humanoid.JumpHeight,humanoid.AutoRotate} end
		humanoid.WalkSpeed=0 humanoid.JumpPower=0 humanoid.JumpHeight=0 humanoid.AutoRotate=false
	elseif saved[humanoid] then
		local original=saved[humanoid] saved[humanoid]=nil
		humanoid.WalkSpeed=original[1] humanoid.JumpPower=original[2] humanoid.JumpHeight=original[3] humanoid.AutoRotate=original[4]
	end
end
local checking={}
local function verify(player)
	if checking[player] or player.Parent~=Players then return end
	checking[player]=true
	local allowed,premium,expires,status=false,false,0,"Error"
	if api:match("^https://") and key~="" and product~="" then
		local ok,response=pcall(function()
			return Http:RequestAsync({Url=api,Method="POST",Headers={["Content-Type"]="application/json",["x-api-key"]=key},Body=Http:JSONEncode({username=player.Name,product_id=product})})
		end)
		if ok and response.Success then
			local decoded,data=pcall(Http.JSONDecode,Http,response.Body)
			if decoded then allowed,premium,expires,status=Policy.evaluate(data,os.time()) end
		end
	end
	checking[player]=nil
	if player.Parent~=Players then return end
	Access.set(player,allowed,status,expires)
	applyCharacter(player)
end
local function setup(player)
	Access.set(player,false,"Pending",0)
	local function characterAdded(character)
		applyCharacter(player)
		character.DescendantAdded:Connect(function(item) if item:IsA("Humanoid") then applyCharacter(player) end end)
	end
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then characterAdded(player.Character) end
	task.spawn(function()
		while player.Parent==Players do verify(player) task.wait(Access.allowed(player) and 300 or 30) end
	end)
end
Players.PlayerAdded:Connect(setup)
for _,player in ipairs(Players:GetPlayers()) do setup(player) end
Access.changed.Event:Connect(applyCharacter)
Players.PlayerRemoving:Connect(function(player) checking[player]=nil Access.remove(player) end)
task.spawn(function()
	while true do
		task.wait(1)
		for _,player in ipairs(Players:GetPlayers()) do
			if player:GetAttribute("GameAccessAllowed")==true and not Access.allowed(player) then Access.set(player,false,"Expired",player:GetAttribute("WhitelistExpire") or 0) end
			if not Access.allowed(player) then applyCharacter(player) end
		end
	end
end)
