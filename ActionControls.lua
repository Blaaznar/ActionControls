-----------------------------------------------------------------------------------------------
-- Client Lua Script for ActionControls
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
require "GameLib"
require "MatchingGame"

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
    Esc = InputKey:newFromKeyParams(1, 0, 1)
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
    o.mouseoverTargetDelay = 0.2
    
    o.boundKeys = {}
    o.boundKeys.mouseLockToggleKeys = {}
    o.boundKeys.movementKeys = {}
    o.boundKeys.sprintingModifier = {}

    o.settings = {
        mouseOverTargetLockKey = EnumInputKeys.None,
        closeWindowsOnMovement = true,
		isMouseoverTargeting = true,
        crosshair = true,
        inCombatTargetingMode = EnumInCombatTargetingMode.None,
    }
    
    o.defaultSettings = table.ShallowCopy(o.settings)
    
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
        Apollo.RegisterSlashCommand("ac", "OnSlashActionControls", self)
        Apollo.RegisterSlashCommand("AC", "OnSlashActionControls", self)
        Apollo.RegisterSlashCommand("ActionControls", "OnSlashActionControls", self)
        Apollo.RegisterSlashCommand("ac-debug", "OnSlashDebug", self)
        Apollo.RegisterSlashCommand("ac-reset", "OnSlashReset", self)
        
        -- Additional Addon initialization
        self:ReadKeyBindings()
        self:SetTargetLock(false)        
        
        self:InitializeEvents()
    end
end

function ActionControls:InitializeEvents()
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
        Apollo.CreateTimer("DelayedMouseOverTargetTimer", self.mouseoverTargetDelay, false)
        Apollo.StopTimer("DelayedMouseOverTargetTimer")
        
        Apollo.RegisterTimerHandler("CrosshairTimer", "OnCrosshairTimer", self)
        Apollo.CreateTimer("CrosshairTimer", 1, true)
        
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
    
    -- must not save objects or it will recurse over the index metamethod
    self.settings.mouseOverTargetLockKey = self.settings.mouseOverTargetLockKey:ToTable()

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
    xpcall(function ()
            local settings = table.ShallowCopy(self.settings)
            table.ShallowMerge(t, settings)
            
            self:ValidateUserSettings(settings)
            
            local key = settings.mouseOverTargetLockKey
            settings.mouseOverTargetLockKey = InputKey:newFromKeyParams(key.eDevice, key.eModifier, key.nCode)
            
            self.settings = settings
        end,
        function (e)
            self.log:Error("Error while loading user settings. Default values will be used.")
        end)
end

function ActionControls:ValidateUserSettings(settings)
    assert(type(settings.inCombatTargetingMode) == "number")
	assert(type(settings.isMouseoverTargeting) == "boolean")
	assert(type(settings.crosshair) == "boolean")
    assert(type(settings.closeWindowsOnMovement) == "boolean")
    
    assert(settings.mouseOverTargetLockKey)
    assert(settings.mouseOverTargetLockKey.eDevice)
    assert(settings.mouseOverTargetLockKey.eModifier)
    assert(settings.mouseOverTargetLockKey.nCode)
end

-----------------------------------------------------------------------------------------------
-- ActionControls Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
-- on Configure button from Addons window
function ActionControls:OnConfigure()
    self:OnSlashActionControls()
end

-- on SlashCommand "/ac"
function ActionControls:OnSlashActionControls()
    self:OnShowOptionWindow()
end

-- on SlashCommand "/ac-debug"
function ActionControls:OnSlashDebug()
    self.log:SetLogLevel(4)
end

function ActionControls:OnSlashReset()
    xpcall(function ()
        -- restore original settings
        self.settings = self.defaultSettings
        
        RequestReloadUI()
    end,
    function (e)
        self.log:Error("Error while trying to reset settings: %s", e)
    end)
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
    
    self.boundKeys.mouseLockToggleKeys = self:GetBoundKeysForAction(bindings, "ExplicitMouseLook")
    
    self.boundKeys.movementKeys = self:GetBoundKeysForAction(bindings, 
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
    
    local boundKeys = {}
    for _, binding in ipairs(foundBindings) do
        for j, arInput in ipairs(binding.arInputs) do
            if j > 2 then break end
            
            -- can support only keyboard for now
            if arInput.eDevice == 1 then
                local retVal = InputKey:newFromArInput(arInput)

                -- For resolving ncodes, I map the keys to Explicit mouse look and see what this returns
                --if binding.strAction == "ExplicitMouseLook" then self.log:Info("GetBoundCharsForAction(): " .. LuaUtils:DataDumper(binding)) end
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
        return
    end

    local inputKey = InputKey:newFromSysKeyCode(sysKeyCode)
    
    if inputKey.strKey == "" or inputKey.nCode == 0 then
        self.log:Debug("Unknown key code (%s), please report it to addon author.", sysKeyCode)
        return
    --else self.log:Info("OnSystemKeyDown(%s): %s", sysKeyCode, tostring(inputKey))
    end
    
    -- target locking
    if self.settings.isMouseoverTargeting 
		and inputKey == self.settings.mouseOverTargetLockKey 
    then
        if GameLib.GetTargetUnit() ~= nil then
            self:SetTargetLock(not self:GetTargetLock())
        else
            self:SetTargetLock(false)
        end
        return
    end
    
    -- automatic interrupt window closing
    if self.settings.closeWindowsOnMovement --self.settings.mouseLockingType == EnumMouseLockingType.MovementKeys 
        and not GameLib.IsMouseLockOn()
    then
        for _,key in ipairs(self.boundKeys.movementKeys) do
            if inputKey == key then
                if self:CloseInterruptWindows() then
                    return
                end
                return
            end
        end
    end
end

-----------------------------------------------------------------------------------------------
-- MouseLocking functions
-----------------------------------------------------------------------------------------------
function ActionControls:OnCrosshairTimer() 
    lockState = GameLib.IsMouseLockOn()

    if lockState then
        self:ShowCrosshair()
    else
        self:HideCrosshair()
    end
end

function ActionControls:CloseInterruptWindows()
    if Apollo.GetConsoleVariable("player.mouseLookWhileMoving")
       or (Apollo.GetConsoleVariable("player.mouseLookWhileCombat") and GameLib.GetPlayerUnit():IsInCombat()) then 
        for _,strata in ipairs(Apollo.GetStrata()) do
            for _,window in ipairs(Apollo.GetWindowsInStratum(strata)) do
                local windowName = window:GetName()
                if window:IsStyleOn("InterruptControl") 
                then
                    if window:IsShown() or window:IsVisible() then
                        self.log:Debug("Closing interrupt window '%s': ", window:GetName())
                        window:Close()
                    end
                end
            end
        end
    end
end

-----------------------------------------------------------------------------------------------
-- World Click functions
-----------------------------------------------------------------------------------------------
function ActionControls:OnGameClickWorld(param)
    self.log:Debug("OnGameClickWorld/Unit()")
    
    if GameLib.IsMouseLockOn() then
        -- reselect units targeted before the mouse click
        GameLib.SetTargetUnit(self.lastTargetUnit)
        self:SetTargetLock(self.isLastTargetLocked)
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

--------------------------------------------------------------------------
-- Targeting
--------------------------------------------------------------------------
function ActionControls:OnMouseOverUnitChanged(unit)
    self.immediateMouseOverUnit = unit

	if not self.settings.isMouseoverTargeting then return end
    
    if unit == nil
       or unit == GameLib.GetTargetUnit() -- same target
    then
        return
    end

    if not self:IsInCombatTargetingAllowed(unit) then
        return
    end

    if unit:GetType() == "Scanner" then return end -- don't target scientist pets
    
    local tPlayerPets = GameLib.GetPlayerPets()
    for k,v in ipairs(tPlayerPets) do -- don't target own pets
        if v == unit then return end
    end
    
    
    if GameLib.IsMouseLockOn() and unit ~= nil and not self:GetTargetLock() then 
        Apollo.StopTimer("DelayedMouseOverTargetTimer")
        
        if GameLib.GetTargetUnit() == nil or not self:IsInCombatTargetingAllowed(GameLib.GetTargetUnit()) then
            self:SetTarget(unit)
        else
            Apollo.StartTimer("DelayedMouseOverTargetTimer")
        end
    end
end

function ActionControls:IsInCombatTargetingAllowed(unit)
    local player = GameLib.GetPlayerUnit()
    if not player:IsInCombat() then
        self.log:Debug("Not in combat - mouseover target allowed")
        return true
    end
    
    if unit ~= nil then
        local unitType = unit:GetType()
        if unitType ~= "Player" and unitType ~= "NonPlayer" then
            local as = unit:GetActivationState()
            -- always allow targeting interactables (or you'll get a nasty surprise in dungeons/pvp)
            if as ~= nil and as.Spell ~= nil and as.Spell.bCanInteract then 
                self.log:Debug("Interactable target, mouseover target allowed")
                return true
            else
                self.log:Debug("In combat - Not a Player or NPC, mouseover target NOT allowed")
                return false
            end
        end

        if unit:IsDead() then -- dead target TODO: allow targeting only interactable targets
            self.log:Debug("In combat - Targeting dead units NOT allowed")
            return false
        end
        
        if self.settings.inCombatTargetingMode == EnumInCombatTargetingMode.None then
            self.log:Debug("In combat - no filtering set, mouseover target allowed.")
            return true
        else
            local disposition = unit:GetDispositionTo(player)
        
            if (self.settings.inCombatTargetingMode == EnumInCombatTargetingMode.Hostile
                and (disposition == Unit.CodeEnumDisposition.Hostile or dispositionTo == Unit.CodeEnumDisposition.Neutral))
            or (self.settings.inCombatTargetingMode == EnumInCombatTargetingMode.Friendly
                and disposition == Unit.CodeEnumDisposition.Friendly)
            then
                self.log:Debug("In combat - mouseover target allowed.")
                return true
            else
                self.log:Debug("In combat - mouseover target NOT allowed.") 
                return false
            end    
        end
    end
    
    self.log:Debug("??? - mouseover target NOT allowed")
    return false
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
    
    self.isTargetLocked = lockState
    self:DisplayLockState()
    
    self:SetLastTargetLock(lockState)
    
    -- after unlocking reselect the current mouseover target if it exists
    if lockState == false and self.immediateMouseOverUnit ~= nil then
        Apollo.StartTimer("DelayedMouseOverTargetTimer")
    end
end

function ActionControls:DisplayLockState()
    if self.isTargetLocked then
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
    self:GenerateModel()
    self:GenerateView()

    self.wndMain:Invoke() -- show the window
end

function ActionControls:GenerateModel()
    self.model = {}
    
    self.model.settings = table.ShallowCopy(self.settings)
    self.model.explicitMouseLook = {} 
end

function ActionControls:GenerateView()
    self.wndMain:FindChild("ChkCloseWindowsOnMovement"):SetCheck(self.model.settings.closeWindowsOnMovement)	

	self.wndMain:FindChild("ChkMouseoverTargeting"):SetCheck(self.model.settings.isMouseoverTargeting)

	self.wndMain:FindChild("ChkCrosshair"):SetCheck(self.model.settings.crosshair)	
	self.wndMain:FindChild("ChkCrosshair"):Enable(self.model.settings.isMouseoverTargeting)
		
	self.wndMain:FindChild("BtnTargetLockKey"):SetText(tostring(self.model.settings.mouseOverTargetLockKey))
	self.wndMain:FindChild("BtnTargetLockKey"):Enable(self.model.settings.isMouseoverTargeting)

    self.wndMain:FindChild("ChkInCombatTargetingMode"):SetCheck(self.model.settings.inCombatTargetingMode ~= EnumInCombatTargetingMode.None)
	self.wndMain:FindChild("ChkInCombatTargetingMode"):Enable(self.model.settings.isMouseoverTargeting)

    self.wndMain:FindChild("RbInCombatTargetingFriendly"):Enable(self.model.settings.isMouseoverTargeting and self.model.settings.inCombatTargetingMode ~= EnumInCombatTargetingMode.None)
    self.wndMain:FindChild("RbInCombatTargetingHostile"):Enable(self.model.settings.isMouseoverTargeting and self.model.settings.inCombatTargetingMode ~= EnumInCombatTargetingMode.None)
    self.wndMain:FindChild("RbInCombatTargetingFriendly"):SetCheck(self.model.settings.inCombatTargetingMode == EnumInCombatTargetingMode.Friendly)
    self.wndMain:FindChild("RbInCombatTargetingHostile"):SetCheck(self.model.settings.inCombatTargetingMode == EnumInCombatTargetingMode.Hostile)
end

---------------------------------------------------------------------------------------------------
-- ActionControlsForm Functions
---------------------------------------------------------------------------------------------------

function ActionControls:ChkCloseWindowsOnMovement_OnButtonUncheck(wndHandler, wndControl, eMouseButton)
    self.model.settings.closeWindowsOnMovement = false
end

function ActionControls:ChkCloseWindowsOnMovement_OnButtonCheck(wndHandler, wndControl, eMouseButton)
    self.model.settings.closeWindowsOnMovement = true
end

function ActionControls:ChkCrosshair_OnButtonCheck(wndHandler, wndControl, eMouseButton)
	self.model.settings.crosshair = true
end

function ActionControls:ChkCrosshair_OnButtonUncheck(wndHandler, wndControl, eMouseButton)
	self.model.settings.crosshair = false
end

function ActionControls:ChkMouseoverTargeting_OnButtonCheck(wndHandler, wndControl, eMouseButton)
	self.model.settings.isMouseoverTargeting = true
	self.model.settings.crosshair = true
	self:GenerateView()
end

function ActionControls:ChkMouseoverTargeting_OnButtonUncheck(wndHandler, wndControl, eMouseButton)
	self.model.settings.isMouseoverTargeting = false
	self.model.settings.crosshair = false
	self:GenerateView()
end

function ActionControls:ChkInCombatTargetingMode_OnButtonCheck(wndHandler, wndControl, eMouseButton)
    self.model.settings.inCombatTargetingMode = EnumInCombatTargetingMode.Hostile
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

    local success, isBound = xpcall(
        function ()
            local bindings = GameLib.GetKeyBindings()
            
            local sprintBinding = self.keyBindingUtils:GetBindingByActionName(bindings, "SprintModifier")    
            local sprintInputKey = inputKey:newFromArInput(sprintBinding.arInputs[1])
            if sprintInputKey.eDevice ~= 0 and
                sprintInputKey:GetModifierFlag(sprintInputKey.nCode) == inputKey.eModifier then
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
    xpcall(function ()
            -- use current settings
            self.settings = self.model.settings
            
            self:OnClose()
        end,
        function(e)
            self.log:Error(e)
        end)
end

-- when the Cancel button is clicked
function ActionControls:OnCancel()
    -- discard current settings
    self.model.settings = nil
    
    self:OnClose()    
end

function ActionControls:OnClose()
    self.wndMain:Close()
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
    if not self.settings.crosshair then 
		return 
	end

    local ds = Apollo.GetDisplaySize()
    local w = (ds.nWidth - 32) / 2
    local h = (ds.nHeight - 32)/ 2
    
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

