local Payload={}
function Payload.read(raw)
	if type(raw)~="table" or type(raw.width)~="number" or type(raw.height)~="number" then return end
	local w,h=raw.width,raw.height
	if w%1~=0 or h%1~=0 or w<1 or h<1 or w>1028 or h>132 then return end
	if type(raw.strokes)~="table" or #raw.strokes<1 or #raw.strokes>8000 or raw.thickness~=3 then return end
	local count=0
	for _,stroke in ipairs(raw.strokes) do
		if type(stroke)~="table" or #stroke<2 then return end
		for _,p in ipairs(stroke) do
			count+=1 if count>16000 or type(p)~="table" or #p~=2 then return end
			local x,y=p[1],p[2]
			if type(x)~="number" or type(y)~="number" or x%1~=0 or y%1~=0 or x<0 or y<0 or x>=w or y>=h then return end
		end
	end
	return {width=w,height=h,thickness=3,strokes=raw.strokes}
end
return Payload
