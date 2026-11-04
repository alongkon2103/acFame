-- Reveals portrait pixels in alternating brush passes; asset images use clipped strips.
local Photo={}
function Photo.new(parent,e,rect,duration)
	local self=setmetatable({rect=rect,duration=duration,elapsed=0,index=0,cells={},bands={}}, {__index=Photo})
	local holder=Instance.new("Frame") holder.Name="PaintedPortrait" holder.Position=UDim2.fromScale(rect.x,rect.y) holder.Size=UDim2.fromScale(rect.w,rect.h) holder.BackgroundColor3=Color3.fromRGB(218,226,223) holder.BorderSizePixel=0 holder.Parent=parent self.holder=holder
	local pw=1400*rect.w local ph=(rect.canvasHeight or 600)*rect.h
	if e.pixels then
		for pass=0,7 do for col=0,31 do for offset=0,3 do
			local row=pass*4+offset
			local x=pass%2==0 and col or 31-col
			local value=e.pixels[row*32+x+1]
			local p=Instance.new("Frame") p.Name="PaintPixel" p.BorderSizePixel=0 p.Visible=false
			p.Position=UDim2.fromScale(x/32,row/32) p.Size=UDim2.new(1/32,1,1/32,1)
			p.BackgroundColor3=Color3.fromRGB(math.floor(value/65536),math.floor(value/256)%256,value%256) p.Parent=holder self.cells[#self.cells+1]=p
		end end end
	else
		for row=0,31 do
			local clip=Instance.new("Frame") clip.Name="PaintBand" clip.ClipsDescendants=true clip.BackgroundTransparency=1 clip.Position=UDim2.fromOffset(0,row*ph/32) clip.Size=UDim2.fromOffset(0,ph/32+1) clip.Parent=holder
			local content
			if e.avatarAssetId then
				content=Instance.new("ImageLabel") content.Image="rbxassetid://"..e.avatarAssetId content.ScaleType=Enum.ScaleType.Crop
			else
				content=Instance.new("TextLabel") content.Text="@" content.Font=Enum.Font.Kalam content.TextScaled=true content.TextColor3=Color3.fromRGB(30,155,145)
			end
			content.BackgroundTransparency=1 content.Size=UDim2.fromOffset(pw,ph) content.Parent=clip
			self.bands[row+1]={clip=clip,content=content}
		end
	end
	return self
end
function Photo:step(dt)
	if not self.holder.Parent then self.done=true return end
	self.elapsed+=dt local p=math.clamp(self.elapsed/self.duration,0,1)
	local count=math.floor(p*1024)
	if #self.cells>0 then
		for i=self.index+1,count do self.cells[i].Visible=true end
	else
		local pw=1400*self.rect.w local ph=(self.rect.canvasHeight or 600)*self.rect.h
		for row=0,31 do
			local pass=math.floor(row/4)
			local amount=math.clamp(p*8-pass,0,1) local band=self.bands[row+1]
			local start=pass%2==0 and 0 or pw*(1-amount)
			band.clip.Position=UDim2.fromOffset(start,row*ph/32)
			band.clip.Size=UDim2.fromOffset(pw*amount,ph/32+1)
			band.content.Position=UDim2.fromOffset(-start,-row*ph/32)
		end
	end
	self.index=count self.done=p>=1
	local i=math.min(count,1023) local pass=math.floor(i/128) local col=math.floor(i%128/4) local row=pass*4+1.5 local x=pass%2==0 and col or 31-col
	return Vector2.new(self.rect.x+self.rect.w*(x+.5)/32,self.rect.y+self.rect.h*(row+.5)/32)
end
return Photo
