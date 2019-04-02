local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local NP = E:GetModule('NamePlates')
local ElvUF = E.oUF

--Cache global variables
local _G = _G
--Lua functions
local wipe = wipe
local select = select
local pairs = pairs
local type = type
local format = format
local tonumber = tonumber
--WoW API / Variables
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
local UnitIsPlayer = UnitIsPlayer
local UnitIsUnit = UnitIsUnit
local UnitReaction = UnitReaction
local SetCVar, GetCVarDefault = SetCVar, GetCVarDefault
local UnitFactionGroup = UnitFactionGroup
local UnitIsPVPSanctuary = UnitIsPVPSanctuary
local UnitIsFriend = UnitIsFriend
local IsInGroup, IsInRaid = IsInGroup, IsInRaid
local IsInInstance = IsInInstance
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitExists = UnitExists
local UnitClass = UnitClass
local UnitName = UnitName
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local GetSpecializationRole = GetSpecializationRole
local GetSpecialization = GetSpecialization
local C_NamePlate_SetNamePlateSelfSize = C_NamePlate.SetNamePlateSelfSize
local C_NamePlate_SetNamePlateEnemySize = C_NamePlate.SetNamePlateEnemySize
local C_NamePlate_SetNamePlateEnemyClickThrough = C_NamePlate.SetNamePlateEnemyClickThrough
local C_NamePlate_SetNamePlateFriendlyClickThrough = C_NamePlate.SetNamePlateFriendlyClickThrough
local C_NamePlate_SetNamePlateSelfClickThrough = C_NamePlate.SetNamePlateSelfClickThrough

local function CopySettings(from, to)
	for setting, value in pairs(from) do
		if(type(value) == 'table' and to[setting] ~= nil) then
			CopySettings(from[setting], to[setting])
		else
			if(to[setting] ~= nil) then
				to[setting] = from[setting]
			end
		end
	end
end

function NP:ResetSettings(unit)
	CopySettings(P.nameplates.units[unit], self.db.units[unit])
end

function NP:CopySettings(from, to)
	if (from == to) then return end

	CopySettings(self.db.units[from], self.db.units[to])
end

function NP:CVarReset()
	SetCVar("nameplateOccludedAlphaMult", .5)
	SetCVar("nameplateMinAlpha", GetCVarDefault("nameplateMinAlpha"))
	SetCVar('nameplateClassResourceTopInset', GetCVarDefault('nameplateClassResourceTopInset'))
	SetCVar('nameplateGlobalScale', 1)
	SetCVar('NamePlateHorizontalScale', 1)
	SetCVar('nameplateLargeBottomInset', GetCVarDefault('nameplateLargeBottomInset'))
	SetCVar('nameplateLargerScale', 1)
	SetCVar('nameplateLargeTopInset', GetCVarDefault('nameplateLargeTopInset'))
	SetCVar('nameplateMaxAlphaDistance', GetCVarDefault('nameplateMaxAlphaDistance'))
	SetCVar('nameplateMaxScale', 1)
	SetCVar('nameplateMaxScaleDistance', 40)
	SetCVar('nameplateMinAlphaDistance', GetCVarDefault('nameplateMinAlphaDistance'))
	SetCVar('nameplateMinScale', 1)
	SetCVar('nameplateMinScaleDistance', 0)
	SetCVar('nameplateSelectedScale', 1)
	SetCVar('nameplateMotionSpeed', GetCVarDefault('nameplateMotionSpeed'))
	SetCVar('nameplateOccludedAlphaMult', GetCVarDefault('nameplateOccludedAlphaMult'))
	SetCVar('nameplateOtherAtBase', GetCVarDefault('nameplateOtherAtBase'))
	SetCVar('nameplateOverlapH', GetCVarDefault('nameplateOverlapH'))
	SetCVar('nameplateOverlapV', GetCVarDefault('nameplateOverlapV'))
	SetCVar('nameplateResourceOnTarget', GetCVarDefault('nameplateResourceOnTarget'))
	SetCVar('nameplateSelectedAlpha', 1)
	SetCVar('nameplateSelectedScale', 1)
	SetCVar('nameplateSelfAlpha', 1)
	SetCVar('nameplateSelfBottomInset', GetCVarDefault('nameplateSelfBottomInset'))
	SetCVar('nameplateSelfScale', 1)
	SetCVar('nameplateSelfTopInset', GetCVarDefault('nameplateSelfTopInset'))
	SetCVar('nameplateTargetBehindMaxDistance', 40)
end

function NP:SetCVars()
	SetCVar('nameplateMaxDistance', NP.db.loadDistance)
	SetCVar('nameplateMotion', NP.db.motionType == 'STACKED' and 1 or 0)

	-- SetCVar('nameplateShowAll', 1) -- NP Show Always

	SetCVar('NameplatePersonalShowAlways', NP.db.units.PLAYER.visibility.showAlways and 1 or 0)
	SetCVar('NameplatePersonalShowInCombat', NP.db.units.PLAYER.visibility.showInCombat and 1 or 0)
	SetCVar('NameplatePersonalShowWithTarget', NP.db.units.PLAYER.visibility.showWithTarget and 1 or 0)
	SetCVar('NameplatePersonalHideDelayAlpha', NP.db.units.PLAYER.visibility.hideDelay)

	SetCVar('nameplateShowFriendlyMinions', NP.db.units.FRIENDLY_PLAYER.minions and 1 or 0)
	SetCVar('nameplateShowEnemyMinions', (NP.db.units.ENEMY_PLAYER.minions or NP.db.units.ENEMY_NPC.minions) and 1 or 0)
	SetCVar('nameplateShowEnemyMinus', NP.db.units.ENEMY_NPC.minors and 1 or 0)
	SetCVar('nameplateShowSelf', (NP.db.units.PLAYER.useStaticPosition == true or NP.db.units.PLAYER.enable ~= true) and 0 or 1)
	SetCVar('nameplateSelectedScale', NP.db.units.TARGET.scale)

	if NP.db.questIcon then
		SetCVar('showQuestTrackingTooltips', 1)
	end

	if NP.db.clampToScreen then
		SetCVar('nameplateOtherTopInset', 0.08)
		SetCVar('nameplateOtherBottomInset', 0.1)
	end
end

function NP:PLAYER_REGEN_DISABLED()
	SetCVar("nameplateMaxAlpha", NP.db.units.TARGET.nonTargetTransparency)
	SetCVar("nameplateMinAlpha", NP.db.units.TARGET.nonTargetTransparency)

	if (NP.db.showFriendlyCombat == 'TOGGLE_ON') then
		SetCVar('nameplateShowFriends', 1);
	elseif (NP.db.showFriendlyCombat == 'TOGGLE_OFF') then
		SetCVar('nameplateShowFriends', 0);
	end

	if (NP.db.showEnemyCombat == 'TOGGLE_ON') then
		SetCVar('nameplateShowEnemies', 1);
	elseif (NP.db.showEnemyCombat == 'TOGGLE_OFF') then
		SetCVar('nameplateShowEnemies', 0);
	end
end

function NP:PLAYER_REGEN_ENABLED()
	SetCVar("nameplateMaxAlpha", 1)
	SetCVar("nameplateMinAlpha", 1)

	if (NP.db.showFriendlyCombat == 'TOGGLE_ON') then
		SetCVar('nameplateShowFriends', 0);
	elseif (NP.db.showFriendlyCombat == 'TOGGLE_OFF') then
		SetCVar('nameplateShowFriends', 1);
	end

	if (NP.db.showEnemyCombat == 'TOGGLE_ON') then
		SetCVar('nameplateShowEnemies', 0);
	elseif (NP.db.showEnemyCombat == 'TOGGLE_OFF') then
		SetCVar('nameplateShowEnemies', 1);
	end
end

function NP:Style(frame, unit)
	if (not unit) then
		return
	end

	frame.isNamePlate = true

	if frame:GetName() == 'ElvNP_TargetClassPower' then
		NP:StyleTargetPlate(frame, unit)
	else
		NP:StylePlate(frame, unit)
	end

	return frame
end

function NP:Construct_RaisedELement(nameplate)
	local RaisedElement = CreateFrame('Frame', nameplate:GetDebugName()..'RaisedElement', nameplate)
	RaisedElement:SetFrameStrata(nameplate:GetFrameStrata())
	RaisedElement:SetFrameLevel(10)
	RaisedElement:SetAllPoints()
	RaisedElement:EnableMouse(false)

	return RaisedElement
end

function NP:StyleTargetPlate(nameplate)
	nameplate:Point('CENTER')
	nameplate:Size(self.db.clickableWidth, self.db.clickableHeight)
	nameplate:SetScale(E.global.general.UIScale)

	nameplate.RaisedElement = NP:Construct_RaisedELement(nameplate)

	--nameplate.Power = NP:Construct_Power(nameplate)

	--nameplate.Power.Text = NP:Construct_TagText(nameplate.RaisedElement)

	nameplate.ClassPower = NP:Construct_ClassPower(nameplate)

	if E.myclass == 'DEATHKNIGHT' then
		nameplate.Runes = NP:Construct_Runes(nameplate)
	end
end

function NP:UpdateTargetPlate(nameplate)
	NP:Update_ClassPower(nameplate)

	if E.myclass == 'DEATHKNIGHT' then
		NP:Update_Runes(nameplate)
	end

	nameplate:UpdateAllElements('OnShow')
end

function NP:ScalePlate(nameplate, scale, targetPlate)
	if NP.targetPlate then
		NP.targetPlate:SetScale(E.global.general.UIScale)
		NP.targetPlate = false
	end

	if not nameplate then
		return
	end

	local targetScale = format('%.2f', E.global.general.UIScale * scale)
	nameplate:SetScale(targetScale)

	if targetPlate then
		NP.targetPlate = nameplate
	end
end

function NP:StylePlate(nameplate)
	nameplate:Point('CENTER')
	nameplate:Size(self.db.clickableWidth, self.db.clickableHeight)
	nameplate:SetScale(E.global.general.UIScale)

	nameplate.RaisedElement = NP:Construct_RaisedELement(nameplate)
	nameplate.Health = NP:Construct_Health(nameplate)
	nameplate.Health.Text = NP:Construct_TagText(nameplate.RaisedElement)
	nameplate.HealthPrediction = NP:Construct_HealthPrediction(nameplate)
	nameplate.Power = NP:Construct_Power(nameplate)
	nameplate.Power.Text = NP:Construct_TagText(nameplate.RaisedElement)
	nameplate.Name = NP:Construct_TagText(nameplate.RaisedElement)
	nameplate.Level = NP:Construct_TagText(nameplate.RaisedElement)
	nameplate.Title = NP:Construct_TagText(nameplate.RaisedElement)
	nameplate.ClassificationIndicator = NP:Construct_ClassificationIndicator(nameplate.RaisedElement)
	nameplate.Castbar = NP:Construct_Castbar(nameplate)
	nameplate.Portrait = NP:Construct_Portrait(nameplate.RaisedElement)
	nameplate.QuestIcons = NP:Construct_QuestIcons(nameplate.RaisedElement)
	nameplate.RaidTargetIndicator = NP:Construct_RaidTargetIndicator(nameplate.RaisedElement)
	nameplate.TargetIndicator = NP:Construct_TargetIndicator(nameplate)
	nameplate.ThreatIndicator = NP:Construct_ThreatIndicator(nameplate.RaisedElement)
	nameplate.Highlight = NP:Construct_Highlight(nameplate)
	nameplate.ClassPower = NP:Construct_ClassPower(nameplate)
	nameplate.PvPIndicator = NP:Construct_PvPIndicator(nameplate.RaisedElement) -- Horde / Alliance / HonorInfo
	nameplate.PvPClassificationIndicator = NP:Construct_PvPClassificationIndicator(nameplate.RaisedElement) -- Cart / Flag / Orb / Assassin Bounty
	nameplate.HealerSpecs = NP:Construct_HealerSpecs(nameplate.RaisedElement)
	nameplate.FloatingCombatFeedback = NP:Construct_FloatingCombatFeedback(nameplate.RaisedElement)
	--nameplate.Cutaway = NP:Construct_Cutaway(nameplate)
	NP:Construct_Auras(nameplate)

	if E.myclass == 'DEATHKNIGHT' then
		nameplate.Runes = NP:Construct_Runes(nameplate)
	end

	if nameplate == _G.ElvNP_Player then
		nameplate:SetScript('OnEnter', _G.UnitFrame_OnEnter)
		nameplate:SetScript('OnLeave', _G.UnitFrame_OnLeave)
		nameplate.Fader = NP:DefaultFader()
	end

	NP.Plates[nameplate] = nameplate:GetName()
end

function NP:UpdatePlate(nameplate)
	NP:Update_Tags(nameplate)
	NP:Update_Highlight(nameplate)

	if (nameplate.VisibilityChanged or nameplate.NameOnlyChanged) or (not NP.db.units[nameplate.frameType].enable) or NP.db.units[nameplate.frameType].nameOnly then
		NP:DisablePlate(nameplate, nameplate.NameOnlyChanged or (NP.db.units[nameplate.frameType].nameOnly and not nameplate.VisibilityChanged))
	else
		NP:Update_Health(nameplate)
		NP:Update_HealthPrediction(nameplate)
		NP:Update_Power(nameplate)
		NP:Update_Castbar(nameplate)
		NP:Update_ClassPower(nameplate)
		NP:Update_Auras(nameplate)
		NP:Update_ClassificationIndicator(nameplate)
		NP:Update_QuestIcons(nameplate)
		NP:Update_Portrait(nameplate)
		NP:Update_PvPIndicator(nameplate) -- Horde / Alliance / HonorInfo
		NP:Update_PvPClassificationIndicator(nameplate) -- Cart / Flag / Orb / Assassin Bounty
		NP:Update_TargetIndicator(nameplate)
		NP:Update_ThreatIndicator(nameplate)
		NP:Update_RaidTargetIndicator(nameplate)
		NP:Update_HealerSpecs(nameplate)
		NP:Update_FloatingCombatFeedback(nameplate)

		if E.myclass == 'DEATHKNIGHT' then
			NP:Update_Runes(nameplate)
		end

		if nameplate == _G.ElvNP_Player then
			NP:Update_Fader(nameplate)
		end
	end

	NP:StyleFilterEvents(nameplate)
end

function NP:DisablePlate(nameplate, nameOnly)
	if nameplate:IsElementEnabled('Health') then nameplate:DisableElement('Health') end
	if nameplate:IsElementEnabled('HealthPrediction') then nameplate:DisableElement('HealthPrediction') end
	if nameplate:IsElementEnabled('Power') then nameplate:DisableElement('Power') end
	if nameplate:IsElementEnabled('ClassificationIndicator') then nameplate:DisableElement('ClassificationIndicator') end
	if nameplate:IsElementEnabled('Castbar') then nameplate:DisableElement('Castbar') end
	if nameplate:IsElementEnabled('Portrait') then nameplate:DisableElement('Portrait') end
	if nameplate:IsElementEnabled('QuestIcons') then nameplate:DisableElement('QuestIcons') end
	if nameplate:IsElementEnabled('RaidTargetIndicator') then nameplate:DisableElement('RaidTargetIndicator') end
	if nameplate:IsElementEnabled('TargetIndicator') then nameplate:DisableElement('TargetIndicator') end
	if nameplate:IsElementEnabled('ThreatIndicator') then nameplate:DisableElement('ThreatIndicator') end
	if nameplate:IsElementEnabled('ClassPower') then nameplate:DisableElement('ClassPower') end
	if nameplate:IsElementEnabled('PvPIndicator') then nameplate:DisableElement('PvPIndicator') end
	if nameplate:IsElementEnabled('PvPClassificationIndicator') then nameplate:DisableElement('PvPClassificationIndicator') end
	if nameplate:IsElementEnabled('HealerSpecs') then nameplate:DisableElement('HealerSpecs') end
	if nameplate:IsElementEnabled('Auras') then nameplate:DisableElement('Auras') end
	if E.myclass == 'DEATHKNIGHT' and nameplate:IsElementEnabled('Runes') then
		nameplate:DisableElement('Runes')
	end

	nameplate.Health.Text:Hide()
	nameplate.Power.Text:Hide()
	nameplate.Name:Hide()
	nameplate.Level:Hide()
	nameplate.Title:Hide()

	if nameOnly then
		NP:Update_Highlight(nameplate)
		nameplate.Name:Show()
		nameplate.Name:ClearAllPoints()
		nameplate.Name:SetPoint('CENTER', nameplate, 'CENTER', 0, 0)
		if NP.db.units[nameplate.frameType].showTitle then
			nameplate.Title:Show()
			nameplate.Title:ClearAllPoints()
			nameplate.Title:SetPoint('TOP', nameplate.Name, 'BOTTOM', 0, -2)
		end
	end
end

function NP:SetupTarget(nameplate, removed)
	local TCP = _G.ElvNP_TargetClassPower
	local nameOnly = nameplate and (nameplate.NameOnlyChanged or NP.db.units[nameplate.frameType].nameOnly)
	TCP.realPlate = (NP.db.units.TARGET.classpower.enable and not (removed or nameOnly) and nameplate) or nil

	local moveToPlate = TCP.realPlate or TCP
	if TCP.ClassPower then
		TCP.ClassPower:SetParent(moveToPlate)
		TCP.ClassPower:ClearAllPoints()
		TCP.ClassPower:SetPoint('CENTER', moveToPlate, 'CENTER', 0, NP.db.units.TARGET.classpower.yOffset)
	end
	if TCP.Runes then
		TCP.Runes:SetParent(moveToPlate)
		TCP.Runes:ClearAllPoints()
		TCP.Runes:SetPoint('CENTER', moveToPlate, 'CENTER', 0, NP.db.units.TARGET.classpower.yOffset)
	end
end

function NP:SetNamePlateClickThrough()
	self:SetNamePlateSelfClickThrough()
	self:SetNamePlateFriendlyClickThrough()
	self:SetNamePlateEnemyClickThrough()
end

function NP:SetNamePlateSelfClickThrough()
	C_NamePlate_SetNamePlateSelfClickThrough(NP.db.clickThrough.personal)
	_G.ElvNP_Player:EnableMouse(not NP.db.clickThrough.personal)
end

function NP:SetNamePlateFriendlyClickThrough()
	C_NamePlate_SetNamePlateFriendlyClickThrough(NP.db.clickThrough.friendly)
end

function NP:SetNamePlateEnemyClickThrough()
	C_NamePlate_SetNamePlateEnemyClickThrough(NP.db.clickThrough.enemy)
end

function NP:Update_StatusBars()
	for StatusBar in pairs(NP.StatusBars) do
		StatusBar:SetStatusBarTexture(E.LSM:Fetch('statusbar', NP.db.statusbar))
	end
end

function NP:GROUP_ROSTER_UPDATE()
	NP.IsInGroup = IsInRaid() or IsInGroup()

	wipe(NP.GroupRoles)

	if NP.IsInGroup then
		local NumPlayers, Unit = IsInRaid() and GetNumGroupMembers() or GetNumSubgroupMembers(), IsInRaid() and 'raid' or 'party'
		for i = 1, NumPlayers do
			if UnitExists(Unit..i) then
				NP.GroupRoles[UnitName(Unit..i)] = UnitGroupRolesAssigned(Unit..i)
			end
		end
	end
end

function NP:GROUP_LEFT()
	NP.IsInGroup = IsInRaid() or IsInGroup()
	wipe(NP.GroupRoles)
end

function NP:PLAYER_ENTERING_WORLD()
	NP.InstanceType = select(2, IsInInstance())
	NP:UpdatePlate(_G.ElvNP_Player)
end

function NP:ConfigureAll()
	NP:StyleFilterConfigure() -- keep this at the top
	NP.PlayerRole = GetSpecializationRole(GetSpecialization())

	C_NamePlate_SetNamePlateSelfSize(NP.db.clickableWidth, NP.db.clickableHeight)
	C_NamePlate_SetNamePlateEnemySize(NP.db.clickableWidth, NP.db.clickableHeight)

	NP:PLAYER_REGEN_ENABLED()

	if NP.db.units.PLAYER.enable and NP.db.units.PLAYER.useStaticPosition then
		_G.ElvNP_Player:Enable()
	else
		_G.ElvNP_Player:Disable()
	end

	NP:UpdateTargetPlate(_G.ElvNP_TargetClassPower)

	for nameplate in pairs(NP.Plates) do
		NP:StyleFilterClear(nameplate) -- keep this at the top of the loop

		NP:UpdatePlate(nameplate)

		if nameplate.isTarget then
			NP:SetupTarget(nameplate)
		end

		nameplate:UpdateAllElements('ForceUpdate')

		if nameplate.frameType == 'PLAYER' then
			NP.PlayerNamePlateAnchor:ClearAllPoints()
			NP.PlayerNamePlateAnchor:SetParent(NP.db.units.PLAYER.useStaticPosition and _G.ElvNP_Player or nameplate)
			NP.PlayerNamePlateAnchor:SetAllPoints(NP.db.units.PLAYER.useStaticPosition and _G.ElvNP_Player or nameplate)
			NP.PlayerNamePlateAnchor:Show()
		end

		NP:StyleFilterUpdate(nameplate, 'NAME_PLATE_UNIT_ADDED') -- keep this at the end of the loop
	end

	NP:Update_StatusBars()
	NP:SetNamePlateClickThrough()
end

function NP:NamePlateCallBack(nameplate, event, unit)
	if event == 'NAME_PLATE_UNIT_ADDED' then
		NP:StyleFilterClear(nameplate) -- keep this at the top

		unit = unit or nameplate.unit

		nameplate.className, nameplate.classFile, nameplate.classID = UnitClass(unit)
		nameplate.reaction = UnitReaction('player', unit)
		nameplate.isPlayer = UnitIsPlayer(unit)
		nameplate.blizzPlate = nameplate:GetParent().UnitFrame

		NP:StyleFilterSetVariables(nameplate) -- sets: isTarget, isTargetingMe, isFocused

		if UnitIsUnit(unit, 'player') and NP.db.units.PLAYER.enable then
			nameplate.frameType = 'PLAYER'
			NP.PlayerNamePlateAnchor:ClearAllPoints()
			NP.PlayerNamePlateAnchor:SetParent(NP.db.units.PLAYER.useStaticPosition and _G.ElvNP_Player or nameplate)
			NP.PlayerNamePlateAnchor:SetAllPoints(NP.db.units.PLAYER.useStaticPosition and _G.ElvNP_Player or nameplate)
			NP.PlayerNamePlateAnchor:Show()
		elseif UnitIsPVPSanctuary(unit) or (nameplate.isPlayer and UnitIsFriend('player', unit) and nameplate.reaction and nameplate.reaction >= 5) then
			nameplate.frameType = 'FRIENDLY_PLAYER'
		elseif not nameplate.isPlayer and (nameplate.reaction and nameplate.reaction >= 5) or UnitFactionGroup(unit) == 'Neutral' then
			nameplate.frameType = 'FRIENDLY_NPC'
		elseif not nameplate.isPlayer and (nameplate.reaction and nameplate.reaction <= 4) then
			nameplate.frameType = 'ENEMY_NPC'
		else
			nameplate.frameType = 'ENEMY_PLAYER'
		end

		NP:UpdatePlate(nameplate)

		if nameplate.isTarget then
			NP:SetupTarget(nameplate)
			NP:ScalePlate(nameplate, NP.db.units.TARGET.scale, true)
		end

		if nameplate:IsShown() and NP.db.fadeIn then
			E:UIFrameFadeIn(nameplate, 1, 0, 1)
		end

		NP:StyleFilterUpdate(nameplate, event) -- keep this at the end
	elseif event == 'NAME_PLATE_UNIT_REMOVED' then
		NP:StyleFilterClear(nameplate) -- keep this at the top

		if nameplate.frameType == 'PLAYER' and nameplate ~= _G.ElvNP_Test then
			NP.PlayerNamePlateAnchor:Hide()
		end

		if nameplate.isTarget then
			NP:SetupTarget(nameplate, true)
			NP:ScalePlate(nameplate, 1, true)
		end

		NP:StyleFilterClearVariables(nameplate)
	elseif event == 'PLAYER_TARGET_CHANGED' then -- we need to check if nameplate exists in here
		NP:SetupTarget(nameplate) -- pass it, even as nil here
		NP:ScalePlate(nameplate, NP.db.units.TARGET.scale, true)
	end
end

function NP:ACTIVE_TALENT_GROUP_CHANGED()
	NP.PlayerRole = GetSpecializationRole(GetSpecialization())
end

local optionsTable = {'EnemyMinus','EnemyMinions','FriendlyMinions','PersonalResource','PersonalResourceOnEnemy','MotionDropDown'}
function NP:HideInterfaceOptions()
	for _, x in pairs(optionsTable) do
		local o = _G['InterfaceOptionsNamesPanelUnitNameplates'..x]
		o:SetSize(0.0001, 0.0001)
		o:SetAlpha(0)
		o:Hide()
	end
end

function NP:Initialize()
	NP.db = E.db.nameplates

	if E.private.nameplates.enable ~= true then return end
	NP.Initialized = true

	ElvUF:RegisterStyle('ElvNP', function(frame, unit) NP:Style(frame, unit) end)
	ElvUF:SetActiveStyle('ElvNP')

	NP.Plates = {}
	NP.StatusBars = {}
	NP.GroupRoles = {}

	local BlizzPlateManaBar = _G.NamePlateDriverFrame.classNamePlatePowerBar
	if BlizzPlateManaBar then
		BlizzPlateManaBar:Hide()
		BlizzPlateManaBar:UnregisterAllEvents()
	end

	hooksecurefunc(_G.NamePlateDriverFrame, 'SetupClassNameplateBars', function(frame)
		if frame.classNamePlateMechanicFrame then
			frame.classNamePlateMechanicFrame:Hide()
		end
		if frame.classNamePlatePowerBar then
			frame.classNamePlatePowerBar:Hide()
			frame.classNamePlatePowerBar:UnregisterAllEvents()
		end
	end)

	ElvUF:Spawn('player', 'ElvNP_Player')
	_G.ElvNP_Player:EnableMouse(true)
	_G.ElvNP_Player:RegisterForClicks('LeftButtonDown', 'RightButtonDown')
	_G.ElvNP_Player:SetAttribute('toggleForVehicle', true)
	_G.ElvNP_Player:Point('TOP', _G.UIParent, 'CENTER', 0, -150)
	_G.ElvNP_Player:Size(NP.db.clickableWidth, NP.db.clickableHeight)
	_G.ElvNP_Player:SetScale(1)
	_G.ElvNP_Player.frameType = 'PLAYER'
	E:CreateMover(_G.ElvNP_Player, 'ElvNP_PlayerMover', L["Player NamePlate"], nil, nil, nil, 'ALL,SOLO', nil, 'nameplate,playerGroup')

	ElvUF:Spawn('player', 'ElvNP_Test')
	_G.ElvNP_Test:Point('BOTTOM', _G.UIParent, 'BOTTOM', 0, 250)
	_G.ElvNP_Test:Size(NP.db.clickableWidth, NP.db.clickableHeight)
	_G.ElvNP_Test:SetScale(1)
	_G.ElvNP_Test:SetMovable(true)
	_G.ElvNP_Test:RegisterForDrag("LeftButton", "RightButton")
	_G.ElvNP_Test:SetScript("OnDragStart", function() _G.ElvNP_Test:StartMoving() end)
	_G.ElvNP_Test:SetScript("OnDragStop", function() _G.ElvNP_Test:StopMovingOrSizing() end)
	_G.ElvNP_Test.frameType = 'PLAYER'
	_G.ElvNP_Test:Disable()
	NP:DisablePlate(_G.ElvNP_Test)

	ElvUF:Spawn('player', 'ElvNP_TargetClassPower')
	_G.ElvNP_TargetClassPower:SetScale(1)
	_G.ElvNP_TargetClassPower:Size(NP.db.clickableWidth, NP.db.clickableHeight)
	_G.ElvNP_TargetClassPower.frameType = 'TARGET'
	_G.ElvNP_TargetClassPower:SetAttribute('toggleForVehicle', true)
	_G.ElvNP_TargetClassPower:Point('TOP', E.UIParent, 'BOTTOM', 0, -500)

	NP.PlayerNamePlateAnchor = CreateFrame("Frame", "ElvUIPlayerNamePlateAnchor", E.UIParent)
	NP.PlayerNamePlateAnchor:EnableMouse(false)
	NP.PlayerNamePlateAnchor:Hide()

	ElvUF:SpawnNamePlates('ElvNP_', function(nameplate, event, unit) NP:NamePlateCallBack(nameplate, event, unit) end)

	NP:RegisterEvent('PLAYER_REGEN_ENABLED')
	NP:RegisterEvent('PLAYER_REGEN_DISABLED')
	NP:RegisterEvent('PLAYER_ENTERING_WORLD')
	NP:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
	NP:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
	NP:RegisterEvent('GROUP_ROSTER_UPDATE')
	NP:RegisterEvent('GROUP_LEFT')
	NP:RegisterEvent('PLAYER_LOGOUT', NP.StyleFilterClearDefaults)

	NP:StyleFilterInitialize()
	NP:HideInterfaceOptions()
	NP:ACTIVE_TALENT_GROUP_CHANGED()
	NP:GROUP_ROSTER_UPDATE()
	NP:SetCVars()
	NP:ConfigureAll()
end

local function InitializeCallback()
	NP:Initialize()
end

E:RegisterModule(NP:GetName(), InitializeCallback)
