local Access={changed=Instance.new("BindableEvent")}
local records=setmetatable({},{__mode="k"})

function Access.allowed(player)
	local record=records[player]
	return record~=nil and record.allowed and (record.expires==0 or record.expires>os.time())
end

function Access.set(player,allowed,status,expires)
	local valid=type(expires)=="number" and expires==expires and expires>=0 and expires<math.huge and expires==math.floor(expires)
	local granted=allowed==true and valid and (expires==0 or expires>os.time())
	if not granted and status~="Pending" and status~="Expired" and status~="Error" then status="NotAllowed" end
	if granted and status~="Premium" then status="Regular" end
	records[player]={allowed=granted,expires=valid and expires or 0}
	player:SetAttribute("GameAccessAllowed",granted)
	player:SetAttribute("GameAccessStatus",status)
	player:SetAttribute("WhitelistExpire",valid and expires or 0)
	Access.changed:Fire(player)
end

function Access.remove(player) records[player]=nil end
return Access
