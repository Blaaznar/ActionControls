-- Helper functions for key mapping

-- How to contribute and extend support for more keys: 
-- 1. Start ActionControls debug mode with /ac-debug 
-- 2. Press the keys the addon doesn't know how to handle
-- 3. Type down the combination of the key you pressed and the code the addon gives you
-- 4. Add the missing combinations to the systemKeyMap below

-- extending nCodeMap requires more work (modifying bindings), 
-- will write a function that will simplify that

-- Character map for keyPress codes reported by SystemKeyDown event
local systemKeyMap = { 
	["Backspace"] = 8, ["Tab"] = 9, ["Shift"] = 16, ["Ctrl"] = 17, 
	["Caps Lock"] = 20, ["Esc"] = 27, ["Space"] = 32, ["Left"] = 37,
	["Up"] = 38, ["Right"] = 39, ["Down"] = 40,

	["0"] = 48, ["1"] = 49, ["2"] = 50, ["3"] = 51, ["4"] = 52, ["5"] = 53,
	["6"] = 54, ["7"] = 55, ["8"] = 56, ["9"] = 57, 
	
	["A"] = 65, ["B"] = 66, ["C"] = 67, ["D"] = 68, ["E"] = 69, ["F"] = 70, 
	["G"] = 71, ["H"] = 72,	["I"] = 73, ["J"] = 74, ["K"] = 75, ["L"] = 76, 
	["M"] = 77,["N"] = 78, ["O"] = 79, ["P"] = 80, ["Q"] = 81, ["R"] = 82,
	["S"] = 83, ["T"] = 84, ["U"] = 85, ["V"] = 86, ["W"] = 87, ["X"] = 88,
	["Y"] = 89, ["Z"] = 90, 
	
	["Num 0"] = 96, ["Num 1"] = 97, ["Num 2"] = 98, ["Num 3"] = 99, 
	["Num 4"] = 100, ["Num 5"] = 101, ["Num 6"] = 102, ["Num 7"] = 103, 
	["Num 8"] = 104, ["Num 9"] = 105, 

	["F1"] = 112, ["F2"] = 113, ["F3"] = 114, ["F4"] = 115, ["F5"] = 116, 
	["F6"] = 117, ["F7"] = 118, ["F8"] = 119, ["F9"] = 120, ["F10"] = 121, 
	["F11"] = 122, ["F12"] = 123, 

	["Num *"] = 106, ["Num +"] = 107, ["Num -"] = 109, ["Num /"] = 111,
	["Num Lock"] = 144,

	[";"] = 186, ["="] = 187, [","] = 188, ["-"] = 189, ["."] = 190, 
	["/"] = 191,

	["`"] = 192, 
	
	["["] = 219, ["\\"] = 220, ["]"] = 221, ["'"] = 222
}

-- Key map for keybinding codes in keyBinding.arInputs[1].nCode
local nCodeKeyMap = {
	[1] = "Esc", [2] = "1", [3] = "2", [4] = "3", [5] = "4", [6] = "5",
	[7] = "6", [8] = "7", [9] = "8", [10] = "9", [11] = "0", [12] = "-",
	[13] = "=", [14] = "Backspace", [15] = "Tab", [16] = "Q", [17] = "W",
	[18] = "E", [19] = "R", [20] = "T", [21] = "Y", [22] = "U", [23] = "I",
	[24] = "O", [25] = "P", [26] = "[", [27] = "]",

	[30] = "A", [31] = "S", [32] = "D", [33] = "F", [34] = "G", [35] = "H",
	[36] = "J", [37] = "K", [38] = "L", [39] = ";", [40] = "'", [41] = "`",
	
	[43] = "\\", [44] = "Z", [45] = "X", [46] = "C", [47] = "V", [48] = "B",
	[49] = "N", [50] = "M", [51] = ",", [52] = ".",
	
	[57] = "Space", [58] = "Caps Lock", [59] = "F1", [60] = "F2", [61] = "F3", 
	[62] = "F4", [63] = "F5", [64] = "F6", [65] = "F7", [66] = "F8", 
	[67] = "F9", [68] = "F10", [69] = "Pause", [70] = "Scroll Lock",
	[71] = "Num 7", [72] = "Num 8", [73] = "Num 1", [75] = "Num 4",
	[76] = "Num 5", [77] = "Num 6", [78] = "Num +", [79] = "Num 9",
	[80] = "Num 2", [81] = "Num 3", [82] = "Num 0", [83] = "Num Del",
	
	[87] = "F11", [88] = "F12",
	
	[328] = "Up", [331] = "Left", [333] = "Right", [336] = "Down"
}

-- Inverted tables for faster lookups
local systemKeyMapInv = {}
for k,v in pairs(systemKeyMap) do 
	table.insert(systemKeyMapInv, v, k) 
end

local nCodeKeyMapInv = {}
for k,v in pairs(nCodeKeyMap) do 
	nCodeKeyMapInv[v] = k 
end

local InputKey = {}

function InputKey:new(o)
    o = {} or o
    setmetatable(o, self)
    self.__index = self 
    self.__eq = function (a,b) return a.eDevice == b.eDevice and a.eModifier == b.eModifier and a.nCode == b.nCode end
end

function InputKey:newFromArInput(arInput)
    o = InputKey:new()

    -- initialize variables here
    o.eDevice = arInput.eDevice
    o.eModifier = arInput.eModifier
    o.nCode = arInput.nCode
    o.strKey = nCodeKeyMap[arInput.nCode]
    
    return o
end

function InputKey:newFromKeyParams(eDevice, eModifier, nCode)
    o = InputKey:new()

    -- initialize variables here
    o.eDevice = eDevice
    o.eModifier = eModifier
    o.nCode = nCode
    o.strKey = nCodeKeyMap[nCode]
    
    return o
end

function InputKey:newFromSysKeyCode(sysKeyCode) -- TODO: how to chain constructors?
    o = InputKey:new()

    -- initialize variables here
    o.eDevice = eDevice
    o.eModifier = eModifier
    if Apollo.IsAltKeyDown() then
        o.eModifier = 1
    elseif Apollo.IsControlKeyDown() then
        o.eModifier = 2
    elseif Apollo.IsAltKeyDown() then
        o.eModifier = 4
    else
        o.eModifier = 0
    end
    
    o.strKey = systemKeyMapInv[sysKeyCode] or 0
    o.nCode = nCodeKeyMapInv[o.strKey] or 0
    
    return o
end

function InputKey:GetInputKeyName()
	assert(self.eDevice, "Binding eDevice not provided.")
    assert(self.eModifier, "Binding eModifier not provided.")
	assert(self.nCode, "Binding nCode not provided.")
    
	if self.eDevice == 2 then
		return "Mouse button " .. tostring(self.nCode + 1)
	elseif self.eDevice == 1 then
		if self.strKey ~= nil then
			if self.eModifier == 0 then
				return nCodeKeyMap[self.nCode]
			else
				local modifier
				if self.eModifier == 1 then
					modifier = "Shift"
				elseif self.eModifier == 2 then
					modifier = "Ctrl"
				elseif self.eModifier == 4 then
					modifier = "Alt"
				else
					modifier = "Unknown"
				end
				return string.format("%s-%s", modifier, self.strKey)
			end
		else
			return "Unknown key"
		end
    elseif inputKey.eDevice == 0 then
        return "Key not bound"
	else
		return "Unknown device/key"
	end
end

-- Register Library
Apollo.RegisterPackage(InputKey, "Blaz:Lib:InputKey-0.1", 1, {})

-------------------------------------------------------------------------------
-- KeyUtils
-------------------------------------------------------------------------------
local KeyUtils = {}

function KeyUtils:new(logInst)
    o = {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.log = logInst

    return o
end

function KeyUtils:GetInputKeyName(inputKey)
    assert(inputKey, "inputKey not provided.")
	assert(inputKey.eDevice, "eDevice not provided.")
    assert(inputKey.eModifier, "eModifier not provided.")
	assert(inputKey.nCode, "nCode not provided.")
    
	if inputKey.eDevice == 2 then
		return "Mouse button " .. tostring(inputKey.nCode + 1)
	elseif inputKey.eDevice == 1 then
		local keyName = self:KeybindNCodeToChar(inputKey.nCode)
		
		if keyName ~= nil then
			if inputKey.eModifier == 0 then
				return nCodeKeyMap[inputKey.nCode]
			else
				local modifier
				if inputKey.eModifier == 1 then
					modifier = "Shift"
				elseif inputKey.eModifier == 2 then
					modifier = "Ctrl"
				elseif inputKey.eModifier == 4 then
					modifier = "Alt"
				else
					modifier = "Unknown"
				end
				return string.format("%s-%s", modifier, keyName)
			end
		else
			return "Unknown key"
		end
    elseif inputKey.eDevice == 0 then
        return "Key not bound"
	else
		return "Unknown device/key"
	end
end

function KeyUtils:KeybindNCodeToChar(nCode)
	return nCodeKeyMap[nCode]
end

function KeyUtils:CharToKeybindNCode(strKey)
	return nCodeKeyMapInv[strKey]
end

function KeyUtils:CharToSysKeyCode(strKey)
	return systemKeyMap[strKey]
end

function KeyUtils:SysKeyCodeToChar(sysKeyCode)
	return systemKeyMapInv[sysKeyCode]
end

function KeyUtils:Bind(bindings, actionName, index, inputKey, unbindConflictingBindings)
	assert(not GameLib.GetPlayerUnit():IsInCombat(), "In combat, changing bindings is not possible at this moment.")
	assert(bindings, "Bindings not provided.")
	assert(index, "Binding index not provided.")
	assert(inputKey.eDevice, "Binding eDevice not provided.")
    assert(inputKey.eModifier, "Binding eModifier not provided.")
	assert(inputKey.nCode, "Binding nCode not provided.")
	
	local inputKeyName = self:GetInputKeyName(inputKey)
		
	if unbindConflictingBindings then
		self:UnbindByInput(bindings, inputKey)
	else
		assert(not self:IsBound(bindings), 
			self.log:Warn(inputKeyName .. " is already bound, please manually unbind it from the game's Keybind window."))
	end
	
	local binding = self:GetBindingByActionName(bindings, actionName)
    if binding ~= nil then
        binding.arInputs[index].eDevice = inputKey.eDevice
        binding.arInputs[index].eModifier = inputKey.eModifier
        binding.arInputs[index].nCode = inputKey.nCode
        
        self.log:Debug("Bound binding for '%s' at index %s to: %s", actionName, tostring(index), inputKeyName)
    else
        self.log:Debug("Binding '%s' not found.", actionName)
    end
end

function KeyUtils:Unbind(bindings, actionName, index)
	assert(bindings, "Bindings not provided.")
	local binding = self:GetBindingByActionName(bindings, actionName)

	if index == nil then 
		for _, i in ipairs(binding.arInputs) do
			binding.arInputs[i].eDevice = 0
            binding.arInputs[i].eModifier = 0
			binding.arInputs[i].nCode = 0    
		end		

		self.log:Debug("Unbound binding for '%s' at index %s.", actionName, tostring(i))
	else 
		binding.arInputs[index].eDevice = 0
        binding.arInputs[index].eModifier = 0        
		binding.arInputs[index].nCode = 0
		
		self.log:Debug("Unbound binding for '%s' at index %s.", actionName, tostring(index))
	end
end

function KeyUtils:UnbindByInput(bindings, inputKey)
	assert(bindings, "Bindings not provided.")
    assert(inputKey, "inputKey not provided.")
	assert(inputKey.eDevice, "eDevice not provided.")
    assert(inputKey.eModifier, "eModifier not provided.")
	assert(inputKey.nCode, "nCode not provided.")
    
	for _, binding in ipairs(bindings) do
		for _, arInput in ipairs(binding.arInputs) do
			if arInput.eDevice == inputKey.eDevice 
            and arInput.eModifier == inputKey.eModifier
            and arInput.nCode == inputKey.nCode 
            then
				arInput.eDevice = 0
                arInput.eModifier = 0
				arInput.nCode = 0
				self.log:Debug("Unbound '%s' from '%s'.", self:GetInputKeyName(inputKey), binding.strAction)
			end
		end
	end
end

function KeyUtils:CommitBindings(bindings)
	assert(bindings, "Bindings not provided.")
	assert(not GameLib.GetPlayerUnit():IsInCombat(), "In combat, changing bindings is not possible at this moment.")

	GameLib.SetKeyBindings(bindings)
	self.log:Debug("Bindings saved.")
end

function KeyUtils:IsBound(bindings, inputKey)
	return self:GetBinding(bindings, inputKey) ~= nil
end

function KeyUtils:GetBinding(bindings, inputKey)
	assert(inputKey.eDevice, "Binding eDevice not provided.")
    assert(inputKey.eModifier, "Binding eModifier not provided.")
	assert(inputKey.nCode, "Binding nCode not provided.")

	if bindings == nil then bindings = GameLib.GetKeyBindings() end
	
	for _, binding in ipairs(bindings) do
		for _, arInput in ipairs(binding.arInputs) do
			if arInput.eDevice == inputKey.eDevice 
            and arInput.eModifier == inputKey.eModifier 
            and arInput.nCode == inputKey.nCode 
            then
				return binding
			end
		end
	end
    
    return nil
end

function KeyUtils:GetBindingByActionName(bindings, actionName)
	assert(bindings, "Bindings not provided.")
	assert(actionName, "Action names list not provided.")

	return self:GetBindingListByActionNames(bindings, actionName)[1]
end

function KeyUtils:GetBindingListByActionNames(bindings, ...)
	assert(bindings, "Bindings not provided.")
	assert(arg, "Action names list not provided.")

	local foundBindings = {}
	for _, binding in ipairs(bindings) do
		for _, actionName in ipairs(arg) do
			if binding.strAction == actionName then
				table.insert(foundBindings, binding)
			end
		end
	end
	
	return foundBindings
end

-- Register Library
Apollo.RegisterPackage(KeyUtils, "Blaz:Lib:KeyUtils-0.2", 1, {})
