-----------------------------------------------------------------------------------------------
-- Client Lua Script for ActionControls
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
require "GameLib"

-----------------------------------------------------------------------------------------------
-- Packages
-----------------------------------------------------------------------------------------------
local KeyUtils = Apollo.GetPackage("Blaz:Lib:KeyUtils-0.2").tPackage
local LuaUtils = Apollo.GetPackage("Blaz:Lib:LuaUtils-0.1").tPackage
local SimpleLog = Apollo.GetPackage("Blaz:Lib:SimpleLog-0.1").tPackage

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local EnumMouseLockingType =
{
	None = 0,
	MovementKeys = 1
}
 
-----------------------------------------------------------------------------------------------
-- ActionControls Module Definition
-----------------------------------------------------------------------------------------------
local ActionControls = {} 

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ActionControls:new(logInst, keyUtilsInst)
    o = {}
    setmetatable(o, self)
    self.__index = self 

    -- variables
	o.log = logInst
	o.keyUtils = keyUtilsInst

	o.playerPrevPosition = nil
	o.immediateMouseOverUnit = nil
	o.lastTargetUnit = nil
	o.isMouseOverTargetLocked = false
	o.isMouseLmbBound = false
	o.isMouseRmbBound = false
	o.boundKeys = {}
	o.boundKeys.mouseLockToggleKeys = {}
	o.boundKeys.mouseLockTriggerKeys = {}

	o.settings = {
		mouseLockingType = EnumMouseLockingType.MovementKeys,
		mouseOverTargetLockKey = nil
	}
	
	o.model = {}
	
    return o
end

function ActionControls:Init()
	self.log:SetLogName("ActionControls")
	self.log:SetLogLevel(3)

	local bHasConfigureFunction = true
	local strConfigureButtonText = "Configure ActionControls"
	local tDependencies = {
		"Blaz:Lib:KeyUtils-0.2",
		"Blaz:Lib:LuaUtils-0.1",
		"Blaz:Lib:SimpleLog-0.1"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
-----------------------------------------------------------------------------------------------
-- ActionControls OnLoad
-----------------------------------------------------------------------------------------------
function ActionControls:OnLoad()
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
	--self.log:Debug("OnDocLoaded()")
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

	self:RestoreUserSettings(t)
end

function ActionControls:RestoreUserSettings(t)
	try(function ()
			local settings = table.ShallowCopy(self.settings)
			table.ShallowMerge(t, settings)
			-- TODO: validate settings
			self.settings = settings
		end,
		function (e)
			self.log:Error("Error while loading user settings. Default values will be used.")
		end)
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
function ActionControls:OnActionControlsOnDebug()
	self.log:SetLogLevel(4)
end

-----------------------------------------------------------------------------------------------
-- Game keybindings
-----------------------------------------------------------------------------------------------

function ActionControls:OnKeyBindingKeyChanged(strKeybind)
	self.log:Debug("OnKeyBindingKeyChanged()")
	self:ReadKeyBindings()
end

function ActionControls:OnKeyBindingUpdated()
	self.log:Debug("OnKeyBindingUpdated()")
	self:ReadKeyBindings()
end

function ActionControls:ReadKeyBindings()
	--GameLib.CodeEnumInputAction.
	local bindings = GameLib.GetKeyBindings();
	
	-- check if mouse buttons are bound to any action
	self.isMouseLmbBound = self.keyUtils:IsBound(2, 0, 0, bindings)
	self.isMouseRmbBound = self.keyUtils:IsBound(2, 0, 1, bindings)
	
	self.boundKeys.mouseLockToggleKeys = {
		self:GetBoundCharsForAction(bindings, "ExplicitMouseLook")
	}
	
	-- TODO: Pass a table with action names and get them all in one go
	self.boundKeys.mouseLockTriggerKeys = {
		self:GetBoundCharsForAction(bindings, "MoveForward"),
		self:GetBoundCharsForAction(bindings, "DashForward"),
		self:GetBoundCharsForAction(bindings, "MoveBackward"),
		self:GetBoundCharsForAction(bindings, "DashBackward"),
		self:GetBoundCharsForAction(bindings, "DashLeft"),
		self:GetBoundCharsForAction(bindings, "StrafeLeft"),
		self:GetBoundCharsForAction(bindings, "TurnLeft"),
		self:GetBoundCharsForAction(bindings, "DashRight"),
		self:GetBoundCharsForAction(bindings, "StrafeRight"),
		self:GetBoundCharsForAction(bindings, "TurnRight"),
		self:GetBoundCharsForAction(bindings, "Jump"),
		self:GetBoundCharsForAction(bindings, "ToggleAutoRun")
	}
	
	return bindings
end

function ActionControls:GetBoundCharsForAction(bindings, actionName)
	local binding = self.keyUtils:GetBindingByActionName(actionName, bindings)

	if binding == nil then
		self.log:Debug("GetBoundCharsForAction(...) - no suitable bindings found for '" .. actionName .. "'")
		return nil
	end
	
	-- Cannot support key modifiers at this point	
	-- todo filtering by eDevice == 1 and eModifier == 0
	
	self.log:Debug("GetBoundCharsForAction(): " .. LuaUtils:DataDumper(binding))

	local boundChars = 	{	
		[1] = self.keyUtils:KeybindNCodeToChar(binding.arInputs[1].nCode),
		[2] = self.keyUtils:KeybindNCodeToChar(binding.arInputs[2].nCode)
	}
	
	return boundChars
end

-----------------------------------------------------------------------------------------------
-- MouseLocking related functions
-----------------------------------------------------------------------------------------------
function ActionControls:InitializeDetection(lockState)
	if lockState == nil then lockState = GameLib.IsMouseLockOn() end
	
	self.playerPrevPosition = nil
end

function ActionControls:ToggleMouseLock()
	self:SetMouseLock(not GameLib.IsMouseLockOn())
end

function ActionControls:SetMouseLock(lockState) 
	--self.log:Debug("SetMouseLock(lockState) = " .. tostring(lockState))

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

function ActionControls:OnGameClickWorld(tPos)
	if GameLib.IsMouseLockOn() then
		GameLib.SetTargetUnit(self.lastTargetUnit)
		
		if not self.isMouseLmbBound then
			self:SetMouseLock(false)
		end
	end
end

function ActionControls:OnGameDialogInteraction()
	-- TODO: Trigger only on window shown, not off
	self.log:Debug("OnGameDialogInteraction()")
	self:SetMouseLock(false)
end

-------------------------------------------------------------------------------
-- Key processing
-------------------------------------------------------------------------------
function ActionControls:OnSystemKeyDown(key)
	--self.log:Debug("OnSystemKeyDown(" .. key .. ")")

	-- modifiers not supported yet
	if Apollo.IsShiftKeyDown() or Apollo.IsAltKeyDown() or Apollo.IsControlKeyDown() then
		return
	end

	-- stop processing keys if configuration or keybind windows are open
	--local keybindForm = Apollo.FindWindowByName("KeybindForm")	
	if (self.wndMain ~= nil and self.wndMain:IsVisible()) 
		--or (keybindForm ~= nil and keybindForm:IsVisible())
	then
		self:SetMouseLock(false)
		return
	end

	-- target locking
	if key == self.keyUtils:CharToSysKeyCode(self.settings.mouseOverTargetLockKey) then
		if GameLib.GetTargetUnit() ~= nil then
			--self.log:Debug('target lock toggle')
			self:SetMouseOverTargetLock(not self:GetMouseOverTargetLock())
		else
			--self.log:Debug('target lock off')
			self:SetMouseOverTargetLock(false)
		end
		return
	end

	-- camera lock toggle
	for _,keys in ipairs(self.boundKeys.mouseLockToggleKeys) do
		if key == self.keyUtils:CharToSysKeyCode(keys[1]) 
		or key == self.keyUtils:CharToSysKeyCode(keys[2]) then
			self.log:Debug("OnSystemKeyDown(" .. key .. ") - Manual toggle")
			self:ToggleMouseLock()
			return
		end
	end
	
	-- camera locking
	if self.settings.mouseLockingType == EnumMouseLockingType.MovementKeys then
		for _,keys in ipairs(self.boundKeys.mouseLockTriggerKeys) do
			if key == self.keyUtils:CharToSysKeyCode(keys[1]) 
			or key == self.keyUtils:CharToSysKeyCode(keys[2]) then
				self.log:Debug("OnSystemKeyDown(" .. key .. ") - Manual movement lock")
				self:SetMouseLock(true)
				return
			end
		end
	end
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

-- Delayed targeting
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

-- Preserves previous target information (clicking on game world to unlock the camera deselects the current target)
function ActionControls:SetLastTarget(unit)
	if unit == nil then 
		unit = GameLib.GetTargetUnit() 
	end
	
 	self.lastTargetUnit = unit
end

-----------------------------------------------------------------------------------------------
-- Target locking
-----------------------------------------------------------------------------------------------
function ActionControls:GetMouseOverTargetLock(lockState)
	if GameLib.GetTargetUnit() == nil then
		return false;
	end
		
	return self.isMouseOverTargetLocked;
end

function ActionControls:SetMouseOverTargetLock(lockState)
	if lockState == self.isMouseOverTargetLocked then
		return
	end

	if not GameLib.IsMouseLockOn() or GameLib.GetTargetUnit() == nil then
		self.isMouseOverTargetLocked = false
		return
	end
	
	self:DisplayLockState(lockState)
	
	self.isMouseOverTargetLocked = lockState
end

function ActionControls:DisplayLockState(lockState)
	-- TODO: Visual representation of target lock on target unit frame (i.e. lock icon or outline)
	if lockState then
		self.log:Info("MouseOver target lock set on '" .. GameLib.GetTargetUnit():GetName() .. "'.")
	else
		self.log:Info("Removed target lock from '" .. GameLib.GetTargetUnit():GetName() .. "'.")
	end
end

-----------------------------------------------------------------------------------------------
-- Options window functions
-----------------------------------------------------------------------------------------------
function ActionControls:OnShowOptionWindow()
	self:SetMouseLock(false)

	self:GenerateModel()
	self:GenerateView()

	GameLib.PauseGameActionInput(true)
	
	self.wndMain:Invoke() -- show the window
end

function ActionControls:GenerateModel()
	local bindings = self:ReadKeyBindings()
	
	self.model = {}
	self.model.settings = table.ShallowCopy(self.settings)
	self.model.explicitMouseLook = {} 
	self.model.bindingExplicitMouseLook = KeyUtils:GetBindingByActionName("ExplicitMouseLook", bindings)
	self.model.explicitMouseLook.nCode = self.model.bindingExplicitMouseLook.arInputs[1].nCode
	
	self.model.isMouseLmbBound = self.isMouseLmbBound
	if self.isMouseLmbBound then
		self.model.bindingLmb = KeyUtils:GetBinding(2, 0, 0, bindings)
	end
	
	self.model.isMouseRmbBound = self.isMouseRmbBound
	if self.isMouseRmbBound then
		self.model.bindingRmb = KeyUtils:GetBinding(2, 0, 1, bindings)
		self.model.rmbActionName = self.model.bindingRmb.strAction
	end
end

function ActionControls:GenerateView()
	self.wndMain:FindChild("RbKeyLocking"):SetCheck(self.model.settings.mouseLockingType == EnumMouseLockingType.MovementKeys)
	
	if self.model.explicitMouseLook.nCode ~= nil then
		self.wndMain:FindChild("BtnCameraLockKey"):SetText(tostring(self.keyUtils:KeybindNCodeToChar(self.model.explicitMouseLook.nCode)))	
	end

	self.wndMain:FindChild("BtnTargetLockKey"):SetText(tostring(self.model.settings.mouseOverTargetLockKey))
	
	self.wndMain:FindChild("BindMouseButtons"):Enable(not self.model.isMouseLmbBound)
	self.wndMain:FindChild("UnBindMouseButtons"):Enable(self.model.isMouseLmbBound)
end

---- Controller like functions
function ActionControls:OnRbKeyLockingCheck( wndHandler, wndControl, eMouseButton )
	self.model.settings.mouseLockingType = EnumMouseLockingType.MovementKeys
	self:GenerateView()
end

function ActionControls:OnRbKeyLockingUncheck( wndHandler, wndControl, eMouseButton )
	self.model.settings.mouseLockingType = EnumMouseLockingType.None
	self:GenerateView()
end

function ActionControls:OnBindMouseButtonsSignal( wndHandler, wndControl, eMouseButton )
	self.model.isMouseLmbBound = true
	self.model.rmbActionName = "DirectionalDash" -- TODO: split to other button
	
	self:GenerateView()
end

function ActionControls:OnUnBindMouseButtonsSignal( wndHandler, wndControl, eMouseButton )
	self.model.isMouseLmbBound = false
	self.model.isMouseRmbBound = false
	self:GenerateView()
end

-- Key capture
function ActionControls:SetBeginBindingState(wndControl)
	wndControl:SetCheck(true)
	wndControl:SetFocus()
end

function ActionControls:SetEndBindingState(wndControl)
	wndControl:SetCheck(false)
	wndControl:ClearFocus()
	self:GenerateView()
end

function ActionControls:OnBindButtonSignal( wndHandler, wndControl, eMouseButton )
	self:SetBeginBindingState(wndControl)
end

function ActionControls:OnBtnCameraLockKey_WindowKeyDown(wndHandler, wndControl, strKeyName, nScanCode, nMetakeys)
	if (not self:IsKeyAlreadyBound(1, 0, nScanCode)) then
		self.model.explicitMouseLook.eDevice = 1
		self.model.explicitMouseLook.eModifier = 0
		self.model.explicitMouseLook.nCode = nScanCode
	end		

	self:SetEndBindingState(wndControl)
end

function ActionControls:BtnTargetLockKey_WindowKeyDown( wndHandler, wndControl, strKeyName, nScanCode, nMetakeys )
	local isBound = self:IsKeyAlreadyBound(1, 0, nScanCode)
	
	if (not isBound) then
		self.model.settings.mouseOverTargetLockKey = self.keyUtils:KeybindNCodeToChar(nScanCode)
	end
	
	self:SetEndBindingState(wndControl)
end

function ActionControls:IsKeyAlreadyBound(eDevice, eModifier, nCode)
	local key = self.keyUtils:KeybindNCodeToChar(nCode)
	if strKeyName == "Esc" then
		return true
	end
	
	if key == nil then return false end -- ????????????????
	
	if self.model.settings.mouseOverTargetLockKey == key then
		return true
	end

	-- should this be executed, I can just overwrite existing bindings?
	local isBound, binding = try(
		function ()
			local isBound = self.keyUtils:IsBound(eDevice, eModifier, nCode)
			if isBound then
				local existingBinding = self.keyUtils:GetBinding(eDevice, eModifier, nCode)
				self.log:Info("Key '" .. tostring(key) .. "' is already bound to '" .. tostring(existingBinding.strActionLocalized) .. "'")
				return 
					true,
					existingBinding
			end
		end,
		function (e)
			self.log:Error(e)
		end)
	
	return isBound
end

-- when the OK button is clicked
function ActionControls:OnOK()
	try(function ()		
			local bindings = GameLib.GetKeyBindings()

			if self.model.isMouseLmbBound ~= self.isMouseLmbBound then
				if self.model.isMouseLmbBound then
					self:BindLmbMouseButton(bindings)
				end
				if self.model.isMouseRmbBound then
					self:BindRmbMouseButton(bindings, self.model.rmbActionName)
				end
				
				if not self.model.isMouseLmbBound and not self.model.isMouseRmbBound then
					self:UnbindMouseButtons(bindings)
				end
			end
			
			if self.model.explicitMouseLook.nCode ~= nil then
				local key = self.model.explicitMouseLook
				self.keyUtils:Bind("ExplicitMouseLook", 
					1, 
					1, --key.eDevice, 
					0, --key.eModifier, 
					key.nCode, 
					true,
					bindings)
			end
			
			self.keyUtils:CommitBindings(bindings)
			
			-- use current settings
			self.settings = self.model.settings
			
			self:OnClose()
			
			self:InitializeDetection()
		end,
		function(e)
			self.log:Error(e)
		end)
end

-- Binding
function ActionControls:BindLmbMouseButton(bindings)
	self.keyUtils:Bind("LimitedActionSet1", 2, 2, 0, 0, true, bindings)
	self.isMouseLmbBound = true
	
	self.log:Debug("Left mouse button bound to 'Action 1'.")
end

function ActionControls:BindRmbMouseButton(bindings, actionName)
	self.keyUtils:Bind(actionName, 2, 2, 0, 1, true, bindings)
	self.isMouseRmbBound = true
	
	self.log:Debug("Right mouse button bound to 'Directional dash'.")
end

function ActionControls:UnbindMouseButtons(bindings)
	self.keyUtils:UnbindByInput(2, 0, 0, bindings) -- LMB
	self.keyUtils:UnbindByInput(2, 0, 1, bindings) -- RMB
	
	self.isMouseLmbBound = false
	self.isMouseRmbBound = false
	
	self.log:Debug("Left and right mouse buttons unbound.")
end


-- when the Cancel button is clicked
function ActionControls:OnCancel()
	-- discard current settings
	self.model.settings = nil
	
	self:OnClose()	
end

function ActionControls:OnClose()
	GameLib.PauseGameActionInput(false)
	self.wndMain:Close() -- hide the window
end

-----------------------------------------------------------------------------------------------
-- ActionControls Instance
-----------------------------------------------------------------------------------------------
local logInst = SimpleLog:new()
local keyUtilsInst = KeyUtils:new(logInst)

local actionControlsInst = ActionControls:new(logInst, keyUtilsInst)

actionControlsInst:Init()

