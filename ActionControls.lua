-----------------------------------------------------------------------------------------------
-- Client Lua Script for ActionControls
-- Copyright (c) NCsoft. All rights reserved
-- 
-- Notes: I'm agressively getting keybindings as the events for bindings changed don't work
-- correctly, once Carbine fixes this bindings will be cached locally
-----------------------------------------------------------------------------------------------
require "Window"
require "GameLib"

-----------------------------------------------------------------------------------------------
-- Packages
-----------------------------------------------------------------------------------------------
local KeyBindingUtils = Apollo.GetPackage("Blaz:Lib:KeyBindingUtils-0.2").tPackage
local LuaUtils = Apollo.GetPackage("Blaz:Lib:LuaUtils-0.1").tPackage
local SimpleLog = Apollo.GetPackage("Blaz:Lib:SimpleLog-0.1").tPackage
local InputKey = Apollo.GetPackage("Blaz:Lib:InputKey-0.1").tPackage

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local EnumMouseLockingType =
{
    None = 0,
    MovementKeys = 1
}

local EnumInCombatTargetingMode = 
{
	None = 0,
	Hostile = 1,
	Friendly = 2
}

local EnumInputKeys =
{
    None = InputKey:newFromKeyParams(0, 0, 0),
    Esc = InputKey:newFromKeyParams(1, 0, 1),
    LMB = InputKey:newFromKeyParams(2, 0, 0),
    RMB = InputKey:newFromKeyParams(2, 0, 1)
}

-- extra windows that should prevent turning mouselook on
local blockingWindowNames =
{
	"NeedVsGreedForm"
}
 
-----------------------------------------------------------------------------------------------
-- ActionControls Module Definition
-----------------------------------------------------------------------------------------------
local ActionControls = {} 

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ActionControls:new(o, logInst, keyBindingUtilsInst)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- variables
    o.log = logInst
    o.keyBindingUtils = keyBindingUtilsInst
    
    o.immediateMouseOverUnit = nil
    o.lastTargetUnit = nil
    o.isTargetLocked = false
    o.isMouseLmbBound = false
    o.isMouseRmbBound = false
    o.boundKeys = {}
    o.boundKeys.mouseLockToggleKeys = {}
    o.boundKeys.mouseLockTriggerKeys = {}
    o.boundKeys.sprintingModifier = {}

    o.settings = {
        mouseLockingType = EnumMouseLockingType.MovementKeys,
        mouseOverTargetLockKey = EnumInputKeys.None,
        
        mouseLmbActionName = "LimitedActionSet1",
        mouseRmbActionName = "DirectionalDash",

		inCombatTargetingMode = EnumInCombatTargetingMode.None,

		-- experimental
		automaticMouseBinding = false
    }
    
    o.bindings = nil
    
    o.model = {}
    
    return o
end

function ActionControls:Init()
    self.log:SetLogName("ActionControls")
    self.log:SetLogLevel(3)

    local bHasConfigureFunction = true
    local strConfigureButtonText = "Action Controls"
    local tDependencies = {
        "Blaz:Lib:KeyBindingUtils-0.2",
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
	if g_ActionBarLoaded then
		self:InitializeEvents() -- Delay event registering until Carbine UI is done jumping about
		return Apollo.AddonLoadStatus.Loaded
	end
	return Apollo.AddonLoadStatus.Loading
end

-----------------------------------------------------------------------------------------------
-- ActionControls OnDocLoaded
-----------------------------------------------------------------------------------------------
function ActionControls:OnDocLoaded()
    if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
        self.wndMain = Apollo.LoadForm(self.xmlDoc, "ActionControlsForm", nil, self)
		self.wndCrosshair = Apollo.LoadForm(self.xmlDoc, "CrosshairForm", "InWorldHudStratum", self)
				
        if self.wndMain == nil then
            Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
            return
        end

		self.wndTargetLock = Apollo.LoadForm(self.xmlDoc, "TargetLockForm", nil, self)
        if self.wndTargetLock == nil then
            Apollo.AddAddonErrorText(self, "Could not load the target lock window for some reason.")
            return
        end

		if self.wndCrosshair == nil then
            Apollo.AddAddonErrorText(self, "Could not load crosshair window for some reason.")
            return
		else
			self.wndCrosshair:SetOpacity(0.5)
        end
        
        self.wndMain:Show(false, true)
        self.wndTargetLock:Show(false, true)
		self.wndCrosshair:Show(false, true)
        
        -- if the xmlDoc is no longer needed, you should set it to nil
        -- self.xmlDoc = nil
        
        -- Register handlers for events, slash commands and timer, etc.
        Apollo.RegisterSlashCommand("ac", "OnActionControlsOn", self)
        Apollo.RegisterSlashCommand("AC", "OnActionControlsOn", self)
        Apollo.RegisterSlashCommand("ActionControls", "OnActionControlsOn", self)
        Apollo.RegisterSlashCommand("ac-debug", "OnActionControlsOnDebug", self)
        
        -- Additional Addon initialization
        self:ReadKeyBindings()
        self:SetTargetLock(false)        
        self:SetMouseLock(false)
    end
end

function ActionControls:InitializeEvents()
        -- Unlock triggers - general unlocking
        self:RegisterEvents("OnGameDialogInteraction", 
            "Test_MouseReturnSignal",
            "AbilityWindowHasBeenToggled",
            "GenericEvent_ShowConfirmLeaveDisband",
            "GenericEvent_ToggleGroupBag",
            "Guild_WindowLoaded",
            "GuildBankerOpen", "GuildBankerClose", 
            "GuildRegistrarOpen", "GuildRegistrarClose",
            "HousingBrokerOpen", "HousingBrokerClose",
            "HousingPanelControlOpen", "HousingPanelControlClose",
            "InspectWindowHasBeenToggled",
            "InvokeCraftingWindow", "CloseCraftingWindow",
            "InvokeFriendsList",
            "InvokeScientistExperimentation",
            "InvokeSettlerBuild", "SettlerHubClose",
            "InvokeShuttlePrompt",
            "InvokeSoldierBuild",
            "InvokeTaxiWindow", "TaxiWindowClose",
            "InvokeTradeskillTrainerWindow", "CloseTradeskillTrainerWindow",
            "InvokeVendorWindow", "CloseVendorWindow",
            "MailBoxActivate", "MailWindowHasBeenClosed",
            "MatchingGameReady",
            "PlayerPathShow",
            "PlayerPathShowWithData",
            "ResourceConversionOpen", "ResourceConversionClose",
            "ShowBank", "HideBank",
            "ShowDye", "HideDye",
            "ShowInstanceGameModeDialog",
            "ShowQuestLog",
            "ShowResurrectDialog", "CharacterCreated",
            "Test_MouseReturnSignal",
            "ToggleAbilitiesWindow",
            "ToggleAchievementsFromHUD",
            "ToggleAchievementWindow",
            "ToggleAuctionWindow",
            "ToggleChallengesWindow",
            "ToggleCharacterWindow",
            "ToggleCodex",
			"ToggleMarketplaceWindow",
            "ToggleGalacticArchiveWindow",
            "ToggleGroupFinder",
            "ToggleInventory",
            "ToggleMailWindow",
            "ToggleProgressLog",
            "ToggleSocialWindow",        
            "ToggleQuestLog",
            "ToggleTradeskills",
            "ToggleZoneMap",
            "TradeskillEngravingStationOpen", "TradeskillEngravingStationClose",

            "DuelStateChanged",
            "MatchingGameReady",
            "PVPMatchFinished",
            "P2PTradeInvite",
            "ProgressClickWindowDisplay",
            "ShowActionBarShortcut")

        -- Mouse look triggers
        Apollo.RegisterEventHandler("SystemKeyDown", "OnSystemKeyDown", self) 
        Apollo.RegisterEventHandler("GameClickWorld", "OnGameClickWorld", self)
        Apollo.RegisterEventHandler("GameClickSky", "OnGameClickWorld", self)
        Apollo.RegisterEventHandler("GameClickUnit", "OnGameClickWorld", self)
        Apollo.RegisterEventHandler("GameClickProp", "OnGameClickWorld", self)
        
        -- Targeting
        Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
        Apollo.RegisterEventHandler("MouseOverUnitChanged", "OnMouseOverUnitChanged", self)
        Apollo.RegisterTimerHandler("DelayedMouseOverTargetTimer", "OnDelayedMouseOverTargetTimer", self)
        Apollo.CreateTimer("DelayedMouseOverTargetTimer", 0.2, false)
        Apollo.StopTimer("DelayedMouseOverTargetTimer")

		-- Target lock
		Apollo.RegisterTimerHandler("DelayedMouseLockToggleTimer", "OnDelayedMouseLockToggleTimer", self)
        Apollo.CreateTimer("DelayedMouseLockToggleTimer", 0.1, false) -- Hack for getting the right window shown state
        Apollo.StopTimer("DelayedMouseLockToggleTimer")
        
        -- Keybinding events
        Apollo.RegisterEventHandler("KeyBindingKeyChanged", "OnKeyBindingKeyChanged", self)
        Apollo.RegisterEventHandler("KeyBindingUpdated", "OnKeyBindingUpdated", self)
end

function ActionControls:RegisterEvents(strFunction, ...)
    for _,strEvent in ipairs(arg) do
        Apollo.RegisterEventHandler(strEvent, strFunction, self)
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
            
            local key = settings.mouseOverTargetLockKey
            settings.mouseOverTargetLockKey = InputKey:newFromKeyParams(key.eDevice, key.eModifier, key.nCode)
            
			-- validation
            assert(GameLib.GetKeyBinding(self.settings.mouseLmbActionName))
			assert(GameLib.GetKeyBinding(self.settings.mouseRmbActionName))
            assert(settings.mouseOverTargetLockKey.strKey ~= "")
            
            self.settings = settings
        end,
        function (e)
            self.log:Error("Error while loading user settings. Default values will be used.")
			Apollo.AddAddonErrorText(self, tostring(e))
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

    -- if I'm caching bindings locally, refresh them
    if self.bindings ~= nil then
        self.bindings = bindings
    end
    
    -- check if mouse buttons are bound to any action
    self.isMouseLmbBound = self.keyBindingUtils:IsBound(bindings, EnumInputKeys.LMB)
    self.isMouseRmbBound = self.keyBindingUtils:IsBound(bindings, EnumInputKeys.RMB)
    self.isMouseBound = self.isMouseLmbBound or self.isMouseRmbBound or self.settings.automaticMouseBinding

    self.boundKeys.mouseLockToggleKeys = self:GetBoundKeysForAction(bindings, "ExplicitMouseLook")
    
    self.boundKeys.mouseLockTriggerKeys = self:GetBoundKeysForAction(bindings, 
			"MoveForward", 
			"DashForward", 
			"MoveBackward", 
			"DashBackward", 
			"DashLeft", 
			"StrafeLeft", 
			"TurnLeft", 
			"DashRight", 
			"StrafeRight", 
			"TurnRight", 
			"Jump", 
			"ToggleAutoRun",
			"SprintModifier")
   
    return bindings
end

function ActionControls:GetBoundKeysForAction(bindings, ...)
    local foundBindings = self.keyBindingUtils:GetBindingListByActionNames(bindings, unpack(arg))
	
    if foundBindings == nil or table.getn(foundBindings) == 0 then
        self.log:Debug("GetBoundCharsForAction(...) - no bindings found.")
        return nil
    end
    
    -- self.log:Debug("GetBoundCharsForAction(): " .. LuaUtils:DataDumper(binding))
	local boundKeys = {}
	for _, binding in ipairs(foundBindings) do
		for j, arInput in ipairs(binding.arInputs) do
			if j > 2 then break end
			
			-- can support only keyboard for now
			if arInput.eDevice == 1 then
                local retVal = InputKey:newFromArInput(arInput)
                
				table.insert(boundKeys, retVal)
			end
		end
	end
	    
    return boundKeys
end

-------------------------------------------------------------------------------
-- Key press processing
-------------------------------------------------------------------------------
function ActionControls:OnSystemKeyDown(sysKeyCode)
    -- stop processing keys if configuration window is open
    if (self.wndMain ~= nil and self.wndMain:IsVisible()) 
    then
        self:SetMouseLock(false)
        return
    end

    local inputKey = InputKey:newFromSysKeyCode(sysKeyCode)
    
    if inputKey.strKey == "" or inputKey.nCode == 0 then
        self.log:Debug("Unknown key code (%s), please report it to addon author.", sysKeyCode)
        return
    --else self.log:Info("OnSystemKeyDown(%s): %s", sysKeyCode, tostring(inputKey))
    end
    
	-- Esc key cleanups
	if inputKey == EnumInputKeys.Esc then
		if self.settings.automaticMouseBinding then
			self:AutoBinding(false)
            self:HideCrosshair()
		end
        return
	end

    -- target locking
	if inputKey == self.settings.mouseOverTargetLockKey 
    then
        if GameLib.GetTargetUnit() ~= nil then
            self:SetTargetLock(not self:GetTargetLock())
        else
            self:SetTargetLock(false)
        end
        return
    end

    -- mouse look toggle
    for _,key in ipairs(self.boundKeys.mouseLockToggleKeys) do
        if inputKey == key then
            self.log:Debug("OnSystemKeyDown(%s) - Manual toggle", sysKeyCode)
            self:ToggleMouseLock()
            return
        end
    end
    
    -- automatic camera locking
    if self.settings.mouseLockingType == EnumMouseLockingType.MovementKeys 
		and not GameLib.IsMouseLockOn()
    then
        for _,key in ipairs(self.boundKeys.mouseLockTriggerKeys) do
            if inputKey == key then
				if self:IsBlockingWindowOpen() then
					return
				end
				
                self.log:Debug("OnSystemKeyDown(%s:'%s') - Manual movement lock", sysKeyCode, key.strKey)
                self:SetMouseLock(true)
                return
            end
        end
    end
end

-----------------------------------------------------------------------------------------------
-- MouseLocking functions
-----------------------------------------------------------------------------------------------
function ActionControls:ToggleMouseLock()
    self:SetMouseLock(not GameLib.IsMouseLockOn())
end

function ActionControls:SetMouseLock(lockState) 
    if lockState ~= GameLib.IsMouseLockOn() then
        self:SetLastTarget()

		if lockState then
			self:ShowCrosshair()
		else
			self:HideCrosshair()
		end
        
        -- EXPERIMENTAL --
        -- Automatic remapping of LMB/RMB to action 1/2 on camera lock - Does not work in combat :(
        if self.settings.automaticMouseBinding then
            try(function()
					local playerUnit = GameLib.GetPlayerUnit()
					
					if playerUnit ~= nil then
	                    if playerUnit:IsInCombat() then
	                        self.log:Error("In combat, changing bindings is not possible at this moment.")
	                    else                    
	                        self:AutoBinding(lockState)
	                    end
					end
	            end,
                function(e)
                    self.log:Error(e)
                end)
        end
        
        GameLib.SetMouseLock(lockState)
    end
end

function ActionControls:IsBlockingWindowOpen()
    if CSIsLib.IsCSIRunning() then
        return true
    end

	for _,strata in ipairs(Apollo.GetStrata()) do -- thanks to Xeurian for finding this function!
		for _,window in ipairs(Apollo.GetWindowsInStratum(strata)) do
			if window:IsStyleOn("Escapable") 
            and not window:IsStyleOn("CloseOnExternalClick") 
            then
				if window:IsShown() or window:IsVisible() then
		            self.log:Debug("Automatic mouse look blocked by '%s': ", window:GetName())
		            return true
		        end
			end
			
			local windowName = window:GetName()
			
			for _,w in ipairs(blockingWindowNames) do
				if w == windowName and otherWin:IsVisible() then
					return true
				end
			end
		end
	end
    
    return false
end

-------------------------------------------------------------------------------
-- EXPERIMENTAL - AutoBinding
-------------------------------------------------------------------------------
function ActionControls:AutoBinding(bindState)
    --if self.bindings == nil then 
    -- APOLLO_BUG: Game doesn't correctly notify of bindings changing when only secondary bindings have been changed, so if I cache the bindings I'll end up overwriting changes made to game's keybindings.
    -- BUG2: Binding keys while turning on mouselook and holding down LMB will lock the mouselook and Apollo.SetMouseLock(false) will not work untill Esc key is pressed
        self.bindings = self:ReadKeyBindings()
	--end
    
	if bindState then
		self:BindLmbMouseButton(self.bindings, self.settings.mouseLmbActionName)
	    self:BindRmbMouseButton(self.bindings, self.settings.mouseRmbActionName)
	    self.isMouseLmbBound = true
	    self.isMouseRmbBound = true
	else
		self:UnbindMouseButtons(self.bindings)
	    self.isMouseLmbBound = false
	    self.isMouseRmbBound = false
	end
	
	self.keyBindingUtils:CommitBindings(self.bindings)
end

-----------------------------------------------------------------------------------------------
-- World Click functions
-----------------------------------------------------------------------------------------------
function ActionControls:OnGameClickWorld(param)
    self.log:Debug("OnGameClickWorld/Unit(%s)", tostring(param))
    
    if GameLib.IsMouseLockOn() then
        -- reselect units targeted before the mouse click
        GameLib.SetTargetUnit(self.lastTargetUnit)
        self:SetTargetLock(self.isLastTargetLocked)

        if not self.isMouseBound then
            self:SetMouseLock(false)
        end
    end
end

-- Preserves previous target information (clicking on game world to unlock the camera deselects the current target)
function ActionControls:SetLastTarget(unit)
    if unit == nil then 
        unit = GameLib.GetTargetUnit() 
    end
    
    self.lastTargetUnit = unit
end

-- Preserves previous target lock information (clicking on game world to unlock the camera deselects the current target)
function ActionControls:SetLastTargetLock(lockState)
    if self.lastTargetUnit == GameLib.GetTargetUnit() then
        self.isLastTargetLocked = self.isTargetLocked
    end
end

-----------------------------------------------------------------------------------------------
-- Game Dialogs
-----------------------------------------------------------------------------------------------

function ActionControls:OnGameDialogInteraction()
    self.log:Debug("OnGameDialogInteraction()")

    Apollo.StartTimer("DelayedMouseLockToggleTimer")
end

function ActionControls:OnDelayedMouseLockToggleTimer()
	self.log:Debug("OnDelayedMouseLockToggleTimer()")
	
	if self:IsBlockingWindowOpen() then
		self:SetMouseLock(false)
	elseif self.settings.mouseLockingType ~= EnumMouseLockingType.None then
		self:SetMouseLock(true)
	end
end

--------------------------------------------------------------------------
-- Targeting
--------------------------------------------------------------------------
function ActionControls:OnMouseOverUnitChanged(unit)
    self.immediateMouseOverUnit = unit
    
    if not self:IsInCombatTargetingAllowed(unit) then
		return
    end
    
    if unit == nil
       or unit == GameLib.GetTargetUnit() -- same target
       or unit:IsDead() -- dead target
    then
        return
    end
    
    if GameLib.IsMouseLockOn() and unit ~= nil and not self:GetTargetLock() then 
        Apollo.StopTimer("DelayedMouseOverTargetTimer")
        
        if GameLib.GetTargetUnit() == nil then
            self:SetTarget(unit)
        else
            Apollo.StartTimer("DelayedMouseOverTargetTimer")
        end
    end
end

function ActionControls:IsInCombatTargetingAllowed(unit)
	if self.settings.inCombatTargetingMode == EnumInCombatTargetingMode.None then
		return true
	end
	
    if unit ~= nil then
        local player = GameLib.GetPlayerUnit()
        local disposition = unit:GetDispositionTo(player)
        
        if player:IsInCombat() then
			if (self.settings.inCombatTargetingMode == EnumInCombatTargetingMode.Hostile
				and (disposition == Unit.CodeEnumDisposition.Hostile or dispositionTo == Unit.CodeEnumDisposition.Neutral))
			or (self.settings.inCombatTargetingMode == EnumInCombatTargetingMode.Friendly
				and disposition == Unit.CodeEnumDisposition.Friendly)
			then
				self.log:Debug("InCombat, mouseover target allowed.")
				return true
			else
				self.log:Debug("InCombat, mouseover target NOT allowed.") 
				return false
			end	
       	end
	end
	
	return true
end

-- Delayed targeting
function ActionControls:OnDelayedMouseOverTargetTimer(strVar, nValue)
    if GameLib.IsMouseLockOn() 
        and self.immediateMouseOverUnit ~= nil 
        and not self:GetTargetLock() 
        and self.immediateMouseOverUnit then 
        self:SetTarget(self.immediateMouseOverUnit)
    end
end

function ActionControls:SetTarget(unit)
    self:SetLastTarget(unit)
    GameLib.SetTargetUnit(unit)
end

-----------------------------------------------------------------------------------------------
-- Target locking
-----------------------------------------------------------------------------------------------
function ActionControls:OnTargetUnitChanged(unit)
    self:SetTargetLock(false)
end

function ActionControls:GetTargetLock()
    if GameLib.GetTargetUnit() == nil then
        return false;
    end
        
    return self.isTargetLocked;
end

function ActionControls:SetTargetLock(lockState)
    if lockState == self.isTargetLocked then
        return
    end
    
    self:DisplayLockState(lockState)
    self.isTargetLocked = lockState
    
    self:SetLastTargetLock(lockState)
    
    -- after unlocking reselect the current mouseover target if it exists
    if lockState == false and self.immediateMouseOverUnit ~= nil then
        Apollo.StartTimer("DelayedMouseOverTargetTimer")
    end
end

function ActionControls:DisplayLockState(lockState)
    if lockState then
        self.wndTargetForm = self.wndTargetForm or Apollo.FindWindowByName("ClusterTargetFlipped")
        if self.wndTargetForm == nil then
            return
        end
        
		self.wndTargetLock:SetAnchorPoints(self.wndTargetForm:GetAnchorPoints())
		self.wndTargetLock:SetAnchorOffsets(self.wndTargetForm:GetAnchorOffsets())
    
		self.wndTargetLock:Show(true, true)
		--self.log:Info("MouseOver target lock set on <%s>", tostring(GameLib.GetTargetUnit():GetName()))
    else
		self.wndTargetLock:Close()
        --self.log:Info("Removed target lock from <%s>", tostring(GameLib.GetTargetUnit():GetName()))
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
    self.model.bindingsChanged = false
    
    self.model.settings = table.ShallowCopy(self.settings)
    self.model.explicitMouseLook = {} 
    self.model.bindingExplicitMouseLook = self.keyBindingUtils:GetBindingByActionName(bindings, "ExplicitMouseLook")
    self.model.explicitMouseLook = InputKey:newFromArInput(self.model.bindingExplicitMouseLook.arInputs[1])

	self.model.isMouseBound = self.isMouseLmbBound or self.isMouseRmbBound or self.settings.automaticMouseBinding

    if self.isMouseBound then
        self.model.rmbActionName = "DirectionalDash"
    end

	self.model.settings.automaticMouseBinding = self.settings.automaticMouseBinding
end

function ActionControls:GenerateView()
    self.wndMain:FindChild("RbKeyLocking"):SetCheck(self.model.settings.mouseLockingType == EnumMouseLockingType.MovementKeys)
    
    if self.model.explicitMouseLook.nCode ~= nil then
        self.wndMain:FindChild("BtnCameraLockKey"):SetText(tostring(self.model.explicitMouseLook))   
    end

    self.wndMain:FindChild("BtnTargetLockKey"):SetText(tostring(self.model.settings.mouseOverTargetLockKey))
    
    self.wndMain:FindChild("BtnBindMouseButtons"):SetCheck(self.model.isMouseBound)
    
    self.wndMain:FindChild("BtnAutoBindMouseButtons"):Enable(self.model.isMouseBound)
    self.wndMain:FindChild("BtnAutoBindMouseButtons"):SetCheck(self.model.settings.automaticMouseBinding)

	self.wndMain:FindChild("ChkInCombatTargetingMode"):SetCheck(self.model.settings.inCombatTargetingMode ~= EnumInCombatTargetingMode.None)
	self.wndMain:FindChild("RbInCombatTargetingFriendly"):Enable(self.model.settings.inCombatTargetingMode ~= EnumInCombatTargetingMode.None)
	self.wndMain:FindChild("RbInCombatTargetingHostile"):Enable(self.model.settings.inCombatTargetingMode ~= EnumInCombatTargetingMode.None)
	self.wndMain:FindChild("RbInCombatTargetingFriendly"):SetCheck(self.model.settings.inCombatTargetingMode == EnumInCombatTargetingMode.Friendly)
	self.wndMain:FindChild("RbInCombatTargetingHostile"):SetCheck(self.model.settings.inCombatTargetingMode == EnumInCombatTargetingMode.Hostile)
end

---------------------------------------------------------------------------------------------------
-- ActionControlsForm Functions
---------------------------------------------------------------------------------------------------

function ActionControls:OnRbKeyLockingCheck(wndHandler, wndControl, eMouseButton)
    self.model.settings.mouseLockingType = EnumMouseLockingType.MovementKeys
    self:GenerateView()
end

function ActionControls:OnRbKeyLockingUncheck( wndHandler, wndControl, eMouseButton)
    self.model.settings.mouseLockingType = EnumMouseLockingType.None
    self:GenerateView()
end

function ActionControls:ChkInCombatTargetingMode_OnButtonCheck(wndHandler, wndControl, eMouseButton)
	self.model.settings.inCombatTargetingMode = EnumInCombatTargetingMode.Friendly
	self:GenerateView()
end

function ActionControls:ChkInCombatTargetingMode_OnButtonUncheck(wndHandler, wndControl, eMouseButton)
	self.model.settings.inCombatTargetingMode = EnumInCombatTargetingMode.None
	self:GenerateView()
end

function ActionControls:RbInCombatTargetingFriendly_OnButtonCheck(wndHandler, wndControl, eMouseButton)
	self.model.settings.inCombatTargetingMode = EnumInCombatTargetingMode.Friendly
	self:GenerateView()
end

function ActionControls:RbInCombatTargetingHostile_OnButtonCheck(wndHandler, wndControl, eMouseButton)
	self.model.settings.inCombatTargetingMode = EnumInCombatTargetingMode.Hostile
	self:GenerateView()
end


function ActionControls:OnBtnBindMouseButtons_ButtonCheck(wndHandler, wndControl, eMouseButton)
	self.model.isMouseBound = true

    self.model.rmbActionName = "DirectionalDash"

	self.model.settings.automaticMouseBinding = false
    
    self:GenerateView()
end

function ActionControls:OnBtnBindMouseButtons_ButtonUncheck(wndHandler, wndControl, eMouseButton)
	self.model.isMouseBound = false

    self.model.rmbActionName = ""

	self.model.settings.automaticMouseBinding = false
	
    self:GenerateView()
end

-- Automatic binding
function ActionControls:OnBtnAutoBindMouseButtons_ButtonCheck(wndHandler, wndControl, eMouseButton)
	self.model.settings.automaticMouseBinding = true
	
	self:GenerateView()
end

function ActionControls:OnBtnAutoBindMouseButtons_ButtonUncheck(wndHandler, wndControl, eMouseButton)
	self.model.settings.automaticMouseBinding = false
	
	self:GenerateView()
end

-- Key capture
function ActionControls:SetBeginBindingState(wndControl)
    self:ClearBindingStates()
    wndControl:SetCheck(true)
    wndControl:SetFocus()
end

function ActionControls:SetEndBindingState(wndControl)
    wndControl:SetCheck(false)
    wndControl:ClearFocus()
    self:GenerateView()
end

function ActionControls:ClearBindingStates()
    self.wndMain:FindChild("BtnCameraLockKey"):SetCheck(false)
    self.wndMain:FindChild("BtnTargetLockKey"):SetCheck(false)
end

function ActionControls:OnBindButtonSignal(wndHandler, wndControl, eMouseButton)
    self:SetBeginBindingState(wndControl)
end

function ActionControls:OnBtnCameraLockKey_WindowKeyDown(wndHandler, wndControl, strKeyName, nScanCode, nMetakeys)
    local inputKey = InputKey:newFromKeyParams(1, nMetakeys, nScanCode)
    if inputKey:IsModifier() then
        return
    end
    
    if inputKey == EnumInputKeys.Esc then
        self.model.explicitMouseLook = EnumInputKeys.None -- unbind
    elseif not self:IsKeyAlreadyBound(inputKey) then
        self.model.explicitMouseLook = inputKey
    end        

    self:SetEndBindingState(wndControl)
end

function ActionControls:BtnTargetLockKey_WindowKeyDown(wndHandler, wndControl, strKeyName, nScanCode, nMetakeys)
    local inputKey = InputKey:newFromKeyParams(1, nMetakeys, nScanCode)
    if inputKey:IsModifier() then
        return
    end
    
    if inputKey == EnumInputKeys.Esc then
        self.model.settings.mouseOverTargetLockKey = EnumInputKeys.None
    elseif not self:IsKeyAlreadyBound(inputKey) then
        self.model.settings.mouseOverTargetLockKey = inputKey
    end
    
    self:SetEndBindingState(wndControl)
end

function ActionControls:IsKeyAlreadyBound(inputKey)
    if inputKey.strKey == nil then return false end -- ?
    
    if self.model.settings.mouseOverTargetLockKey == inputKey
        or self.model.explicitMouseLook == inputKey
    then
        return true
    end

    local isBound = try(
        function ()
            local bindings = GameLib.GetKeyBindings()
            
            local sprintBinding = self.keyBindingUtils:GetBindingByActionName(bindings, "SprintModifier")    
            local sprintInputKey = inputKey:newFromArInput(sprintBinding.arInputs[1])
            if sprintInputKey:GetModifierFlag(sprintInputKey.nCode) == inputKey.eModifier then
                self.log:Info("Key '%s' is already bound to '%s'", tostring(sprintInputKey), tostring(sprintBinding.strActionLocalized))
                return true
            end
            
            local existingBinding = self.keyBindingUtils:GetBinding(bindings, inputKey)
            if existingBinding ~= nil then
                self.log:Info("Key '%s' is already bound to '%s'", tostring(inputKey), tostring(existingBinding.strActionLocalized))
                return 
                    true,
                    existingBinding
            end

            return 
                false, 
                nil
        end,
        function (e)
            self.log:Error(e)
        end)
    
    return isBound
end

-- when the OK button is clicked
function ActionControls:OnOK()
    try(function ()
			if not GameLib.GetPlayerUnit():IsInCombat() then
	            local bindings = GameLib.GetKeyBindings()
	
	            if self.model.isMouseBound ~= self.isMouseBound 
	                or self.model.settings.automaticMouseBinding ~= self.settings.automaticMouseBinding
	            then
	                if self.model.isMouseBound then
	                    self:BindLmbMouseButton(bindings, self.model.settings.mouseLmbActionName)
	                    self:BindRmbMouseButton(bindings, self.model.settings.mouseRmbActionName)
	                end
	                
	                if not self.model.isMouseBound then
	                    self:UnbindMouseButtons(bindings)
	                end
	            end
	            
	            if self.model.explicitMouseLook.nCode ~= nil 
	                and self.model.explicitMouseLook.nCode ~= KeyBindingUtils:GetBindingByActionName(bindings, "ExplicitMouseLook").arInputs[1].nCode then
	                self.keyBindingUtils:Bind(bindings, "ExplicitMouseLook", 1, self.model.explicitMouseLook, true)
	            end
	            
	            self.keyBindingUtils:CommitBindings(bindings)
			else
				self.log:Warn("In combat, game bindings not saved.")
			end        
	
            -- use current settings
            self.settings = self.model.settings
            
            self:OnClose()
            
            self:ReadKeyBindings()
        end,
        function(e)
            self.log:Error(e)
        end)
end

-- Binding
function ActionControls:BindLmbMouseButton(bindings, mouseLmbActionName)
    self.keyBindingUtils:Bind(bindings, mouseLmbActionName, 2, EnumInputKeys.LMB, true)
    self.isMouseLmbBound = true
    
    self.log:Debug("Right mouse button bound to '%s'.", mouseLmbActionName)
end

function ActionControls:BindRmbMouseButton(bindings, mouseRmbActionName)
    self.keyBindingUtils:Bind(bindings, mouseRmbActionName, 2, EnumInputKeys.RMB, true)
    self.isMouseRmbBound = true
    
    self.log:Debug("Right mouse button bound to '%s'.", mouseRmbActionName)
end

function ActionControls:UnbindMouseButtons(bindings)
    self.keyBindingUtils:UnbindByInput(bindings, EnumInputKeys.LMB)
    self.keyBindingUtils:UnbindByInput(bindings, EnumInputKeys.RMB)
    
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
    self:ClearBindingStates()
    
    self.wndMain:Close() -- hide the window
end

---------------------------------------------------------------------------------------------------
-- TargetLockForm Functions
---------------------------------------------------------------------------------------------------

function ActionControls:OnBtnTargetLockedButtonSignal(wndHandler, wndControl, eMouseButton)
	self:SetTargetLock(false)
end

---------------------------------------------------------------------------------------------------
-- CrosshairForm Functions
---------------------------------------------------------------------------------------------------
function ActionControls:ShowCrosshair()
	--local ds = Apollo.GetDisplaySize()
	--local w = (ds.nWidth - 32) / 2
	--local h = (ds.nHeight - 32)/ 2
	
	-- Carbine broke mouselook, at least show where the targeting reticle is :(
	local mouse = Apollo.GetMouse()
	local w = mouse.x - 16
	local h = mouse.y - 16
	
	self.wndCrosshair:SetAnchorOffsets(w, h, w + 32, h + 32)

    self.wndCrosshair:Show(true, true)
end

function ActionControls:HideCrosshair()
	self.wndCrosshair:Close()
end

-----------------------------------------------------------------------------------------------
-- ActionControls Instance
-----------------------------------------------------------------------------------------------
local logInst = SimpleLog:new()
local keyBindingUtilsInst = KeyBindingUtils:new(nil, logInst)

local actionControlsInst = ActionControls:new(nil, logInst, keyBindingUtilsInst)

actionControlsInst:Init()

