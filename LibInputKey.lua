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
    
    [29] = "Ctrl",

	[30] = "A", [31] = "S", [32] = "D", [33] = "F", [34] = "G", [35] = "H",
	[36] = "J", [37] = "K", [38] = "L", [39] = ";", [40] = "'", [41] = "`",
	[42] = "Shift",
	[43] = "\\", [44] = "Z", [45] = "X", [46] = "C", [47] = "V", [48] = "B",
	[49] = "N", [50] = "M", [51] = ",", [52] = ".",
	[54] = "Right Shift",
	
	[57] = "Space", [58] = "Caps Lock", [59] = "F1", [60] = "F2", [61] = "F3", 
	[62] = "F4", [63] = "F5", [64] = "F6", [65] = "F7", [66] = "F8", 
	[67] = "F9", [68] = "F10", [69] = "Pause", [70] = "Scroll Lock",
	[71] = "Num 7", [72] = "Num 8", [73] = "Num 1", [75] = "Num 4",
	[76] = "Num 5", [77] = "Num 6", [78] = "Num +", [79] = "Num 9",
	[80] = "Num 2", [81] = "Num 3", [82] = "Num 0", [83] = "Num Del",
	
	[87] = "F11", [88] = "F12",
    
    [285] = "Right Ctrl",
	
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
    self.__tostring = function (a) return a:GetInputKeyName() end
        
    o.eDevice = 0
    o.eModifier = 0
    o.nCode = 0
    o.strKey = ""
    
    return o
end

function InputKey:newFromArInput(arInput)
    local o = self:new()

    -- initialize variables here
    o.eDevice = arInput.eDevice
    o.eModifier = arInput.eModifier
    o.nCode = arInput.nCode
    o.strKey = nCodeKeyMap[arInput.nCode]
    
    return o
end

function InputKey:newFromKeyParams(eDevice, eModifier, nCode)
    local o = self:new()

    -- initialize variables here
    o.eDevice = eDevice
    if self:IsModifier() then
        o.eModifier = 0
    else
        o.eModifier = eModifier
    end
    
    o.nCode = nCode
    o.strKey = nCodeKeyMap[nCode]
    
    return o
end

function InputKey:newFromSysKeyCode(sysKeyCode) -- TODO: how to properly chain constructors?
    local o = self:new()

    -- initialize variables here
    o.eDevice = 1
    o.strKey = systemKeyMapInv[sysKeyCode] or ""
    o.nCode = nCodeKeyMapInv[o.strKey] or 0
    
    if self:IsModifier() then
        o.eModifier = 0
    else
        if Apollo.IsShiftKeyDown() then
            o.eModifier = GameLib.CodeEnumInputModifier.Shift
        elseif Apollo.IsControlKeyDown() then
            o.eModifier = GameLib.CodeEnumInputModifier.Control
        elseif Apollo.IsAltKeyDown() then
            o.eModifier = GameLib.CodeEnumInputModifier.Alt
        else
            o.eModifier = 0
        end
    end
    
    return o
end

function InputKey:GetInputKeyName()
	if  self.eDevice == nil or self.eModifier == nil or self.nCode == nil then
        return "Invalid key!"
    end
        
	if self.eDevice == 2 then
		return "Mouse button " .. tostring(self.nCode + 1)
	elseif self.eDevice == 1 then
		if self.strKey ~= "" then
			if self.eModifier == 0 then
				return tostring(nCodeKeyMap[self.nCode])
			else
				local modifier
				if self.eModifier == GameLib.CodeEnumInputModifier.Shift then
					modifier = "Shift"
				elseif self.eModifier == GameLib.CodeEnumInputModifier.Control then
					modifier = "Ctrl"
				elseif self.eModifier == GameLib.CodeEnumInputModifier.Alt then
					modifier = "Alt"
				else
					modifier = "Unknown"
				end
                
                return string.format("%s-%s", modifier, tostring(self.strKey))
			end
		else
			return "None"
		end
    elseif self.eDevice == 0 then
        return "None"
	else
		return "Unknown device/key"
	end
end

function InputKey:IsModifier()
    return self:GetModifierFlag(self.nCode) ~= 0
end

function InputKey:GetModifierFlag(nModifierScancode)
	if nModifierScancode == GameLib.CodeEnumInputModifierScancode.LeftShift
        or nModifierScancode == GameLib.CodeEnumInputModifierScancode.RightShift
    then
		return GameLib.CodeEnumInputModifier.Shift
	elseif nModifierScancode == GameLib.CodeEnumInputModifierScancode.LeftCtrl 
        or nModifierScancode == GameLib.CodeEnumInputModifierScancode.RightCtrl
    then
		return GameLib.CodeEnumInputModifier.Control
	elseif nModifierScancode == GameLib.CodeEnumInputModifierScancode.LeftAlt 
        or nModifierScancode == GameLib.CodeEnumInputModifierScancode.RightAlt
    then
		return GameLib.CodeEnumInputModifier.Alt
	else
		return 0 
	end
end

-- Register Library
Apollo.RegisterPackage(InputKey, "Blaz:Lib:InputKey-0.1", 1, {})