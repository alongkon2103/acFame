local f=game.ReplicatedStorage.ACFame
local brushCopy=f.BrushWriter:Clone() local Brush=require(brushCopy)
local artistCopy=f.ArtistController:Clone() local Artist=require(artistCopy)
local holder=Instance.new("Frame")
local writer=Brush.new(holder,"Alice",{x=.07,y=.46,w=.86,h=.24},Color3.new(1,1,1),3)
local start,lift=writer:cursor()
assert(start and lift and writer.index==0,"First cursor must be available before ink")
assert(#writer.holder:GetChildren()==0,"Priming must not reveal ink")
local canvas=Instance.new("Part") canvas.Size=Vector3.new(100,40,1)
local root=Instance.new("Part") root.Parent=workspace
local target=Instance.new("Part")
local function part() return Instance.new("Part") end
local model=Instance.new("Model")
local actor=setmetatable({enabled=true,saved={},root=root,model=model,tip=Vector3.new(-100,0,0),x=-100,
 map={Canvas=canvas},target=target,shoulderOffset=Vector3.zero,reach=2,floorOffset=3,
 lift={LiftBase=part(),LiftDeck=part(),LiftColumn=part()},pieces={},joints={}}, {__index=Artist})
actor:step(1/60,start,true)
local expected=canvas.CFrame:PointToWorldSpace(Vector3.new((start.X-.5)*canvas.Size.X,(.5-start.Y)*canvas.Size.Y,canvas.Size.Z/2+.06))+Vector3.new(0,0,.22)
assert((actor.tip-expected).Magnitude<.001,"Brush must reach first point before ink")
writer:step(.05)
local uv=writer:cursor() actor:step(1/60,uv,false)
expected=canvas.CFrame:PointToWorldSpace(Vector3.new((uv.X-.5)*canvas.Size.X,(.5-uv.Y)*canvas.Size.Y,canvas.Size.Z/2+.06))
assert((actor.tip-expected).Magnitude<.001,"Brush must stay on current ink")
for _,p in pairs(actor.lift) do p:Destroy() end
root:Destroy() target:Destroy() canvas:Destroy() holder:Destroy() model:Destroy() brushCopy:Destroy() artistCopy:Destroy()
return "First stroke priming and brush/ink synchronization passed"
