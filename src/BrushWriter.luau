-- Original vector handwriting. Each stroke is painted progressively, including pen lifts.
local Brush={}
local glyphs={
 A=".12,.84 .62,.08 .83,.82|.3,.57 .73,.55",
 B=".2,.83 .34,.13|.34,.13 .71,.16 .73,.34 .31,.46 .72,.51 .74,.71 .54,.82 .2,.83",
 C=".81,.22 .59,.11 .28,.27 .18,.58 .34,.81 .7,.75",
 D=".2,.83 .35,.13|.35,.13 .68,.2 .8,.49 .61,.77 .2,.83",
 E=".79,.14 .34,.14 .2,.82 .73,.8|.28,.47 .67,.45",
 F=".2,.84 .34,.14 .8,.13|.28,.47 .69,.45",
 G=".81,.22 .57,.13 .28,.28 .19,.61 .42,.82 .73,.7 .75,.49 .48,.5",
 H=".3,.13 .16,.83|.82,.13 .68,.83|.23,.48 .75,.46",
 I=".3,.15 .76,.13|.54,.14 .4,.81|.2,.83 .68,.81",
 J=".36,.15 .84,.13|.68,.14 .56,.7 .39,.85 .18,.7",
 K=".31,.13 .17,.84|.85,.13 .25,.51 .69,.82",
 L=".34,.13 .19,.83 .77,.8",
 M=".13,.84 .29,.13 .48,.63 .84,.12 .71,.84",
 N=".16,.84 .3,.13 .65,.81 .81,.12",
 O=".62,.12 .32,.21 .18,.53 .3,.8 .61,.8 .79,.48 .74,.23 .62,.12",
 P=".18,.84 .34,.14 .67,.16 .78,.33 .58,.48 .28,.48",
 Q=".62,.12 .32,.21 .18,.53 .3,.8 .61,.8 .79,.48 .74,.23 .62,.12|.5,.64 .8,.94",
 R=".18,.84 .34,.14 .67,.16 .78,.33 .58,.48 .28,.48|.47,.48 .74,.83",
 S=".79,.22 .56,.11 .3,.24 .32,.42 .65,.57 .66,.75 .39,.84 .17,.73",
 T=".16,.16 .88,.12|.55,.14 .41,.84",
 U=".31,.13 .2,.65 .32,.83 .59,.78 .81,.13",
 V=".2,.13 .34,.84 .83,.13",
 W=".12,.13 .2,.83 .48,.34 .52,.83 .88,.12",
 X=".22,.14 .74,.83|.84,.13 .15,.83",
 Y=".19,.13 .46,.49 .85,.13|.46,.49 .38,.84",
 Z=".24,.15 .83,.13 .16,.83 .76,.81",
 a=".72,.4 .51,.29 .23,.43 .2,.7 .36,.83 .65,.66 .72,.36|.71,.35 .64,.78 .82,.81",
 b=".25,.79 .37,.08 .23,.49 .43,.32 .71,.36 .77,.58 .57,.8 .28,.79",
 c=".76,.39 .56,.3 .29,.4 .19,.64 .35,.8 .68,.76",
 d=".73,.39 .53,.3 .27,.4 .2,.64 .34,.8 .62,.65|.85,.06 .67,.78 .84,.81",
 e=".22,.55 .66,.51 .71,.38 .49,.3 .24,.44 .2,.68 .43,.82 .74,.72",
 f=".26,1.06 .42,.28 .6,.06 .77,.12|.16,.45 .74,.4",
 g=".73,.38 .52,.3 .26,.42 .22,.65 .37,.8 .66,.64|.75,.33 .59,.98 .37,1.13 .16,1.02",
 h=".2,.82 .37,.06|.27,.55 .53,.32 .7,.42 .62,.79 .82,.8",
 i=".39,.36 .3,.74 .42,.82 .59,.74|.44,.15 .45,.16",
 j=".54,.36 .4,.97 .23,1.1 .07,1.02|.6,.15 .61,.16",
 k=".22,.82 .36,.07|.76,.31 .28,.6|.44,.52 .59,.79 .78,.8",
 l=".3,.7 .58,.08 .37,.16 .22,.66 .34,.81 .57,.74",
 m=".16,.81 .25,.34|.21,.55 .4,.32 .51,.43 .43,.8|.49,.53 .68,.33 .8,.45 .72,.79 .89,.8",
 n=".2,.8 .3,.34|.26,.54 .55,.32 .73,.43 .65,.78 .83,.79",
 o=".65,.32 .36,.33 .2,.54 .27,.77 .54,.8 .73,.6 .7,.39 .55,.33",
 p=".17,1.12 .34,.33|.3,.49 .55,.32 .77,.43 .71,.67 .49,.81 .27,.72",
 q=".73,.4 .53,.3 .26,.43 .23,.68 .4,.8 .69,.59|.78,.33 .59,1.08 .79,.99",
 r=".22,.82 .32,.33|.28,.52 .54,.31 .74,.4",
 s=".77,.38 .54,.29 .31,.37 .32,.52 .61,.64 .62,.77 .39,.84 .19,.75",
 t=".56,.13 .38,.68 .44,.81 .69,.72|.2,.4 .81,.36",
 u=".29,.35 .2,.68 .32,.81 .61,.6 .71,.33|.69,.38 .62,.77 .81,.8",
 v=".19,.35 .32,.8 .52,.72 .79,.33",
 w=".16,.35 .22,.78 .42,.62 .51,.35 .48,.75 .66,.77 .86,.32",
 x=".23,.36 .65,.8|.77,.33 .17,.82",
 y=".26,.35 .2,.66 .34,.79 .66,.57|.77,.33 .59,.95 .36,1.12 .16,1.03",
 z=".24,.38 .74,.34 .23,.8 .74,.76",
 ["0"]=".67,.14 .36,.15 .21,.48 .27,.77 .54,.83 .76,.5 .72,.22 .55,.13",
 ["1"]=".31,.3 .57,.13 .42,.81|.23,.82 .67,.8",
 ["2"]=".23,.3 .43,.13 .69,.2 .7,.39 .24,.79 .73,.8",
 ["3"]=".28,.18 .69,.16 .66,.4 .4,.46 .7,.53 .64,.77 .34,.83 .18,.71",
 ["4"]=".62,.12 .2,.59 .82,.57|.71,.13 .56,.84",
 ["5"]=".8,.15 .33,.15 .26,.46 .57,.43 .72,.57 .6,.79 .34,.84 .18,.73",
 ["6"]=".74,.15 .43,.2 .23,.5 .28,.77 .54,.83 .73,.64 .61,.46 .3,.53",
 ["7"]=".22,.18 .82,.15 .36,.83",
 ["8"]=".48,.46 .24,.3 .42,.12 .68,.16 .71,.32 .46,.47 .24,.64 .34,.82 .63,.8 .72,.61 .48,.46",
 ["9"]=".68,.46 .4,.5 .23,.34 .37,.15 .65,.15 .76,.34 .59,.73 .31,.83",
 ["_"]=".12,.96 .87,.96",
 ["."]=".43,.8 .45,.82",
 ["-"]=".23,.54 .75,.51",
 ["@"]=".62,.41 .41,.34 .29,.53 .36,.68 .57,.58 .65,.33 .59,.65 .78,.64 .88,.42 .72,.15 .4,.1 .12,.32 .09,.68 .36,.91 .78,.84",
}
local function catmull(a,b,c,d,t)
	return (b*2+(c-a)*t+(a*2-b*5+c*4-d)*t*t+(-a+b*3-c*3+d)*t*t*t)*.5
end
function Brush.new(parent,text,rect,ink,seconds)
	local holder=Instance.new("Frame") holder.Name="BrushLettering" holder.BackgroundTransparency=1
	holder.Position=UDim2.fromScale(rect.x,rect.y) holder.Size=UDim2.fromScale(rect.w,rect.h) holder.Parent=parent
	local self=setmetatable({holder=holder,rect=rect,seconds=seconds,elapsed=0,index=0,commands={},ink=ink,done=false}, {__index=Brush})
	local chars={} local supported=true
	for first,last in utf8.graphemes(text) do
		local ch=text:sub(first,last)
		if not glyphs[ch:lower()] and ch~=" " then supported=false end
		table.insert(chars,ch)
	end
	-- Non-Latin names retain Roblox's Unicode shaping and get a continuous ink reveal.
	if not supported then
		local clip=Instance.new("Frame") clip.Name="UnicodeInkReveal" clip.BackgroundTransparency=1 clip.ClipsDescendants=true clip.Size=UDim2.fromScale(0,1) clip.Parent=holder
		local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.Text=text label.Font=Enum.Font.Kalam label.TextScaled=true label.TextColor3=ink label.Size=UDim2.fromOffset(1400*rect.w,600*rect.h) label.Parent=clip
		self.clip=clip return self
	end
	local width=1400*rect.w local height=600*rect.h
	local cell=math.min(height*.72,width/math.max(#chars,1))
	local ox=(width-cell*#chars)/2
	local sy=math.min(height*.8,cell*1.35)
	local oy=(height-sy)/2
	for ci,ch in ipairs(chars) do
		local data=glyphs[ch] or glyphs[ch:lower()]
		if data then
			for stroke in data:gmatch("[^|]+") do
				local points={}
				for x,y in stroke:gmatch("([%d.]+),([%d.]+)") do table.insert(points,Vector2.new(ox+(ci-1+tonumber(x))*cell,oy+tonumber(y)*sy)) end
				local previous=points[1]
				table.insert(self.commands,{point=previous,lift=true})
				for i=1,#points-1 do
					local a=points[math.max(1,i-1)] local b=points[i] local c=points[i+1] local d=points[math.min(#points,i+2)]
					local steps=math.max(2,math.ceil((c-b).Magnitude/4))
					for j=1,steps do
						local point=catmull(a,b,c,d,j/steps)
						local pressure=.52+.48*math.sin(math.pi*(i-1+j/steps)/(#points-1))
						table.insert(self.commands,{a=previous,point=point,thickness=math.max(1.7,sy*.11*pressure)}) previous=point
					end
				end
			end
		end
	end
	return self
end
function Brush:step(dt)
	if not self.holder.Parent then self.done=true return end
	self.elapsed+=dt
	local progress=math.clamp(self.elapsed/self.seconds,0,1)
	if self.clip then
		self.clip.Size=UDim2.fromScale(progress,1) self.done=progress>=1
		return Vector2.new(self.rect.x+self.rect.w*progress,self.rect.y+self.rect.h*.55),false
	end
	local goal=math.floor(#self.commands*progress)
	for i=self.index+1,goal do
		local c=self.commands[i]
		if not c.lift then
			local delta=c.point-c.a
			local mark=Instance.new("Frame") mark.Name="InkStroke" mark.BorderSizePixel=0 mark.BackgroundColor3=self.ink
			mark.AnchorPoint=Vector2.new(.5,.5) mark.Position=UDim2.fromOffset((c.a.X+c.point.X)/2,(c.a.Y+c.point.Y)/2)
			mark.Size=UDim2.fromOffset(delta.Magnitude+c.thickness*.45,c.thickness) mark.Rotation=math.deg(math.atan2(delta.Y,delta.X))
			mark.Parent=self.holder
			local round=Instance.new("UICorner") round.CornerRadius=UDim.new(1,0) round.Parent=mark
		end
	end
	self.index=goal self.done=progress>=1
	local c=self.commands[math.max(1,goal)]
	if c then return Vector2.new(self.rect.x+c.point.X/1400,self.rect.y+c.point.Y/600),c.lift end
end
return Brush
