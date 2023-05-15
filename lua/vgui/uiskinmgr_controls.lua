local PANEL = {}

function PANEL:Init()
	self.Label = self:Add("DLabel")
	self.Label:SetTextColor(self:GetSkin().Colours.Label.Dark)

	self.DivRatio = 0.6
	self.Disabled = false
	self.Editable = false

	self.VarName = ""

	self:SetPaintBackground(false)
end

function PANEL:Setup(value, name, editable, type)
	self:SetTooltip(name)
	self.Buttons = {}
	self.Editable = editable

	self.VarName = name
	self.Label:SetText(name)

	local additional
	if !type then
		if istable(value) && value.r && value.g && value.b then
			type = "Color"
		elseif isstring(value) then type = "Generic"
		elseif isnumber(value) then type = "Number"
		end
	elseif istable(type) && type.choices then
		additional = type
		type = "Combo"
	end

	if !vgui.GetControlTable("uiskinmgr_control_"..type) then type = "Generic" end

	self.Inner = vgui.Create("uiskinmgr_control_"..type, self)
	self.Inner:Setup(value or (additional && additional.text), editable, self)

	if self.Inner.SetOptions then
		self.Inner:SetOptions(additional.choices)
	end

	if editable then
		local butRemove = self:Add("DImageButton")
		butRemove:SetImage("icon16/delete.png")
		butRemove:SetSize(16,16)
		butRemove:SetTooltip("Remove from preset")
		butRemove.DoClick = function(b)
			self:OnRemoved()
		end

		local butDefault = self:Add("DImageButton")
		butDefault:SetImage("icon16/cog.png")
		butDefault:SetSize(16,16)
		butDefault:SetTooltip("Revert to skin default")
		butDefault.DoClick = function(b)
			self:OnDefault()
		end

		self.Buttons[1] = butRemove
		self.Buttons[2] = butDefault
	else
		self:SetAvailable(true)
	end
end

function PANEL:SetDisabled(bool)
	self.Disabled = bool

	if bool then
		self.Label:SetTextColor(self:GetSkin().Colours.Properties.Label_Disabled)
	else
		self.Label:SetTextColor(self:GetSkin().Colours.Label.Dark)
	end

	if self.ButtonAdd then self.ButtonAdd:SetEnabled(!bool) end
end

function PANEL:SetAvailable(bool)
	if self.Editable || !self.Buttons then return end

	if !self.ButtonAdd then
		self.ButtonAdd = self:Add("DImageButton")
		self.ButtonAdd:SetSize(16,16)
		self.ButtonAdd.DoClick = function(b)
			self:OnAdded()
		end
		self.Buttons[#self.Buttons + 1] = self.ButtonAdd
	end

	if bool then
		self.ButtonAdd:SetImage("icon16/add.png")
		self.ButtonAdd:SetTooltip("Add to preset")
	else
		self.ButtonAdd:SetImage("icon16/tick.png")
		self.ButtonAdd:SetTooltip("Already in preset")
	end
end

function PANEL:SetDivision(ratio)
	self.DivRatio = math.min(1, math.max(0, ratio))
end

function PANEL:Paint(w, h)
	local Skin = self:GetSkin()
	local col = color_white

	if self.Disabled then
		surface.SetDrawColor( col.r - 10, col.g - 10, col.b - 10, col.a )
	else
		surface.SetDrawColor( col )
	end
	surface.DrawRect( 0, 0, w, h )

	surface.SetDrawColor( Skin.Colours.Properties.Border )
	surface.DrawRect( 0, h-1, w, 1 )
	surface.DrawRect( w * self.DivRatio, 0, 1, h )
end

function PANEL:PerformLayout(w, h)
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

	local restSpace = divw2
	for _, but in ipairs(self.Buttons) do
		restSpace = restSpace - but:GetWide() - 4
		but:SetPos(divw + restSpace, 4)
	end

	if self.Inner then
		self.Inner:SetPos(divw + 4, 2)
		self.Inner:SetSize(restSpace - 8, h - 4)
	end
end

function PANEL:OnRemoved() end
function PANEL:OnDefault() end
function PANEL:OnAdded() end
function PANEL:OnEdited() end

vgui.Register("uiskinmgr_control", PANEL, "DPanel")


/*============ CONTROLS ============
--- Generic ---*/
PANEL = {}
function PANEL:Init()
	self.Editable = false
	self:SetPaintBackground(false)
end

function PANEL:Setup(value, editable, parent)
	self.Editable = editable
	self.Parent = parent or self:GetParent()
	self.TextEntry = self:Add("DTextEntry")
	self.TextEntry:SetEditable(editable)
	self:SetValue(value)
	
	self.TextEntry.OnChange = function(s)
		self.Parent:OnEdited(s:GetValue())
	end
	self.TextEntry:SetPaintBackground(false)

	local skin = self:GetSkin()

	self.TextEntry.Paint = function(s, w, h)
		surface.SetDrawColor(skin.colTextEntryBG)
		surface.DrawRect(0,0,w,h)
		s:DrawTextEntryText(skin.colTextEntryText, skin.colTextEntryTextHighlight, skin.colTextEntryTextCursor)
	end
end

function PANEL:SetValue(value)
	if istable(value) then
		if value.r && value.g && value.b then
			value = value.r .. " " .. value.g .. " " .. value.b .. " " .. (value.a or "")
		else
			local str = ""
			for k, v in pairs(value) do
				if isnumber(v) || isstring(v) then
					str = str .. v .. " "
				end
			end

			value = string.Trim(str, " ") //remove any unnecessary spaces
		end
	end

	self.TextEntry:SetValue(value)
end

function PANEL:PerformLayout(w, h)
	self.TextEntry:SetPos(0,0)
	self.TextEntry:SetSize(w,h)
end

derma.DefineControl("uiskinmgr_control_Generic", "", PANEL, "DPanel")

/*--- Color ---*/
PANEL = {}
DEFINE_BASECLASS( "uiskinmgr_control_Generic" )

function PANEL:SetValue(value)
	BaseClass.SetValue(self, value)
	self.Color = value
	self.Parent:OnEdited(value)
end

function PANEL:Setup(value, editable, parent)
	BaseClass.Setup(self, value, editable, parent)
	self.Color = value

	self.TextEntry.OnChange = function(s)
		local split = string.Split(s:GetValue(), " ")
		local color = Color(
			tonumber(split[1]) or 255,
			tonumber(split[2]) or 255,
			tonumber(split[3]) or 255,
			tonumber(split[4]) or 255
		)

		self.Color = color
		self.Parent:OnEdited(color)
	end

	self.ColorCube = self:Add("DButton")
	self.ColorCube:SetText("")
	self.ColorCube:SetPaintBackground(false)
	self.ColorCube:SetEnabled(editable)
	self.ColorCube.DoClick = function(but)
		local color = vgui.Create( "DColorCombo", self )
		color.Mixer:SetAlphaBar( true )
		color:SetColor(self.Color)
		color:SetupCloseButton( function() CloseDermaMenus() end )
		color.OnValueChanged = function( color, newcol )
			self:SetValue(newcol)
		end

		local menu = DermaMenu()
		menu:AddPanel( color )
		menu:SetPaintBackground( false )
		menu:Open( gui.MouseX() + 8, gui.MouseY() + 10 )
	end

	local skin = self:GetSkin()
	self.ColorCube.Paint = function(s, w, h)
		surface.SetDrawColor(skin.Colours.Properties.Border)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(self.Color.r, self.Color.g, self.Color.b, 255)
		surface.DrawRect(2, 2, w-4, h-4)
	end
end

function PANEL:PerformLayout(w, h)
	self.ColorCube:SetPos(0,0)
	self.ColorCube:SetSize(h, h)
	self.TextEntry:SetPos(h+4, 0)
	self.TextEntry:SetSize(w - h - 4, h)
end

derma.DefineControl("uiskinmgr_control_Color", "", PANEL, "uiskinmgr_control_Generic")

/*--- Combo ---*/
PANEL = {}

function PANEL:Setup(value, editable, parent)
	self.Editable = editable
	self.Parent = parent

	self.TextEntry = self:Add("DComboBox") //hack to get the layout automaticaly working :)
	self.TextEntry:SetEnabled(editable)
	self.TextEntry.OnSelect = function(cb, index, value, data)
		self.Parent:OnEdited(data)
	end

	self.Value = value
end

function PANEL:SetOptions(choices)
	for k, v in SortedPairs(choices) do
		self.TextEntry:AddChoice(k, v)

		if v == self.Value then
			self.TextEntry:SetText(k)
		end
	end
end

derma.DefineControl("uiskinmgr_control_Combo", "", PANEL, "uiskinmgr_control_Generic")
