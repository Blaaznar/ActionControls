-------------------------------------------------------------------------------
-- KeyBindingUtils
-------------------------------------------------------------------------------
local KeyBindingUtils = {}

function KeyBindingUtils:new(o, logInst)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.log = logInst

    return o
end

function KeyBindingUtils:Bind(bindings, actionName, index, inputKey, unbindConflictingBindings)
	assert(not GameLib.GetPlayerUnit():IsInCombat(), "In combat, changing bindings is not possible at this moment.")
	assert(bindings, "Bindings not provided.")
	assert(index, "Binding index not provided.")
	assert(inputKey, "InputKey not provided.")
	
	if unbindConflictingBindings then
		self:UnbindByInput(bindings, inputKey)
	else
		assert(not self:IsBound(bindings), 
			self.log:Warn("'%s' is already bound, please manually unbind it from the game's Keybind window.", tostring(inputKey)))
	end
	
	local binding = self:GetBindingByActionName(bindings, actionName)
    if binding ~= nil then
        binding.arInputs[index].eDevice = inputKey.eDevice
        binding.arInputs[index].eModifier = inputKey.eModifier
        binding.arInputs[index].nCode = inputKey.nCode
        
        self.log:Debug("Bound '%s' binding at index %s to: '%s'", actionName, tostring(index), tostring(inputKey))
    else
        self.log:Debug("Binding '%s' not found.", actionName)
    end
end

function KeyBindingUtils:Unbind(bindings, actionName, index)
	assert(bindings, "Bindings not provided.")
	local binding = self:GetBindingByActionName(bindings, actionName)

	if index == nil then 
		for _, i in ipairs(binding.arInputs) do
			binding.arInputs[i].eDevice = 0
            binding.arInputs[i].eModifier = 0
			binding.arInputs[i].nCode = 0    
		end		

		self.log:Debug("Unbound '%s' binding at index %s.", actionName, tostring(i))
	else 
		binding.arInputs[index].eDevice = 0
        binding.arInputs[index].eModifier = 0        
		binding.arInputs[index].nCode = 0
		
		self.log:Debug("Unbound '%s' binding at index %s.", actionName, tostring(index))
	end
end

function KeyBindingUtils:UnbindByInput(bindings, inputKey)
	assert(bindings, "Bindings not provided.")
    assert(inputKey, "InputKey not provided.")
    
	if inputKey.eDevice == 0
       and inputKey.eModifier == 0
       and inputKey.nCode == 0 
    then
		return
	end

	for _, binding in ipairs(bindings) do
		for _, arInput in ipairs(binding.arInputs) do
			if arInput.eDevice == inputKey.eDevice 
            and arInput.eModifier == inputKey.eModifier
            and arInput.nCode == inputKey.nCode 
            then
				arInput.eDevice = 0
                arInput.eModifier = 0
				arInput.nCode = 0
				self.log:Debug("Unbound '%s' from '%s'.", tostring(inputKey), binding.strAction)
			end
		end
	end
end

function KeyBindingUtils:CommitBindings(bindings)
	assert(bindings, "Bindings not provided.")
	assert(not GameLib.GetPlayerUnit():IsInCombat(), "In combat, changing bindings is not possible at this moment.")

	GameLib.SetKeyBindings(bindings)
	self.log:Debug("Bindings saved.")
end

function KeyBindingUtils:IsBound(bindings, inputKey)
	return self:GetBinding(bindings, inputKey) ~= nil
end

-- TODO: use GameLib.GetCharInputKeySet!!!!!!!!!!!!!!!!!!!!!!!!

function KeyBindingUtils:GetBinding(bindings, inputKey)
	assert(inputKey, "InputKey not provided.")

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

function KeyBindingUtils:GetBindingByActionName(bindings, actionName)
	assert(bindings, "Bindings not provided.")
	assert(actionName, "Action names list not provided.")

	return self:GetBindingListByActionNames(bindings, actionName)[1]
end

function KeyBindingUtils:GetBindingListByActionNames(bindings, ...)
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
Apollo.RegisterPackage(KeyBindingUtils, "Blaz:Lib:KeyBindingUtils-0.2", 1, {})
