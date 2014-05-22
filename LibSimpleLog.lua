local SimpleLog = {}

function SimpleLog:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.logLevel = 3
	o.logName = ""
	
    return o
end

function SimpleLog:SetLogLevel(logLevel)
	self.logLevel = tonumber(logLevel)
end

function SimpleLog:SetLogName(logName)
	self.logName = logName
end

function SimpleLog:Debug (message) 
	if self.logLevel > 3 then
		Print("[" .. self.logName .. " - Debug] : " .. tostring(message))
	end
end

function SimpleLog:Info (message) 
	if self.logLevel > 2 then
		Print("[" .. self.logName .. "] : " .. tostring(message))
	end
end

function SimpleLog:Warn (message) 
	if self.logLevel > 1 then
		Print("[" .. self.logName .. " - Warning] : " .. tostring(message))
	end
end

function SimpleLog:Error (message) 
	if self.logLevel > 0 then
		local strMessage = tostring(message)
	
		Print("[" .. self.logName .. " - Error] : " .. strMessage)
		Apollo.AddAddonErrorText(self, strMessage)
	end
end

Apollo.RegisterPackage(SimpleLog, "Blaz:Lib:SimpleLog-0.1", 1, {})
