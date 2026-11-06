local Http=game:GetService("HttpService")
local f=game.ReplicatedStorage.ACFame
local configCopy=game.ServerScriptService.FameConfig:Clone()
local config=require(configCopy) configCopy:Destroy()
local payloadCopy=f.WritingPayload:Clone() local Payload=require(payloadCopy)
local brushCopy=f.BrushWriter:Clone() local Brush=require(brushCopy)
assert(Payload.read({width=10,height=10,thickness=3,strokes={{{0,0},{11,0}}}})==nil)
local results={}
for _,name in ipairs({"น้ำฝน 🌟","สมชาย ใจดี","中文","日本語","한국어","العربية","हिन्दी","Émilie_123"}) do
	local response=Http:RequestAsync({Url=config.BridgeUrl.."/writing/paths",Method="POST",Headers={["Content-Type"]="application/json",["X-Fame-Key"]=config.BridgeKey,["X-Fame-Session"]=Http:GenerateGUID(false)},Body=Http:JSONEncode({text=name})})
	assert(response.Success,"Writing API failed: "..response.StatusCode)
	local raw=Http:JSONDecode(response.Body) local path=Payload.read(raw)
	assert(path,"Invalid path") assert(not raw.text:find("🌟",1,true))
	local root=Instance.new("Frame")
	local writing=Brush.new(root,raw.text,{x=0,y=0,w=1,h=1},Color3.new(1,1,1),3,path)
	assert(not writing.clip and #writing.commands>0,"Must draw strokes, not reveal text")
	assert(writing:cursor()~=nil)
	writing:step(.5) assert(writing.index>0 and not writing.done)
	writing:step(3) assert(writing.done)
	results[#results+1]={name=raw.text,strokes=#path.strokes,commands=#writing.commands}
	root:Destroy()
end
payloadCopy:Destroy() brushCopy:Destroy()
return results
