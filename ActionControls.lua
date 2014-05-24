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
    
    
    o.isAutomaticMouseLockDelayed = false
    o.immediateMouseOverUnit = nil
    o.lastTargetUnit = nil
    o.isTargetLocked = false
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
    
    -- Experimental
    o.automaticMouseBinding = false
    
    return o
end

function ActionControls:Init()
    self.log:SetLogName("ActionControls")
    self.log:SetLogLevel(3)

    local bHasConfigureFunction = true
    local strConfigureButtonText = "Action Controls"
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

		self.wndTargetLock = Apollo.LoadForm(self.xmlDoc, "TargetLockForm", nil, self)
        if self.wndTargetLock == nil then
            Apollo.AddAddonErrorText(self, "Could not load the target lock window for some reason.")
            return
        end
        
        self.wndMain:Show(false, true)
        self.wndTargetLock:Show(false, true)
        
        -- if the xmlDoc is no longer needed, you should set it to nil
        -- self.xmlDoc = nil
        
        -- Register handlers for events, slash commands and timer, etc.
        Apollo.RegisterSlashCommand("ac", "OnActionControlsOn", self)
        Apollo.RegisterSlashCommand("AC", "OnActionControlsOn", self)
        Apollo.RegisterSlashCommand("ActionControls", "OnActionControlsOn", self)
        Apollo.RegisterSlashCommand("ac-debug", "OnActionControlsOnDebug", self)
        Apollo.RegisterSlashCommand("ac-autobind", "OnActionControlsOnAutoBind", self)
        
        -- Unlock triggers - general unlocking
        self:RegisterEvents("OnGameDialogInteraction", 
            "Test_MouseReturnSignal",
            "AbilityWindowHasBeenToggled",
            "GenericEvent_ShowConfirmLeaveDisband",
            "GenericEvent_ToggleGroupBag",
            "Guild_WindowLoaded",
            "GuildBankerOpen", 
            "GuildRegistrarOpen",
            "HousingBrokerOpen",
            "HousingPanelControlOpen",
            "InspectWindowHasBeenToggled",
            "InvokeCraftingWindow",
            "InvokeFriendsList",
            "InvokeScientistExperimentation",
            "InvokeSettlerBuild",
            "InvokeShuttlePrompt",
            "InvokeSoldierBuild",
            "InvokeTaxiWindow",
            "InvokeTradeskillTrainerWindow",
            "InvokeVendorWindow",
            "MailBoxActivate",
            "MatchingGameReady",
            "PlayerPathShow",
            "PlayerPathShowWithData",
            "ResourceConversionOpen",
            "ShowBank",
            "ShowDye",
            "ShowInstanceGameModeDialog",
            "ShowQuestLog",
            "ShowResurrectDialog",
            "Test_MouseReturnSignal",
            "ToggleAbilitiesWindow",
            "ToggleAchievementsFromHUD",
            "ToggleAchievementWindow",
            "ToggleAuctionWindow",
            "ToggleChallengesWindow",
            "ToggleCharacterWindow",
            "ToggleCodex",
            "ToggleGalacticArchiveWindow",
            "ToggleGroupFinder",
            "ToggleInventory",
            "ToggleMailWindow",
            "ToggleProgressLog",
            "ToggleSocialWindow",        
            "ToggleQuestLog",
            "ToggleTradeskills",
            "ToggleZoneMap",
            "TradeskillEngravingStationOpen")

        -- Unlock triggers - auto-popup windows 
        -- TODO: Monitor Shown state
        self:RegisterEvents("OnGameDialog", 
            "DuelStateChanged",
            "MatchingGameReady",
            "PVPMatchFinished",
            "P2PTradeInvite",
            "ProgressClickWindowDisplay")
        
        Apollo.RegisterTimerHandler("GameDialogTimer", "OnGameDialogTimer", self)
        Apollo.CreateTimer("GameDialogTimer", 0.3, false)
        Apollo.StopTimer("GameDialogTimer")
        
        -- Lock triggers
        Apollo.RegisterEventHandler("SystemKeyDown", "OnSystemKeyDown", self) 
        Apollo.RegisterEventHandler("GameClickWorld", "OnGameClickWorld", self)
        Apollo.RegisterEventHandler("GameClickSky", "OnGameClickWorld", self)
        Apollo.RegisterEventHandler("GameClickUnit", "OnGameClickWorld", self)
        Apollo.RegisterEventHandler("GameClickProp", "OnGameClickWorld", self)
        
        -- Targeting
        Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
        Apollo.RegisterEventHandler("MouseOverUnitChanged", "OnMouseOverUnitChanged", self)
        Apollo.RegisterTimerHandler("DelayedMouseOverTargetTimer", "OnDelayedMouseOverTargetTimer", self)
        Apollo.CreateTimer("DelayedMouseOverTargetTimer", 0.3, false)
        Apollo.StopTimer("DelayedMouseOverTargetTimer")
        self:SetTargetLock(false)
        
        -- Keybinding events
        Apollo.RegisterEventHandler("KeyBindingKeyChanged", "OnKeyBindingKeyChanged", self)
        Apollo.RegisterEventHandler("KeyBindingUpdated", "OnKeyBindingUpdated", self)
        
        -- Additional Addon initialization
        self:ReadKeyBindings()
        
        self:InitializeDetection()
    end
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

-- on SlashCommand "/ac-autobind"
function ActionControls:OnActionControlsOnAutoBind()
    self.automaticMouseBinding = not self.automaticMouseBinding
    
    if self.automaticMouseBinding then
        self.log:Warn("Automatic mouse binding turned on. Your mouse buttons will now automatically rebind to Action1/Dodge only when mouse look is enabled.")
        self.log:Warn("This feature is experimental and will not be able to switch bindings once your character is in combat.")
        self.log:Warn("If you like it, petition Carbine to allow this kind of functionality in combat.")
    end
    
    self:SetMouseLock(false)
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
    
    -- self.log:Debug("GetBoundCharsForAction(): " .. LuaUtils:DataDumper(binding))

    local boundChars = {    
        [1] = self.keyUtils:KeybindNCodeToChar(binding.arInputs[1].nCode),
        [2] = self.keyUtils:KeybindNCodeToChar(binding.arInputs[2].nCode)
    }
    
    return boundChars
end

-------------------------------------------------------------------------------
-- Key press processing
-------------------------------------------------------------------------------
function ActionControls:OnSystemKeyDown(sysKeyCode)
    local strKey = self.keyUtils:SysKeyCodeToChar(sysKeyCode)
    --self.log:Debug("OnSystemKeyDown(%s): %s", sysKeyCode, tostring(strKey))
    
    if strKey == nil then
        self.log:Debug("Unknown key code (%s), please report it to addon author.", sysKeyCode)
        return
    end
    
    -- modifiers not properly supported yet
    if Apollo.IsAltKeyDown() 
    or Apollo.IsControlKeyDown() 
    --or Apollo.IsShiftKeyDown() 
    then
        return
    end

    -- stop processing keys if configuration window is open
    if (self.wndMain ~= nil and self.wndMain:IsVisible()) 
    then
        self:SetMouseLock(false)
        return
    end

    -- target locking
	if strKey == "Esc" then
		--self:SetTargetLock(false) -- so the target lock window doesn't stay shown
	elseif strKey == self.settings.mouseOverTargetLockKey then
        if GameLib.GetTargetUnit() ~= nil then
            self:SetTargetLock(not self:GetTargetLock())
        else
            self:SetTargetLock(false)
        end
        return
    end

    -- camera lock toggle
    for _,keys in ipairs(self.boundKeys.mouseLockToggleKeys) do
        if strKey == keys[1]
        or strKey == keys[2] then
            self.log:Debug("OnSystemKeyDown(%s) - Manual toggle", sysKeyCode)
            self:ToggleMouseLock()
            return
        end
    end
    
    -- automatic camera locking
    if self.settings.mouseLockingType == EnumMouseLockingType.MovementKeys 
        and not self.isAutomaticMouseLockDelayed
    then
        for _,keys in ipairs(self.boundKeys.mouseLockTriggerKeys) do
            if strKey == keys[1] 
            or strKey == keys[2] then
                self.log:Debug("OnSystemKeyDown(%s) - Manual movement lock", sysKeyCode)
                self:SetMouseLock(true)
                return
            end
        end
    end
end

-----------------------------------------------------------------------------------------------
-- MouseLocking functions
-----------------------------------------------------------------------------------------------
function ActionControls:InitializeDetection(lockState)
    if lockState == nil then lockState = GameLib.IsMouseLockOn() end
end

function ActionControls:ToggleMouseLock()
    self:SetMouseLock(not GameLib.IsMouseLockOn())
end

function ActionControls:SetMouseLock(lockState) 
    self:InitializeDetection(lockState)

    if lockState ~= GameLib.IsMouseLockOn() then
        self:SetLastTarget()
        GameLib.SetMouseLock(lockState)

        -- EXPERIMENTAL --
        -- Automatic remapping of LMB/RMB to action 1/2 on camera lock - Does not work in combat :(
        if self.automaticMouseBinding then
            local bindings = GameLib.GetKeyBindings()
            try(function()
                    if lockState then
                        self:BindLmbMouseButton(bindings)
                        self:BindRmbMouseButton(bindings, "DirectionalDash")
                        self.mouseIsLmbBound = true
                        self.mouseIsRmbBound = true
                    else
                        self:UnbindMouseButtons(bindings)
                        self.mouseIsLmbBound = false
                        self.mouseIsRmbBound = false
                    end
                    
                    self.keyUtils:CommitBindings(bindings)
                end,
                function(e)
                    self.log:Error(e)
                end)
        end
    end
end

-----------------------------------------------------------------------------------------------
-- World Click functions
-----------------------------------------------------------------------------------------------
function ActionControls:OnGameClickWorld(tPos)
    if not self.mouseIsLmbBound and GameLib.IsMouseLockOn() then
        -- reselect units targeted before the mouse click
        GameLib.SetTargetUnit(self.lastTargetUnit)
        self:SetTargetLock(self.isLastTargetLocked)

        self:SetMouseLock(false)
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
    -- TODO: Trigger only on window shown, not off
    self.log:Debug("OnGameDialogInteraction()")
    self:SetMouseLock(false)
end

function ActionControls:OnGameDialog()
    -- TODO: Trigger only on window shown, not off
    self:SetMouseLock(false)
    self.isAutomaticMouseLockDelayed = true
    Apollo.StartTimer("GameDialogTimer")
end

function ActionControls:OnGameDialogTimer()
    self.log:Debug("OnGameDialogTimer()")
    self.isAutomaticMouseLockDelayed = false
end

--------------------------------------------------------------------------
-- Targeting
--------------------------------------------------------------------------
function ActionControls:OnMouseOverUnitChanged(unit)
    self.immediateMouseOverUnit = unit
    if unit == GameLib.GetTargetUnit() then
        -- same target
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
        local targetForm = Apollo.FindWindowByName("ClusterTargetFlipped")
        if targetForm == nil then
            return
        end
        
		self.wndTargetLock:SetAnchorPoints(targetForm:GetAnchorPoints())
		self.wndTargetLock:SetAnchorOffsets(targetForm:GetAnchorOffsets())
    
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
        local strKey = self.keyUtils:KeybindNCodeToChar(self.model.explicitMouseLook.nCode)
        
        self.wndMain:FindChild("BtnCameraLockKey"):SetText(tostring(strKey or ""))    
    end

    self.wndMain:FindChild("BtnTargetLockKey"):SetText(tostring(self.model.settings.mouseOverTargetLockKey or ""))
    
    self.wndMain:FindChild("BindMouseButtons"):Enable(not self.model.isMouseLmbBound)
    self.wndMain:FindChild("UnBindMouseButtons"):Enable(self.model.isMouseLmbBound)
end

-----------------------------------------------------------------------------------------------
-- ActionControls Form functions
-----------------------------------------------------------------------------------------------
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
    
     -- TODO: split to other button
    self.model.isMouseRmbBound = true
    self.model.rmbActionName = "DirectionalDash"
    -------------------------------
    
    self:GenerateView()
end

function ActionControls:OnUnBindMouseButtonsSignal( wndHandler, wndControl, eMouseButton )
    self.model.isMouseLmbBound = false
    self.model.isMouseRmbBound = false
    self.model.rmbActionName = ""
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
    if self.keyUtils:KeybindNCodeToChar(nScanCode) == "Esc" then
        self.model.explicitMouseLook.eDevice = 0
        self.model.explicitMouseLook.eModifier = 0
        self.model.explicitMouseLook.nCode = 0
    elseif (not self:IsKeyAlreadyBound(1, 0, nScanCode)) then
        self.model.explicitMouseLook.eDevice = 1
        self.model.explicitMouseLook.eModifier = 0
        self.model.explicitMouseLook.nCode = nScanCode
    end        

    self:SetEndBindingState(wndControl)
end

function ActionControls:BtnTargetLockKey_WindowKeyDown( wndHandler, wndControl, strKeyName, nScanCode, nMetakeys )
    if self.keyUtils:KeybindNCodeToChar(nScanCode) == "Esc" then
        self.model.settings.mouseOverTargetLockKey = nil
    elseif not self:IsKeyAlreadyBound(1, 0, nScanCode) then
        self.model.settings.mouseOverTargetLockKey = self.keyUtils:KeybindNCodeToChar(nScanCode)
    end
    
    self:SetEndBindingState(wndControl)
end

function ActionControls:IsKeyAlreadyBound(eDevice, eModifier, nCode)
    local key = self.keyUtils:KeybindNCodeToChar(nCode)
    
    if key == nil then return false end -- ?
    
    if self.model.settings.mouseOverTargetLockKey == key then
        return true
    end

    local isBound, binding = try(
        function ()
            local isBound = self.keyUtils:IsBound(eDevice, eModifier, nCode)
            if isBound then
                local existingBinding = self.keyUtils:GetBinding(eDevice, eModifier, nCode)
                self.log:Info("Key '%s' is already bound to '%s'", tostring(key), tostring(existingBinding.strActionLocalized))
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
            
            if self.model.explicitMouseLook.nCode ~= nil 
                and self.model.explicitMouseLook.nCode ~= KeyUtils:GetBindingByActionName("ExplicitMouseLook", bindings).arInputs[1].nCode then
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
    
    self.log:Debug("Right mouse button bound to '%s'.", actionName)
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

---------------------------------------------------------------------------------------------------
-- TargetLockForm Functions
---------------------------------------------------------------------------------------------------

function ActionControls:OnBtnTargetLockedButtonSignal(wndHandler, wndControl, eMouseButton)
	self:SetTargetLock(false)
end

-----------------------------------------------------------------------------------------------
-- ActionControls Instance
-----------------------------------------------------------------------------------------------
local logInst = SimpleLog:new()
local keyUtilsInst = KeyUtils:new(logInst)

local actionControlsInst = ActionControls:new(logInst, keyUtilsInst)

actionControlsInst:Init()

