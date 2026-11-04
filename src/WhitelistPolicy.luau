local Policy={}

function Policy.evaluate(data,now)
	if type(data)~="table" then return false,false,0,"Error" end
	if data.allowed~=true then return false,false,0,data.reason=="expired" and "Expired" or "NotAllowed" end
	if data.source~="user_whitelist_access" or type(now)~="number" or now~=now then return false,false,0,"Error" end
	local premium=data.is_premium==true
	local status=premium and "Premium" or "Regular"
	if data.duration_type=="permanent" and data.expires_at==nil then return true,premium,0,status end
	if data.duration_type~="days" or type(data.expires_at)~="string" then return false,false,0,"Error" end
	local ok,date=pcall(DateTime.fromIsoDate,data.expires_at)
	if not ok or not date then return false,false,0,"Error" end
	local expires=date.UnixTimestamp
	if expires<=now then return false,false,expires,"Expired" end
	return true,premium,expires,status
end

return Policy
