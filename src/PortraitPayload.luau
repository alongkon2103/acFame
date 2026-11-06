local Portrait={}
function Portrait.read(raw,allowPixels)
	if not allowPixels or type(raw)~="table" or #raw~=1024 then return nil end
	local pixels=table.create(1024)
	for i=1,1024 do
		local value=raw[i]
		if type(value)~="number" or value~=value or value%1~=0 or value<0 or value>16777215 then return nil end
		pixels[i]=value
	end
	return pixels
end
return Portrait
