--[[
# Element: Monk Stagger Bar

Handles the visibility and updating of the Monk's stagger bar.

## Widget

Stagger - A `StatusBar` used to represent the current stagger level.

## Sub-Widgets

.bg - A `Texture` used as a background. It will inherit the color of the main StatusBar.

## Notes

A default texture will be applied if the widget is a StatusBar and doesn't have a texture set.

## Sub-Widgets Options

.multiplier - Used to tint the background based on the main widgets R, G and B values. Defaults to 1 (number)[0-1]

## Examples

    local Stagger = CreateFrame('StatusBar', nil, self)
    Stagger:SetSize(120, 20)
    Stagger:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, 0)

    -- Register with oUF
    self.Stagger = Stagger
--]]

if(select(2, UnitClass('player')) ~= 'MONK') then return end

local _, ns = ...
local oUF = ns.oUF

-- ElvUI block
local GetSpecialization = GetSpecialization
local UnitHasVehiclePlayerFrameUI = UnitHasVehiclePlayerFrameUI
local UnitHealthMax = UnitHealthMax
local UnitIsUnit = UnitIsUnit
local UnitStagger = UnitStagger
-- GLOBALS: MonkStaggerBar
-- end block

-- sourced from FrameXML/Constants.lua
local SPEC_MONK_BREWMASTER = SPEC_MONK_BREWMASTER or 1

-- sourced from FrameXML/MonkStaggerBar.lua
local BREWMASTER_POWER_BAR_NAME = BREWMASTER_POWER_BAR_NAME or 'STAGGER'

-- percentages at which bar should change color
local STAGGER_YELLOW_TRANSITION =  STAGGER_YELLOW_TRANSITION or 0.3
local STAGGER_RED_TRANSITION = STAGGER_RED_TRANSITION or 0.6

-- table indices of bar colors
local STAGGER_GREEN_INDEX = STAGGER_GREEN_INDEX or 1
local STAGGER_YELLOW_INDEX = STAGGER_YELLOW_INDEX or 2
local STAGGER_RED_INDEX = STAGGER_RED_INDEX or 3

local function UpdateColor(self, event, unit)
	if(unit and unit ~= self.unit) then return end
	local element = self.Stagger

	local colors = self.colors.power[BREWMASTER_POWER_BAR_NAME]

	-- ElvUI changed block
	local cur, max = element.cur or 0, element.max or 1
	local perc = max > 0 and (cur / max) or 0 -- ElvUI changed
	-- ElvUI end

	local t
	if(perc >= STAGGER_RED_TRANSITION) then
		t = colors and colors[STAGGER_RED_INDEX]
	elseif(perc > STAGGER_YELLOW_TRANSITION) then
		t = colors and colors[STAGGER_YELLOW_INDEX]
	else
		t = colors and colors[STAGGER_GREEN_INDEX]
	end

	local r, g, b
	if(t) then
		r, g, b = t[1], t[2], t[3]
		if(b) then
			element:SetStatusBarColor(r, g, b)

			local bg = element.bg
			if(bg and b) then
				local mu = bg.multiplier or 1
				bg:SetVertexColor(r * mu, g * mu, b * mu)
			end
		end
	end

	if(element.PostUpdateColor) then
		element:PostUpdateColor(r, g, b)
	end
end

local function Update(self, event, unit)
	if(unit and unit ~= self.unit) then return end

	local element = self.Stagger

	--[[ Callback: Stagger:PreUpdate()
	Called before the element has been updated.

	* self - the Stagger element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	-- Blizzard code has nil checks for UnitStagger return
	local cur = UnitStagger('player') or 0
	local max = UnitHealthMax('player')

	element:SetMinMaxValues(0, max)
	element:SetValue(cur)

	element.cur = cur
	element.max = max

	--[[ Callback: Stagger:PostUpdate(cur, max)
	Called after the element has been updated.

	* self - the Stagger element
	* cur  - the amount of staggered damage (number)
	* max  - the player's maximum possible health value (number)
	--]]
	if(element.PostUpdate) then
		element:PostUpdate(cur, max)
	end
end

local function Path(self, ...)
	--[[ Override: Stagger.Override(self, event, unit)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	(self.Stagger.Override or Update)(self, ...);

	--[[ Override: Stagger.UpdateColor(self, event, unit)
	Used to completely override the internal function for updating the widgets' colors.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	(self.Stagger.UpdateColor or UpdateColor) (self, ...)
end

-- ElvUI changed
local function Visibility(self, event, unit)
	local element = self.Stagger
	local isShown = element:IsShown()
	local useClassbar = (SPEC_MONK_BREWMASTER ~= GetSpecialization()) or UnitHasVehiclePlayerFrameUI('player')
	local stateChanged = false

	if useClassbar and isShown then
		element:Hide()
		self:UnregisterEvent('UNIT_AURA', Path)
		stateChanged = true
	elseif not useClassbar and not isShown then
		element:Show()
		self:RegisterEvent('UNIT_AURA', Path)
		stateChanged = true
	end

	if element.PostUpdateVisibility then
		element.PostUpdateVisibility(self, event, unit, not useClassbar, stateChanged)
	end

	if not useClassbar then
		Path(self, event, unit)
	end
end
-- end block

local function VisibilityPath(self, ...)
	--[[ Override: Stagger.OverrideVisibility(self, event, unit)
	Used to completely override the internal visibility toggling function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	(self.Stagger.OverrideVisibility or Visibility)(self, ...)
end

local function ForceUpdate(element)
	VisibilityPath(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.Stagger
	if(element and UnitIsUnit(unit, 'player')) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)
		self:RegisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath, true)

		if(element:IsObjectType('StatusBar') and not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		MonkStaggerBar:UnregisterEvent('PLAYER_ENTERING_WORLD')
		MonkStaggerBar:UnregisterEvent('PLAYER_SPECIALIZATION_CHANGED')
		MonkStaggerBar:UnregisterEvent('UNIT_DISPLAYPOWER')
		MonkStaggerBar:UnregisterEvent('UNIT_EXITED_VEHICLE')
		MonkStaggerBar:UnregisterEvent('UPDATE_VEHICLE_ACTIONBAR')

		element:Hide()

		return true
	end
end

local function Disable(self)
	local element = self.Stagger
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_AURA', Path)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)
		self:UnregisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath)

		MonkStaggerBar:RegisterEvent('PLAYER_ENTERING_WORLD')
		MonkStaggerBar:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
		MonkStaggerBar:RegisterEvent('UNIT_DISPLAYPOWER')
		MonkStaggerBar:RegisterEvent('UNIT_EXITED_VEHICLE')
		MonkStaggerBar:RegisterEvent('UPDATE_VEHICLE_ACTIONBAR')
	end
end

oUF:AddElement('Stagger', VisibilityPath, Enable, Disable)
