-- Helper functions for key mapping

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

local KeyUtils = {}

function KeyUtils:new(logInst)
    o = {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.logInst = logInst
	
    return o
end

function KeyUtils:CharToSysKeyCode(char)
	return systemKeyMap[char]
end

function KeyUtils:KeybindNCodeToChar(nCode)
	return nCodeKeyMap[nCode]
end

function KeyUtils:Bind(actionName, index, eDevice, nCode, pBindings)
	assert(not GameLib.GetPlayerUnit():IsInCombat(), "In combat, changing bindings is not possible at this moment.")
	assert(index, error("Binding index not provided."))
	assert(eDevice, error("Binding eDevice not provided."))
	assert(nCode, error("Binding nCode not provided."))
	
	local bindings = pBindings or GameLib.GetKeyBindings();
	local binding = self:GetBindingByActionName(bindings, actionName)

	binding.arInputs[index].eDevice = eDevice
	binding.arInputs[index].nCode = nCode
	
	GameLib.SetKeyBindings(bindings)
	
	self.log:Debug("Bound binding for '" .. actionName .. "' at index " .. index .. ".")
end

function KeyUtils:Unbind(actionName, index, pBindings)
	assert(not GameLib.GetPlayerUnit():IsInCombat(), "In combat, changing bindings is not possible at this moment.")
	
	local bindings = pBindings or GameLib.GetKeyBindings();
	local binding = self:GetBindingByActionName(bindings, actionName)

	if index == nil then 
		for _, i in ipairs(binding.arInputs) do
			binding.arInputs[i].eDevice = 0
			binding.arInputs[i].nCode = 0    
		end		

		self.log:Debug("Unbound binding for '" .. actionName .. "' at index " .. i .. ".")
	else 
		binding.arInputs[index].eDevice = 0
		binding.arInputs[index].nCode = 0
		
		self.log:Debug("Unbound binding for '" .. actionName .. "' at index " .. index .. ".")
	end

	GameLib.SetKeyBindings(bindings)
end

-- Register Library
Apollo.RegisterPackage(KeyUtils, "Blaz:Lib:KeyUtils-0.2", 1, {})