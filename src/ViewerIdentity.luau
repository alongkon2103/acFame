local Identity={}
local function text(value)
	if type(value)~="string" or not utf8.len(value) then return nil end
	local stop=utf8.offset(value,81)
	return (stop and value:sub(1,stop-1) or value):match("^%s*(.-)%s*$")
end
function Identity.name(raw,filter)
	local tried={}
	for _,key in ipairs({"displayName","nickname","name","uniqueId"}) do
		local candidate=text(raw[key])
		if candidate and candidate~="" and not tried[candidate] then
			tried[candidate]=true
			local ok,result=pcall(filter,candidate)
			if ok and type(result)=="string" and result:match("%S") and not result:find("#",1,true) then return result end
		end
	end
	return "Viewer"
end
function Identity.asset(value)
	local id=tostring(value or "")
	return id:match("^%d+$") or id:match("^rbxassetid://(%d+)$")
end
return Identity
