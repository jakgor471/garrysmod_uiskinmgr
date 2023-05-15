uiskinmgr = uiskinmgr or {}

local DisallowedFields = {["Author"] = 1, ["Base"] = 1, ["Description"] = 1, ["Name"] = 1, ["PrintName"] = 1}
function uiskinmgr.IsAllowedField(fieldname)
	return DisallowedFields[fieldname] == nil
end

function uiskinmgr.IsExperimental(fieldname)
	local exp, name = string.match(fieldname, "^(_Exp%.)([%w_%.]+)")
	return exp != nil, name
end