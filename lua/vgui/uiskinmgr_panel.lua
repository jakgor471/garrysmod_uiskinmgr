include("includes/uiskinmgr_include.lua")

local PANEL = {}

function PANEL:OnRemove()
	if self.SkinManagerTable && self.Edited then
		self.SkinManagerTable.presets["Unsaved preset"] = self.PresetData
	end
end

function PANEL:Init()
	self.Edited = false

	self.SkinList = self:Add("DListView")
	self.SkinList:AddColumn("Skin name", 1)
	self.SkinList:AddColumn("Author", 2)
	self.SkinList:SetMultiSelect(false)

	self.PresetList = self:Add("DListView")
	self.PresetList:AddColumn("Preset name")
	self.PresetList:SetMultiSelect(false)

	self.Lbl = self:Add("DLabel")
	self.Lbl:SetText("Installed skins")
	self.Lbl:SetDark(true)

	self.Lbl2 = self:Add("DLabel")
	self.Lbl2:SetText("Override")
	self.Lbl2:SetDark(true)

	self.Lbl3 = self:Add("DLabel")
	self.Lbl3:SetText("Available properties")
	self.Lbl3:SetDark(true)

	self.Lbl4 = self:Add("DLabel")
	self.Lbl4:SetText("Presets")
	self.Lbl4:SetDark(true)

	self.Properties = self:Add("DScrollPanel")
	self.PropertiesList = self.Properties:Add("DListLayout")
	self.PropertiesList:Dock(FILL)

	self.Properties.Paint = function(fish, w, h)
		local skyn = fish:GetSkin()

		surface.SetDrawColor(skyn.Colours.Properties.Border)
		surface.DrawRect(0, 0, w, h)
	end

	self.AvailProps = self:Add("DPropertySheet")

	self.AllProperties = {}

	local scrollpanel1 = self.AvailProps:Add("DScrollPanel")
	self.PropsListGeneral = scrollpanel1:Add("DListLayout")
	self.PropsListGeneral:Dock(FILL)
	self.AvailProps:AddSheet("General", scrollpanel1, "icon16/application_edit.png")

	scrollpanel1 = self.AvailProps:Add("DScrollPanel")
	self.PropsListExperimental = scrollpanel1:Add("DListLayout")
	self.PropsListExperimental:Dock(FILL)
	self.AvailProps:AddSheet("Experimental", scrollpanel1, "icon16/error.png")

	self.PresetName = self:Add("DTextEntry")

	self.SaveButton = self:Add("DButton")
	self.SaveButton:SetText("Save")
	self.SaveButton.DoClick = function(but)
		self:OnPresetSave(self.PresetName:GetValue(), self.PresetData, true)
		self:UpdatePresets()
		self:OnEdited(false)
	end

	self.DeleteButton = self:Add("DButton")
	self.DeleteButton:SetText("Delete preset")
	self.DeleteButton.DoClick = function(but)
		self:OnPresetDelete(self.SkinManagerTable.currentPreset)
		self:UpdatePresets()
		self:UpdateProperties()
	end
	self.DeleteButton:SetTooltip("Move to uiskinmgr/presets/trash")

	self.RefreshButton = self:Add("DButton")
	self.RefreshButton:SetText("Reload presets")
	self.RefreshButton.DoClick = function(but)
		self:OnRefreshPresets()
		self:UpdatePresets()
		self:UpdateProperties()
	end

	self.ApplyButton = self:Add("DButton")
	self.ApplyButton:SetText("Apply")
	self.ApplyButton.DoClick = function(but)
		if self.Edited then
			self:OnPresetSave("Unsaved preset", self.PresetData, false)
			self:OnPresetChange("Unsaved preset", self.PresetData)
		else
			self:OnPresetChange(self.SkinManagerTable.currentPreset)
		end
		self:UpdatePresets()
	end

	for k, v in SortedPairs(derma.SkinList) do
		local line = self.SkinList:AddLine(v.PrintName or k, v.Author or "N/A")
		line.SkinName = k
		line.OnMousePressed = function(l, kc)
			self:OnSkinChange(l.SkinName or "Default")
			self:UpdateList()
			self:UpdatePresets()
			self:UpdateAvailable()
			self:UpdateProperties()
		end
	end
end

function PANEL:OnEdited(bool)
	if !self.Edited && bool then
		self.EditedImg = self:Add("DImage")
		self.EditedImg:SetImage("icon16/information.png")
		self.EditedText = self:Add("DLabel")
		self.EditedText:SetDark(true)
		self.EditedText:SetText("Make sure to save your changes!")
	elseif self.Edited && !bool then
		self.EditedImg:Remove()
		self.EditedText:Remove()

		self.EditedText = nil
		self.EditedImg = nil
	end
	self.Edited = bool
end
function PANEL:OnSkinChange(newskin) end
function PANEL:OnPresetSave(presetname, presetdata) end
function PANEL:OnPresetChange(presetname, presetdata) end
function PANEL:OnPresetDelete(presetname) end
function PANEL:OnRefreshPresets() end

function PANEL:SetSkinManager(tbl)
	self.SkinManagerTable = tbl
	self:UpdateList()

	self:UpdatePresets()
	self:UpdateAvailable()
	self:LoadPreset(tbl.presets["Unsaved preset"] or tbl.presets[tbl.currentPreset])
	self:UpdateProperties()
end

function PANEL:UpdateList()
	if !self.SkinManagerTable.currentSkin then return end

	self.SkinList:ClearSelection()

	for k, v in ipairs(self.SkinList:GetLines()) do
		if v.SkinName == self.SkinManagerTable.currentSkin then
			v:SetSelected(true)
			break
		end
	end
end

function PANEL:UpdateAvailable()
	if !self.SkinManagerTable.currentSkin then return end
	if !self.SkinManagerTable.defaults[self.SkinManagerTable.currentSkin] then return end

	self.PropsListGeneral:Clear()
	self.PropsListExperimental:Clear()

	for k, v in SortedPairs(self.SkinManagerTable.defaults[self.SkinManagerTable.currentSkin]) do
		local experimental = uiskinmgr.IsExperimental(k)
		local add = experimental || istable(v) && v.r && v.g && v.b || isstring(v)

		if add then
			local avail = vgui.Create("uiskinmgr_control")

			avail:Setup(v, k, false, self.SkinManagerTable.extra[k])
			avail.OnAdded = function(x)
				self.PresetData[k] = self.PresetData[k] or v
				self:UpdateProperties()
				self:OnEdited(true)
			end

			avail:SetAvailable(true)
			avail:SetDisabled(!uiskinmgr.IsAllowedField(k))

			self.AllProperties[self.SkinManagerTable.currentSkin .. k] = avail

			if experimental then
				self.PropsListExperimental:Add(avail)
			else
				self.PropsListGeneral:Add(avail)
			end
		end
	end
end

function PANEL:UpdateProperties()
	self.PropertiesList:Clear()
	for k, v in SortedPairs(self.PresetData) do
		local avail = self.AllProperties[self.SkinManagerTable.currentSkin .. k]

		if IsValid(avail) then
			avail:SetAvailable(false)
		end
		
		local prop = self.PropertiesList:Add("uiskinmgr_control")
		prop:SetDivision(0.4)
		prop:Setup(v, k, true, self.SkinManagerTable.extra[k])
		prop:SetDisabled(!uiskinmgr.IsAllowedField(k))
		prop.OnRemoved = function(x)
			self.PresetData[k] = nil
			//self:UpdateProperties()
			self:OnEdited(true)
			prop:Remove()
			
			if IsValid(avail) then
				avail:SetAvailable(true)
			end
		end
		prop.OnDefault = function(x)
			self.PresetData[k] = (self.SkinManagerTable.defaults[self.SkinManagerTable.currentSkin] or {})[k]
			self:UpdateProperties()
			self:OnEdited(true)
		end

		prop.OnEdited = function(s, anyval)
			self.PresetData[k] = anyval
			self:OnEdited(true)
		end
	end
end

function PANEL:UpdatePresets()
	self.PresetList:Clear()

	for k, v in SortedPairs(self.SkinManagerTable.presets or {}) do
		local line = self.PresetList:AddLine(k)
		line.OnMousePressed = function(l, kc)
			self:LoadPreset(self.SkinManagerTable.presets[k])
			self:OnPresetChange(k)
			self:UpdateAvailable()
			self:UpdateProperties()
			self.PresetName:SetValue(k)
			self:OnEdited(false)
			self:UpdatePresets()
		end
	end

	self.PresetList:ClearSelection()

	for k, v in ipairs(self.PresetList:GetLines()) do
		if v:GetValue(1) == self.SkinManagerTable.currentPreset then
			v:SetSelected(true)
			break
		end
	end
end

function PANEL:LoadPreset(preset)
	self.PresetData = {}

	for k, v in pairs(preset or {}) do
		self.PresetData[k] = v
	end
end

function PANEL:PerformLayout(w, h)
	local defbuttall = 20

	self.Lbl:SetPos(6,4)
	self.Lbl:SetWide(w * 0.5)

	self.SkinList:SetPos(4, 4 + self.Lbl:GetTall() + 2)
	self.SkinList:SetWide(w * 0.4 - 8)
	self.SkinList:SetTall(h * 0.4 - self.SkinList:GetY() - 4)

	self.Lbl4:SetPos(6, self.SkinList:GetY() + self.SkinList:GetTall() + 2)
	self.Lbl4:SetWide(w * 0.5)

	self.PresetList:SetPos(4, 4 + self.Lbl4:GetY() + self.Lbl4:GetTall())
	self.PresetList:SetWide(self.SkinList:GetWide())
	self.PresetList:SetTall(h - self.Properties:GetTall() - defbuttall - 80)

	self.Properties:SetPos(8 + self.SkinList:GetWide(), self.SkinList:GetY())
	self.Properties:SetWide(w * 0.6 - 8)
	self.Properties:SetTall(h * 0.4 - self.Properties:GetY() - 4)

	self.Lbl3:SetPos(self.Properties:GetX(),self.Lbl4:GetY())
	self.Lbl3:SetWide(w * 0.3)

	self.AvailProps:SetPos(self.Properties:GetX(), self.PresetList:GetY())
	self.AvailProps:SetWide(self.Properties:GetWide())
	self.AvailProps:SetTall(self.PresetList:GetTall())
	self.PropsListGeneral:InvalidateLayout()
	self.AvailProps:InvalidateLayout()

	self.SaveButton:SetPos(self.AvailProps:GetX(), self.AvailProps:GetY() + self.AvailProps:GetTall() + 4)
	self.SaveButton:SetSize(50, defbuttall)

	self.RefreshButton:SetPos(self.PresetList:GetX() + self.PresetList:GetWide() - 100, self.PresetList:GetY() + self.PresetList:GetTall() + 4)
	self.RefreshButton:SetSize(100, defbuttall)

	self.DeleteButton:SetPos(self.RefreshButton:GetX() - 84, self.RefreshButton:GetY())
	self.DeleteButton:SetSize(80, defbuttall)

	self.ApplyButton:SetPos(w - 100 - 8, self.SaveButton:GetY())
	self.ApplyButton:SetSize(100, defbuttall)

	self.PresetName:SetPos(self.SaveButton:GetX() + self.SaveButton:GetWide() + 4, self.SaveButton:GetY())
	self.PresetName:SetSize(100, defbuttall)

	self.Properties:InvalidateLayout()

	self.Lbl2:SetPos(self.Properties:GetX(),4)
	self.Lbl2:SetWide(w * 0.5)

	if self.EditedText && self.EditedImg then
		self.EditedImg:SetPos(self.AvailProps:GetX(), self.AvailProps:GetY() + self.AvailProps:GetTall() + 8 + defbuttall)
		self.EditedImg:SetSize(16,16)
		self.EditedText:SetPos(self.EditedImg:GetX() + 20, self.EditedImg:GetY())
		self.EditedText:SetWide(300)
	end
end

vgui.Register("uiskinmgr_panel", PANEL, "DPanel")