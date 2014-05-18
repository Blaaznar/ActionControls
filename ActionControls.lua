-----------------------------------------------------------------------------------------------
-- Client Lua Script for ActionControls
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
 
-----------------------------------------------------------------------------------------------
-- ActionControls Module Definition
-----------------------------------------------------------------------------------------------
local ActionControls = {
	_VERSION = 'ActionControls.lua 0.0.13',
	_URL     = '',
	_DESCRIPTION = 'Action control system for Wildstar'} 

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local KeyUtils
local LuaUtils

local EnumMouseLockingType =
{
	None = 0,
	MovementKeys = 1,
    PhisicalMovement = 2
}

-----------------------------------------------------------------------------------------------
-- Logging
-- TODO: Move to a class or use 3rd party logging lib
-----------------------------------------------------------------------------------------------
local logLevel = 3	
local log = {}
log.Debug = function (message) 
	if logLevel > 3 then
		Print("[ActionControls - Debug] : " .. tostring(message))
	end
end

log.Info = function (message) 
	if logLevel > 2 then
		Print("[ActionControls] : " .. tostring(message))
	end
end

log.Warn = function (message) 
	if logLevel > 1 then
		Print("[ActionControls - Warning] : " .. tostring(message))
	end
end

log.Error = function (message) 
	if logLevel > 0 then
		local strMessage = tostring(message)
	
		Print("[ActionControls - Error] : " .. strMessage)
		Apollo.AddAddonErrorText(self, strMessage)
	end
end
	

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ActionControls:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.playerPrevPosition = nil
	o.immediateMouseOverUnit = nil
	o.lastTargetUnit = nil
	o.isMouseOverTargetLocked = false
	o.isMouseBoundToActions = false
	o.boundKeys = {}
	o.boundKeys.mouseLockKeys = {}
	o.boundKeys.mouseLockToggleKeys = {}
	o.settings = {
		--logLevel = 4,
		mouseLockingType = EnumMouseLockingType.MovementKeys,
		mouseOverTargetLockKey = "Caps Lock"
	}
	
    return o
end

function ActionControls:Init()
	local bHasConfigureFunction = true
	local strConfigureButtonText = "Configure ActionControls"
	local tDependencies = {
		"Blaz:Lib:KeyUtils-0.2",
		"Blaz:Lib:LuaUtils-0.1"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
-----------------------------------------------------------------------------------------------
-- ActionControls OnLoad
-----------------------------------------------------------------------------------------------
function ActionControls:OnLoad()
	KeyUtils = Apollo.GetPackage("Blaz:Lib:KeyUtils-0.2").tPackage
	LuaUtils = Apollo.GetPackage("Blaz:Lib:LuaUtils-0.1").tPackage

    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("ActionControls.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function ActionControls:GetAsyncLoadStatus()
	return Apollo.AddonLoadStatus.Loaded
end

-----------------------------------------------------------------------------------------------
-- ActionControls OnDocLoaded
-----------------------------------------------------------------------------------------------
function ActionControls:OnDocLoaded()
	--log.Debug("OnDocLoaded()")
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ActionControlsForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
		
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		Apollo.RegisterSlashCommand("ac", "OnActionControlsOn", self)
		Apollo.RegisterSlashCommand("AC", "OnActionControlsOn", self)
		Apollo.RegisterSlashCommand("ActionControls", "OnActionControlsOn", self)
		Apollo.RegisterSlashCommand("ac-debug", "OnActionControlsOnDebug", self)
		
		-- Unlock triggers
		Apollo.RegisterEventHandler("Test_MouseReturnSignal", "OnGameDialogInteraction", self)
		
		Apollo.RegisterEventHandler("AbilityWindowHasBeenToggled", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("GenericEvent_ShowConfirmLeaveDisband", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("GenericEvent_ToggleGroupBag", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("Guild_WindowLoaded", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("GuildBankerOpen", "OnGameDialogInteraction", self) 
		Apollo.RegisterEventHandler("GuildRegistrarOpen", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("HousingBrokerOpen", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("HousingPanelControlOpen", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("InspectWindowHasBeenToggled", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("InvokeCraftingWindow", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("InvokeFriendsList", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("InvokeScientistExperimentation", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("InvokeSettlerBuild", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("InvokeShuttlePrompt", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("InvokeSoldierBuild", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("InvokeTaxiWindow", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("InvokeTradeskillTrainerWindow", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("InvokeVendorWindow", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("MailBoxActivate", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("MatchingGameReady", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("PlayerPathShow", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("PlayerPathShowWithData", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ResourceConversionOpen", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ShowBank", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ShowDye", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ShowInstanceGameModeDialog", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ShowQuestLog", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ShowResurrectDialog", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("Test_MouseReturnSignal", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleAbilitiesWindow", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleAchievementsFromHUD", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleAchievementWindow", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleAuctionWindow", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleChallengesWindow", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleCharacterWindow", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleCodex", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleGalacticArchiveWindow", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleGroupFinder", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleInventory", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleMailWindow", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleProgressLog", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleSocialWindow", "OnGameDialogInteraction", self)		
		Apollo.RegisterEventHandler("ToggleQuestLog", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleTradeskills", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("ToggleZoneMap", "OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("TradeskillEngravingStationOpen", "OnGameDialogInteraction", self)
		
		Apollo.RegisterEventHandler("DuelStateChanged",	"OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("MatchingGameReady",	"OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("PVPMatchFinished",	"OnGameDialogInteraction", self)
		Apollo.RegisterEventHandler("P2PTradeInvite",	"OnGameDialogInteraction", self)
				
		-- Lock triggers
		Apollo.RegisterEventHandler("SystemKeyDown", "OnSystemKeyDown", self) 
		Apollo.RegisterEventHandler("GameClickWorld", "OnGameClickWorld", self)
		Apollo.RegisterEventHandler("GameClickSky", "OnGameClickWorld", self)
		Apollo.RegisterEventHandler("GameClickUnit", "OnGameClickWorld", self)
		Apollo.RegisterEventHandler("GameClickProp", "OnGameClickWorld", self)
		
		Apollo.RegisterTimerHandler("DetectMovementTimer", "OnDetectMovementTimer", self)
		Apollo.CreateTimer("DetectMovementTimer", 0.05, false)
		Apollo.StopTimer("DetectMovementTimer")
		
		-- Targeting
		Apollo.RegisterEventHandler("MouseOverUnitChanged", "OnMouseOverUnitChanged", self)
		Apollo.RegisterTimerHandler("DelayedMouseOverTargetTimer", "OnDelayedMouseOverTargetTimer", self)
		Apollo.CreateTimer("DelayedMouseOverTargetTimer", 0.3, false)
		Apollo.StopTimer("DelayedMouseOverTargetTimer")
		self:SetMouseOverTargetLock(false)
		
		-- Keybinding events
		Apollo.RegisterEventHandler("KeyBindingKeyChanged", "OnKeyBindingKeyChanged", self)
		Apollo.RegisterEventHandler("KeyBindingUpdated", "OnKeyBindingUpdated", self)
		
		-- Additional Addon initialization
		self:ReadKeyBindings()
		
		self:InitializeDetection()
	end
end

-----------------------------------------------------------------------------------------------
-- Save/Restore user settings
-----------------------------------------------------------------------------------------------
function ActionControls:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then return end
	return self.settings	
end

function ActionControls:OnRestore(eType, t)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account
	or t == nil then
		return 
	end

	-- TODO: validation    
	table.ShallowMerge(t, self.settings)
end

-----------------------------------------------------------------------------------------------
-- ActionControls Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
-- on Configure button from Addons window
function ActionControls:OnConfigure()
	self:OnActionControlsOn()
end

-- on SlashCommand "/ac"
function ActionControls:OnActionControlsOn()
	self:OnShowOptionWindow()
end

-- on SlashCommand "/ac-debug"
function ActionControls:OnActionControlsOnDebug(param, pLogLevel)
	pLogLevel = tonumber(pLogLevel)

	if pLogLevel == nil then
		return
	end	

	if pLogLevel >= 0 and pLogLevel <= 4 then
		logLevel = pLogLevel
	else
		logLevel = 3
	end
end

-----------------------------------------------------------------------------------------------
-- Game keybindings
-----------------------------------------------------------------------------------------------

function ActionControls:ReadKeyBindings()
	--GameLib.CodeEnumInputAction
	local bindings = GameLib.GetKeyBindings();
	
	-- check if LMB is bound to any action
	self.isMouseBoundToActions = table.ExistsItem(bindings, 
		function (binding)
			return table.ExistsItem(binding.arInputs, 
				function (arInput) 
					return arInput.eDevice == 2 and arInput.nCode == 0 
				end) 
		end)
	
	--local bindingLAS2 = self:GetBindingByActionName(bindings, "LimitedActionSet2")
	--self.isMouseBoundToActions = 
	--	table.ExistsItem(bindingLAS1.arInputs, function (x) return x.eDevice == 2 and x.nCode == 0 end)
	--	or table.ExistsItem(bindingLAS2.arInputs, function (x) return x.eDevice == 2 and x.nCode == 0 end)
			
	self.boundKeys.mouseLockToggleKeys = {}
	table.insert(self.boundKeys.mouseLockToggleKeys, self:GetBoundCharsForAction(bindings, "ExplicitMouseLook"))
	--log.Debug(LuaUtils:DataDumper(self.boundKeys.mouseLockToggleKeys))

	self.boundKeys.mouseLockKeys = {}
	table.insert(self.boundKeys.mouseLockKeys, self:GetBoundCharsForAction(bindings, "MoveForward"))
	table.insert(self.boundKeys.mouseLockKeys, self:GetBoundCharsForAction(bindings, "DashForward"))
	table.insert(self.boundKeys.mouseLockKeys, self:GetBoundCharsForAction(bindings, "MoveBackward"))
	table.insert(self.boundKeys.mouseLockKeys, self:GetBoundCharsForAction(bindings, "DashBackward"))
	table.insert(self.boundKeys.mouseLockKeys, self:GetBoundCharsForAction(bindings, "DashLeft"))
	table.insert(self.boundKeys.mouseLockKeys, self:GetBoundCharsForAction(bindings, "StrafeLeft"))
	table.insert(self.boundKeys.mouseLockKeys, self:GetBoundCharsForAction(bindings, "TurnLeft"))
	table.insert(self.boundKeys.mouseLockKeys, self:GetBoundCharsForAction(bindings, "DashRight"))
	table.insert(self.boundKeys.mouseLockKeys, self:GetBoundCharsForAction(bindings, "StrafeRight"))
	table.insert(self.boundKeys.mouseLockKeys, self:GetBoundCharsForAction(bindings, "TurnRight"))	
	table.insert(self.boundKeys.mouseLockKeys, self:GetBoundCharsForAction(bindings, "Jump"))
	table.insert(self.boundKeys.mouseLockKeys, self:GetBoundCharsForAction(bindings, "ToggleAutoRun"))
	
	if self.boundKeys.mouseLockToggleKeys[1] ~= nil 
	or self.boundKeys.mouseLockToggleKeys[2] ~= nil then
		log.Debug("Toggle key mapped to " .. LuaUtils:DataDumper(self.boundKeys.mouseLockToggleKeys))
	else
		log.Info("Explicit Mouse Look keybinding is not set, to unlock press Esc key.")
	end
end

function ActionControls:GetBoundCharsForAction(bindings, actionName)
	local binding = self:GetBindingByActionName(bindings, actionName)

	if binding == nil then
		log.Debug("GetBoundCharsForAction(...) - no suitable bindings found for '" .. actionName .. "'")
		return nil
	end
	
	-- Cannot support key modifiers at this point	
	-- todo filtering by eDevice == 1 and eModifier == 0
	
	log.Debug("GetBoundCharsForAction(): " .. LuaUtils:DataDumper(binding))

	local boundChars = 	{	
		[1] = KeyUtils:KeybindNCodeToChar(binding.arInputs[1].nCode),
		[2] = KeyUtils:KeybindNCodeToChar(binding.arInputs[2].nCode)
	}
	
	return boundChars
end

function ActionControls:GetBindingByActionName(bindings, actionName)
	return table.FindItem(bindings, function(a) return a.strAction == actionName end)
end


function ActionControls:BindMouseButtons()
	if GameLib.GetPlayerUnit():IsInCombat() then
		log.Warn("In combat, changing bindings is not possible at this moment.")
		return
	end
	
	local bindings = GameLib.GetKeyBindings();

	if table.ExistsItem(bindings, 
		function (binding)
			return table.ExistsItem(binding.arInputs, 
				function (arInput) 
					return (arInput.eDevice == 2 and arInput.nCode == 0)
						or (arInput.eDevice == 2 and arInput.nCode == 1)
				end) 
		end) then
		log.Warn("Mouse buttons are already bound, please manualy unbind them from the game's Keybind window.")
		return
	end

	local lmbBinding = self:GetBindingByActionName(bindings, "LimitedActionSet1")
	lmbBinding.arInputs[2].eDevice = 2
	lmbBinding.arInputs[2].nCode = 0
	
	local rmbBinding = self:GetBindingByActionName(bindings, "LimitedActionSet2")
	rmbBinding.arInputs[2].eDevice = 2
	rmbBinding.arInputs[2].nCode = 1

	GameLib.SetKeyBindings(bindings)
	
	self.isMouseBoundToActions = true
	
	log.Debug("Left and right mouse buttons bound to 'Action 1' and 'Action 2'.")
end

function ActionControls:UnbindMouseButtons()
	if GameLib.GetPlayerUnit():IsInCombat() then
		log.Warn("In combat, changing bindings is not possible at this moment.")
		return
	end
	
	local bindings = GameLib.GetKeyBindings();
	
	local lmbBinding = self:GetBindingByActionName(bindings, "LimitedActionSet1")
	lmbBinding.arInputs[2].eDevice = 0
	lmbBinding.arInputs[2].nCode = 0
	
	local rmbBinding = self:GetBindingByActionName(bindings, "LimitedActionSet2")
	rmbBinding.arInputs[2].eDevice = 0
	rmbBinding.arInputs[2].nCode = 0

	GameLib.SetKeyBindings(bindings)
	
	self.isMouseBoundToActions = false	
	
	log.Debug("Left and right mouse buttons unbound from 'Action 1' and 'Action 2'.")
end

function ActionControls:OnKeyBindingKeyChanged(strKeybind)
	log.Debug("OnKeyBindingKeyChanged()")
	self:ReadKeyBindings()
end

function ActionControls:OnKeyBindingUpdated()
	log.Debug("OnKeyBindingUpdated()")
	self:ReadKeyBindings()
end

-----------------------------------------------------------------------------------------------
-- MouseLocking related functions
-----------------------------------------------------------------------------------------------
function ActionControls:InitializeDetection(lockState)
	if lockState == nil then lockState = GameLib.IsMouseLockOn() end
	
	self.playerPrevPosition = nil
	
	if lockState then
		Apollo.StopTimer("DetectMovementTimer")
		--log.Debug('timer stopped')
	elseif self.settings.mouseLockingType == EnumMouseLockingType.PhisicalMovement then
		Apollo.StartTimer("DetectMovementTimer")
		--log.Debug('timer started')
	end
end

function ActionControls:ToggleMouseLock()
	self:SetMouseLock(not GameLib.IsMouseLockOn())
end

function ActionControls:SetMouseLock(lockState) 
	--log.Debug("SetMouseLock(lockState) = " .. tostring(lockState))

	self:InitializeDetection(lockState)

	if lockState ~= GameLib.IsMouseLockOn() then
		self:SetMouseOverTargetLock(false)
		self:SetLastTarget()
				
		GameLib.SetMouseLock(lockState)

		-- Automatic remapping of LMB/RMB to action 1/2 on camera lock - Does not work in combat :(
		--if lockState then
		--	self:BindMouseButtons()
		--else
		--	self:UnbindMouseButtons()
		--end
	end
end

function ActionControls:OnSystemKeyDown(key)
	--log.Debug("OnSystemKeyDown(" .. key .. ")")
	--log.Debug(LuaUtils:DataDumper(self.settings))

	-- target locking
	if key == KeyUtils:CharToSysKeyCode(self.settings.mouseOverTargetLockKey) then
		if GameLib.GetTargetUnit() ~= nil then
			--log.Debug('target lock toggle')
			self:SetMouseOverTargetLock(not self:GetMouseOverTargetLock())
		else
			--log.Debug('target lock off')
			self:SetMouseOverTargetLock(false)
		end
	end

	-- toggle camera lock	
	for _,keys in ipairs(self.boundKeys.mouseLockToggleKeys) do
		if key == KeyUtils:CharToSysKeyCode(keys[1]) 
		or key == KeyUtils:CharToSysKeyCode(keys[2]) then
			--log.Debug("OnSystemKeyDown(" .. key .. ") - Manual toggle")
			self:ToggleMouseLock()
			return
		end
	end
	
	-- camera locking
	if self.settings.mouseLockingType == EnumMouseLockingType.PhisicalMovement 
		and key == KeyUtils:CharToSysKeyCode("Esc")
	then 
		log.Debug("OnSystemKeyDown(" .. key .. ") - ESC pressed, turning on movement timer")
		-- ESC directly executes GameLib.SetMouseLock(false), but that doesn't set the movement timer to on
		Apollo.StartTimer("DetectMovementTimer")
		return
	elseif self.settings.mouseLockingType == EnumMouseLockingType.MovementKeys then
		for _,keys in ipairs(self.boundKeys.mouseLockKeys) do
			if key == KeyUtils:CharToSysKeyCode(keys[1]) 
			or key == KeyUtils:CharToSysKeyCode(keys[2]) then
				--log.Debug("OnSystemKeyDown(" .. key .. ") - Manual movement lock")
				self:SetMouseLock(true)
				return
			end
		end
	end
end

function ActionControls:OnGameClickWorld(tPos)
	if GameLib.IsMouseLockOn() then
		GameLib.SetTargetUnit(self.lastTargetUnit)
		
		if not self.isMouseBoundToActions then
			self:SetMouseLock(false)
		end
	end
end

function ActionControls:OnGameDialogInteraction()
	-- TODO: Trigger only on window shown, not off
	log.Debug("OnGameDialogInteraction()")
	self:SetMouseLock(false)
end

-- Positional locking (phisical movement) - Thanks to Casstiel from Steer addon
function ActionControls:OnDetectMovementTimer(strVar, nValue)
	local position = self:GetPlayerPosition()
	local prevPosition = self.playerPrevPosition
	self.playerPrevPosition = position

	if not GameLib.IsMouseLockOn() and ActionControls:IsPlayerPositionChanged(position, prevPosition) then
		--log.Debug("OnDetectMovementTimer() - moving induced lock")
		self:SetMouseLock(true)
	elseif self.settings.mouseLockingType == EnumMouseLockingType.PhisicalMovement then
		Apollo.StartTimer("DetectMovementTimer")
	end
end

function ActionControls:GetPlayerPosition()
	local playerUnit = GameLib.GetPlayerUnit()
	
	if playerUnit == nil or not playerUnit:IsValid() then
		return nil
	end
	
	return playerUnit:GetPosition()
end

function ActionControls:IsPlayerPositionChanged(currentPosition, prevPosition)
	if currentPosition == nil or prevPosition == nil then
		return false
	end

	local delta = 0.1
	
	return not (math.abs(prevPosition.x-currentPosition.x) < delta and 
				math.abs(prevPosition.y-currentPosition.y) < delta and 
				math.abs(prevPosition.z-currentPosition.z) < delta)
end

--------------------------------------------------------------------------
-- MouseOver targeting
--------------------------------------------------------------------------
function ActionControls:OnMouseOverUnitChanged(unit)
	self.immediateMouseOverUnit = unit
	if unit == GameLib.GetTargetUnit() then
		-- same target
		return
	end
	
	if GameLib.GetTargetUnit() == nil then
		self:SetMouseOverTargetLock(false)
	end
	
	if GameLib.IsMouseLockOn() and unit ~= nil and not self:GetMouseOverTargetLock() then 
		Apollo.StopTimer("DelayedMouseOverTargetTimer")
		
		if GameLib.GetTargetUnit() == nil then
			self:SetTarget(unit)
		else
			Apollo.StartTimer("DelayedMouseOverTargetTimer")
		end
	end
end

function ActionControls:OnDelayedMouseOverTargetTimer(strVar, nValue)
	if GameLib.IsMouseLockOn() 
	    and self.immediateMouseOverUnit ~= nil 
	    and not self:GetMouseOverTargetLock() 
	    and self.immediateMouseOverUnit then 
		self:SetTarget(self.immediateMouseOverUnit)
	end
end

function ActionControls:SetTarget(unit)
	self:SetLastTarget(unit)
	GameLib.SetTargetUnit(unit)
end

function ActionControls:SetLastTarget(unit)
	if unit == nil then 
		unit = GameLib.GetTargetUnit() 
	end
	
 	self.lastTargetUnit = unit
end

-- Target locking
function ActionControls:SetMouseOverTargetLock(lockState)
	if lockState == self.isMouseOverTargetLocked then
		return
	end

	if not GameLib.IsMouseLockOn() or GameLib.GetTargetUnit() == nil then
		self.isMouseOverTargetLocked = false
		return
	end
	
	-- TODO: Visual representation of target lock on target unit frame (i.e. lock icon or outline)
	if lockState then
		log.Info("MouseOver target lock set on '" .. GameLib.GetTargetUnit():GetName() .. "'.")
	else
		log.Info("Removed target lock from '" .. GameLib.GetTargetUnit():GetName() .. "'.")
	end
	
	self.isMouseOverTargetLocked = lockState
end

function ActionControls:GetMouseOverTargetLock(lockState)
	if GameLib.GetTargetUnit() == nil then
		return false;
	end
		
	return self.isMouseOverTargetLocked;
end

-----------------------------------------------------------------------------------------------
-- ActionControlsForm Functions
-----------------------------------------------------------------------------------------------
function ActionControls:OnShowOptionWindow()
	self:SetMouseLock(false)
	
	self:OptionWindowPopulateFrom()
	
	self.wndMain:Invoke() -- show the window
	GameLib.PauseGameActionInput(true)
end

function ActionControls:OptionWindowPopulateFrom()
	self:ReadKeyBindings()
	
	self.isMouseBoundToActionsOption = self.isMouseBoundToActions
	
	self.userSettings = table.ShallowCopy(self.settings)

	self.wndMain:FindChild("RbKeyLocking"):SetCheck(self.userSettings.mouseLockingType == EnumMouseLockingType.MovementKeys)
	self.wndMain:FindChild("RbPositionLocking"):SetCheck(self.userSettings.mouseLockingType == EnumMouseLockingType.PhisicalMovement)
	self.wndMain:FindChild("RbDisabledLocking"):SetCheck(self.userSettings.mouseLockingType == EnumMouseLockingType.None)

	self.wndMain:FindChild("TbCameraLockKey"):SetText(tostring(self.boundKeys.mouseLockToggleKeys[1][1]))		
	self.wndMain:FindChild("TbTargetLockKey"):SetText(tostring(self.userSettings.mouseOverTargetLockKey))
	
	self:SetMouseBindButtonsState()
end

function ActionControls:SetMouseBindButtonsState()
	self.wndMain:FindChild("BindMouseButtons"):Enable(not self.isMouseBoundToActionsOption)
	self.wndMain:FindChild("UnBindMouseButtons"):Enable(self.isMouseBoundToActionsOption)
end

function ActionControls:OnRbKeyLockingCheck( wndHandler, wndControl, eMouseButton )
	log.Debug("OnKeyLockingChkButtonCheck")
	self.userSettings.mouseLockingType = EnumMouseLockingType.MovementKeys
end

function ActionControls:OnRbPositionLockingCheck( wndHandler, wndControl, eMouseButton )
	log.Debug("OnPositionLockingChkButtonCheck")
	self.userSettings.mouseLockingType = EnumMouseLockingType.PhisicalMovement
end

function ActionControls:OnRbDisabledLockingCheck( wndHandler, wndControl, eMouseButton )
	log.Debug("OnRbPositionLockingCheck")
	self.userSettings.mouseLockingType = EnumMouseLockingType.None
end

-- Binding keys
function ActionControls:OnBindMouseButtonsSignal( wndHandler, wndControl, eMouseButton )
	log.Debug("OnBindMouseButtonsSignal")
	
	self.isMouseBoundToActionsOption = true
	self:SetMouseBindButtonsState()
end

function ActionControls:OnUnBindMouseButtonsSignal( wndHandler, wndControl, eMouseButton )
	self.isMouseBoundToActionsOption = false
	self:SetMouseBindButtonsState()
end

function ActionControls:OnBindButtonSignal( wndHandler, wndControl, eMouseButton )
	log.Info("OnTbCameraLockKeyMouseButtonDown")
	self:OptionsBeginBinding(wndControl)
end

function ActionControls:OnBindWindowKeyDown( wndHandler, wndControl, strKeyName, nScanCode, nMetakeys )
	log.Info("OnTbCameraLockKeyWindowKeyDown")
	
	local key = self:OptionsProcessKey(wndHandler, strKeyName, nScanCode)
	log.Info("key: " .. tostring(key))

	self:OptionsEndBinding(wndControl)
end

function ActionControls:OptionsBeginBinding(wndControl)
	wndControl:SetCheck(true)
	wndControl:SetFocus()
end

function ActionControls:OptionsProcessKey(wndControl, strKeyName, nScanCode)
	log.Info(strKeyName)
	
	if strKeyName == "Esc" then
		return nil
	end
	
	return KeyUtils:KeybindNCodeToChar(nScanCode)
end

function ActionControls:OptionsEndBinding(wndControl)
	wndControl:SetCheck(false)
	wndControl:ClearFocus()
end

-- when the OK button is clicked
function ActionControls:OnOK()
	if self.isMouseBoundToActionsOption ~= self.isMouseBoundToActions then
		if GameLib.GetPlayerUnit():IsInCombat() then
			log.Warn("In combat, changing bindings is not possible at this moment.")
			return
		end
	
		if self.isMouseBoundToActionsOption then
			self:BindMouseButtons()
		else
			self:UnbindMouseButtons()
		end
	end
	
	-- use current settings
	self.settings = self.userSettings
	
	self:OnClose()
	
	self:InitializeDetection()
end

-- when the Cancel button is clicked
function ActionControls:OnCancel()
	-- discard current settings
	self.userSettings = nil
	
	self:OnClose()	
end

function ActionControls:OnClose()
	GameLib.PauseGameActionInput(false)
	self.wndMain:Close() -- hide the window
end

-----------------------------------------------------------------------------------------------
-- ActionControls Instance
-----------------------------------------------------------------------------------------------
local ActionControlsInst = ActionControls:new()
ActionControlsInst:Init()


