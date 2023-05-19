include("includes/uiskinmgr_include.lua")
include("includes/uiskinmgr_rendering.lua")

local MASTER = vgui.GetWorldPanel()
local SkinManager = {}

local XPerimental = {}
XPerimental["Tint.Color"] = {
	default = Color(0,0,0,255),
	apply = function(skin, preset, value, pipeline)
		local entry = {
			operation = "Colorize",
			mode = preset["_Exp.Tint.Mode"] or "Add",
			color = value
		}

		table.insert(pipeline, entry)
	end,
	order = 100
}
XPerimental["Tint.Mode"] = {
	default = "Add",
	extra = {choices = {
		["Add"] = "Add",
		["Multiply"] = "Mul"
	}, text = "Blend mode"}
}
XPerimental["Render.BlurX"] = {
	default = 0,
	apply = function(skin, preset, value, pipeline)
		local entry = {
			operation = "BlurX",
			value = value
		}

		table.insert(pipeline, entry)
	end,
	order = 150
}
XPerimental["Render.BlurY"] = {
	default = 0,
	apply = function(skin, preset, value, pipeline)
		local entry = {
			operation = "BlurY",
			value = value
		}

		table.insert(pipeline, entry)
	end,
	order = 160
}

XPerimental["Render.Opacity"] = {
	default = 1,
	apply = function(skin, preset, value, pipeline)
		local entry = {
			operation = "Opacity",
			value = value
		}

		table.insert(pipeline, entry)
	end,
	order = 200
}


local function serializePreset(preset, name)
	local str = ""

	for k, v in SortedPairs(preset) do
		if istable(v) && v.r && v.g && v.b then
			str = str .. k .. " = " .. tostring(v.r) .. " " .. tostring(v.g) .. " " .. tostring(v.b) .. " " .. tostring(v.a or 255) .. "\r\n"
		elseif isstring(v) then
			str = str .. k .. " = \"" .. v .. "\"\r\n"
		elseif isnumber(v) then
			str = str .. k .. " = " .. v .. "\r\n"
		end
	end

	file.CreateDir("uiskinmgr/presets")
	file.Write("uiskinmgr/presets/" .. name .. ".txt", str)
end

local function deserializePreset(str)
	local preset = {}

	for s in string.gmatch(str, "([^\n]*)\n") do
		local path, value = string.match(s, "([%w_%.]+)%s*=%s*([%w_%s%.\"]+)")

		local param = string.match(path, "([%w_]+)$")
		local quote = string.match(value, "\"([^\"]*)\"")

		if quote then
			preset[path] = quote
		else
			local r, g, b, a = string.match(value, "([%d]+)%s+([%d]+)%s+([%d]+)%s+([%d]+)%s+")

			if r && g && b then
				preset[path] = Color(tonumber(r),tonumber(g),tonumber(b),tonumber(a) or 255)
			elseif r then
				preset[path] = tonumber(r)
			end
		end
	end

	return preset
end

local function deepskin(children, skin)
	for k,v in pairs(children) do
		v:SetSkin(skin)
		if #v:GetChildren() != 0 then deepskin(v:GetChildren(),skin) end
	end
end

local function reloadDefaults(skinmanager)
	for x, y in pairs(derma.SkinList) do
		local stack = util.Stack()
		skinmanager.defaults[x] = {}

		local skintex = y.GwenTexture
		if skintex then
			local tex = skintex:GetTexture("$basetexture")
			skinmanager.defaults[x].GwenTex = tex
		end

		stack:Push({table1 = y, parent = ""})

		while stack:Size() > 0 do
			local tbl = stack:Top().table1
			local parent = stack:Top().parent
			stack:Pop()

			for k, v in pairs(tbl) do
				local ourparent = parent .. k
				if istable(v) then
					if v.r && v.g && v.b then
						skinmanager.defaults[x][ourparent] = {r = v.r, g = v.g, b = v.b, a = v.a or 255}
					else
						stack:Push({table1 = v, parent = ourparent .. "."})
					end
				elseif isstring(v) then
					skinmanager.defaults[x][ourparent] = v
				end
			end
		end

		for k, v in pairs(XPerimental) do
			local def = v.default
			skinmanager.defaults[x]["_Exp."..k] = def
			skinmanager.extra["_Exp."..k] = v.extra
		end
	end
end

local function applyPreset(preset, skin, default)
	if !preset || !skin then return end

	local stack = util.Stack()
	stack:Push({table1 = skin, parent = ""})

	while stack:Size() > 0 do
		local tbl = stack:Top().table1
		local parent = stack:Top().parent
		stack:Pop()

		for k, v in pairs(tbl) do
			local ourlovingparent = parent .. k
			if !uiskinmgr.IsAllowedField(ourlovingparent) then continue end

			if istable(v) then
				if v.r && v.g && v.b then
					local val = preset[ourlovingparent] or default[ourlovingparent]
					tbl[k] = {r = val.r, g = val.g, b = val.b, a = val.a or 255}
				elseif tbl[k] then
					stack:Push({table1 = v, parent = ourlovingparent .. "."})
				end
			elseif isstring(v) then
				local val = preset[ourlovingparent] or default[ourlovingparent]
				tbl[k] = val
			end
		end
	end

	//refresh the texture from disk
	local skintex = skin.GwenTexture
	if skintex && default.GwenTex then
		skintex:SetTexture("$basetexture", default.GwenTex)
	end

	local pipeline = {}
	for k, v in SortedPairsByMemberValue(XPerimental, order) do
		if preset["_Exp."..k] && v.apply then
			v.apply(skin, preset, preset["_Exp."..k], pipeline)
		end
	end

	if skintex then
		local tex = skintex:GetTexture("$basetexture")
		local newtex = uiskinmgr.Render_Pipeline(skintex, pipeline)
		skintex:SetTexture("$basetexture", newtex)
	end
end

local function loadPresetsFromDisk(skinmanager)
	local files = file.Find( "uiskinmgr/presets/*.txt", "DATA" )

	for k, v in ipairs(files) do
		local presetname = string.match(v, "/*([%w_]+).txt$")
		local str = file.Read("uiskinmgr/presets/"..v, "DATA")
		skinmanager.presets[presetname] = deserializePreset(str or "")
	end
end

local function handleSkinChange(panel, newskin)
	local def = panel.SkinManagerTable.defaults[newskin]
	if !def then
		notification.AddLegacy("Couldn't load skin defaults, please reload the map", NOTIFY_ERROR, 5)
		return
	end

	panel.SkinManagerTable.currentSkin = newskin
	cookie.Set("UISkinMgr_DefaultSkin", newskin)

	local curpreset = panel.SkinManagerTable.currentPreset

	applyPreset(panel.SkinManagerTable.presets[curpreset], derma.SkinList[newskin], def)
	deepskin(MASTER:GetChildren(), newskin)
	derma.RefreshSkins()
end

local function handlePresetChange(panel, newpreset, presetdata)
	panel.SkinManagerTable.currentPreset = newpreset
	cookie.Set("UISkinMgr_DefaultPreset", newpreset)

	local curskin = panel.SkinManagerTable.currentSkin or "Default"

	handleSkinChange(panel, curskin)
end

local function handlePresetSave(panel, presetname, presetdata, savetodisk)
	if savetodisk then
		presetname = string.gsub(presetname or "", "[^%w_]", "_")
		presetname = string.lower(presetname)

		if presetname == "" then
			presetname = "unnamed_preset"
		end

		serializePreset(presetdata, presetname)
	end

	panel.SkinManagerTable.presets[presetname] = presetdata
end

local function handlePresetDelete(panel, presetname)
	if !file.Exists("uiskinmgr/presets/"..presetname..".txt", "DATA") then return end

	local str = file.Read("uiskinmgr/presets/"..presetname..".txt", "DATA")
	file.CreateDir("uiskinmgr/presets/trash")
	file.Write("uiskinmgr/presets/trash/"..presetname..".txt",str)
	file.Delete("uiskinmgr/presets/"..presetname..".txt")

	panel.SkinManagerTable.presets[presetname] = nil

	panel.SkinManagerTable.currentPreset = "No override"
	handleSkinChange(panel, panel.SkinManagerTable.currentSkin)
end

local function handleRefreshPresets(panel)
	loadPresetsFromDisk(panel.SkinManagerTable)
end

list.Set( "DesktopWindows", "UISkinManager", {
	title = "UI Skin Manager",
	icon = "icon64/skinmgr.png",
	width		= 960,
	height		= 700,
	onewindow	= true,
	init = function( icon, window )
		local w, h = 800, 600

		if ScrW() < 1000 || ScrH() < 800 then
			w = math.max(ScrW() * 0.6, 520)
			h = math.max(ScrW() * 0.6 * 0.75, 440)
		end

		window:SetTitle( "UI Skin Manager" )
		window:SetSize( w, h )
		window:SetSizable( true )
		window:SetMinWidth( 520 )
		window:SetMinHeight( 440 )
		window:Center()

		local mgr = vgui.Create("uiskinmgr_panel", window)
		mgr:Dock(FILL)
		mgr:DockMargin(4,4,4,4)
		mgr:SetSkinManager(SkinManager)
		mgr.OnSkinChange = handleSkinChange
		mgr.OnPresetChange = handlePresetChange
		mgr.OnPresetSave = handlePresetSave
		mgr.OnPresetDelete = handlePresetDelete
		mgr.OnRefreshPresets = handleRefreshPresets
	end
} )

SkinManager.currentSkin = cookie.GetString("UISkinMgr_DefaultSkin", "Default")

SkinManager.defaults = {}
SkinManager.extra = {}
SkinManager.presets = {["No override"] = {}}
SkinManager.currentPreset = cookie.GetString("UISkinMgr_DefaultPreset", "No override")

loadPresetsFromDisk(SkinManager)

hook.Add("PostGamemodeLoaded", "UISkinMgr_Load", function()
	//build defaults
	reloadDefaults(SkinManager)

	if !derma.SkinList[SkinManager.currentSkin] then
		SkinManager.currentSkin = "Default"
	end

	local curskin = SkinManager.currentSkin

	for k, v in pairs(hook.GetTable()["ForceDermaSkin"] or {}) do
		hook.Remove("ForceDermaSkin", k)
	end

	hook.Add("ForceDermaSkin", "UISkinMgrDermaInjector", function()
		return SkinManager.currentSkin
	end)

	applyPreset(SkinManager.presets[SkinManager.currentPreset], derma.SkinList[curskin], SkinManager.defaults[curskin])
	deepskin(MASTER:GetChildren(), curskin)
	derma.RefreshSkins()
end)

concommand.Add("uiskinmgr_reloaddefaults", function(ply, cmd, args, strargs)
	if !SkinManager then return end

	notification.AddLegacy("Defaults reloaded manually. It may cause some problems!", NOTIFY_GENERIC, 5)
	reloadDefaults(SkinManager)
end)