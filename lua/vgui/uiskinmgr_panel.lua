include("includes/uiskinmgr_include.lua")

local BasePanel = baseclass.Get("DPanel")
local PANEL = {}

local availProp = vgui.RegisterTable({
	Init = function(self)
		self.Label = self:Add("DLabel")
		self.Label:SetDark(true)
		self.DivRatio = 0.6
		self.Disabled = false
		self.VarName = ""

		self:SetPaintBackground(false)
	end,
	SetDisabled = function(self, bool)
		self.Disabled = bool

		self.Button:SetEnabled(!bool)
	end,
	SetAvailable = function(self, bool)
		if !bool then
			self.Button:SetImage("icon16/tick.png")
			self.Button:SetTooltip("Already in preset")
		else
			self.Button:SetImage("icon16/add.png")
			self.Button:SetTooltip("Add to preset")
		end

		self:SetDisabled(!bool)
	end,
	OnRemoved = function(self) end,
	OnDefault = function(self) end,
	OnAdded = function(self) end,
	OnEdited = function(self, anyval) end,
	Setup = function(self, value, name, editable)
		self.VarName = name
		self.Label:SetText(name)
		local skeen = self:GetSkin()

		self.Button = self:Add("DImageButton")

		if istable(value) && value.r && value.g && value.b then
			self.Inner = self:Add("DButton")
			self.Inner:SetText("")
			self.Inner.Val = Color(value.r, value.g, value.b, value.a or 255)
			self.Inner.Paint = function(s, w, h)
				surface.SetDrawColor(skeen.Colours.Properties.Border)
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(s.Val.r, s.Val.g, s.Val.b, 255)
				surface.DrawRect(2, 2, w-4, h-4)
			end

			if editable then
				self.Inner.DoClick = function(s)
					local color = vgui.Create( "DColorCombo", self )
					color.Mixer:SetAlphaBar( true )
					color:SetColor(self.Inner.Val)
					color:SetupCloseButton( function() CloseDermaMenus() end )
					color.OnValueChanged = function( color, newcol )
						self:OnEdited( newcol )
						self.Inner.Val = newcol
					end

					local menu = DermaMenu()
					menu:AddPanel( color )
					menu:SetPaintBackground( false )
					menu:Open( gui.MouseX() + 8, gui.MouseY() + 10 )
				end
			end
		elseif isstring(value) then
			self.Inner = self:Add("DTextEntry")
			self.Inner:SetValue(value)
			self.Inner:SetPaintBackground( false )
			self.Inner:SetEditable(editable)
			self.Inner.OnChange = function(s)
				self:OnEdited(s:GetValue())
			end
		end

		if editable then
			self.Button:SetImage("icon16/delete.png")
			self.Button.DoClick = function(b)
				self:OnRemoved()
			end
			self.Button:SetTooltip("Remove from preset")

			self.DefButton = self:Add("DImageButton")
			self.DefButton:SetImage("icon16/cog.png")
			self.DefButton.DoClick = function(b)
				self:OnDefault()
			end
			self.DefButton:SetTooltip("Revert to skin default")
		else
			self.Button.DoClick = function(b)
				self:OnAdded()
			end

			self:SetAvailable(true)
		end
	end,
	PerformLayout = function(self, w, h)
		local divw = w * self.DivRatio
		local divw2 = w * (1-self.DivRatio)

		surface.SetFont(self.Label:GetFont())
		local textw, texth = surface.GetTextSize(self.VarName)
		self.Label:SetPos(8, 2)
		self.Label:SetWide(divw - 8)
		self.Label:SetText(self.VarName)
		
		if textw > self.Label:GetWide() then
			local ratio = textw / self.Label:GetWide()

			local str = string.match(self.VarName, "(%.[%w_]+)$")
			self.Label:SetText(str or self.VarName)
		end

		if self.Inner then
			self.Inner:SetPos(divw + 4, 2)
			self.Inner:SetSize(divw2 * 0.6, h - 4)
		end

		local xyz = w - 18
		if self.Button then
			self.Button:SetPos(xyz, h - 20)
			self.Button:SetSize(16, 16)

			xyz = xyz - 20
		end

		if self.DefButton then
			self.DefButton:SetPos(xyz, h - 20)
			self.DefButton:SetSize(16, 16)
		end
	end,
	SetDivision = function(self, ratio)
		self.DivRatio = ratio
	end,
	Paint = function(self, w, h)
		local Skin = self:GetSkin()
		surface.SetDrawColor( color_white )
		surface.DrawRect( 0, 0, w, h )
		surface.SetDrawColor( Skin.Colours.Properties.Border )
		surface.DrawRect( 0, h-1, w, 1 )
		surface.DrawRect( w * self.DivRatio, 0, 1, h )

		if self.Disabled then
			self.Label:SetTextColor(Skin.Colours.Properties.Label_Disabled)

			if self.Inner && self.Inner.SetTextColor then
				self.Inner:SetTextColor(Skin.Colours.Properties.Label_Disabled)
			end
		end
	end
}, "DPanel")

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
		local avail

		if v.r && v.g && v.b then
			avail = vgui.CreateFromTable(availProp)
			avail:Setup({r = v.r, g = v.g, b = v.b, a = v.a}, k)
			avail.OnAdded = function(x)
				self.PresetData[k] = self.PresetData[k] or {r = v.r, g = v.g, b = v.b, a = v.a}
				self:UpdateProperties()
				self:OnEdited(true)
			end
		elseif isstring(v) then
			avail = vgui.CreateFromTable(availProp)
			avail:Setup(v, k)
			avail.OnAdded = function(x)
				self.PresetData[k] = self.PresetData[k] or v
				self:UpdateProperties()
				self:OnEdited(true)
			end
		end

		if IsValid(avail) then
			avail:SetDisabled(!uiskinmgr.IsAllowedField(k))
			self.AllProperties[self.SkinManagerTable.currentSkin .. k] = avail

			if uiskinmgr.IsExperimental(k) then
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
		
		local prop = self.PropertiesList:Add(availProp)
		prop:SetDivision(0.4)
		prop:Setup(v, k, true)
		prop:SetDisabled(!uiskinmgr.IsAllowedField(k))
		prop.OnRemoved = function(x)
			self.PresetData[k] = nil
			self:UpdateProperties()
			self:OnEdited(true)
			
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