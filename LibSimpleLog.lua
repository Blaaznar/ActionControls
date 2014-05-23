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

function SimpleLog:Debug (message, ...) 
	if self.logLevel > 3 then
		if arg == nil then
			Print(string.format("[%s - Debug] : %s", self.logName, tostring(message)))
		else
			Print(string.format("[%s - Debug] : %s", self.logName, string.format(message, unpack(arg))))
		end
	end
end

function SimpleLog:Info (message, ...) 
	if self.logLevel > 2 then
		if arg == nil then
			Print(string.format("[%s] : %s", self.logName, tostring(message)))
		else
			Print(string.format("[%s] : %s", self.logName, string.format(message, unpack(arg))))
		end
	end
end

function SimpleLog:Warn (message, ...) 
	if self.logLevel > 1 then
		if arg == nil then
			Print(string.format("[%s - Warning] : %s", self.logName, tostring(message)))
		else
			Print(string.format("[%s - Warning] : %s", self.logName, string.format(message, unpack(arg))))
		end
	end
end

function SimpleLog:Error (message, ...) 
	if self.logLevel > 0 then
		--local strMessage = tostring(message)
	
		if arg == nil then
			Print(string.format("[%s - Error] : %s", self.logName, tostring(message)))
		else
			for _, a in ipairs(arg) do
				a = tostring(a)
			end
		
			Print(string.format("[%s - Error] : %s", self.logName, string.format(message, unpack(arg))))
		end
		--Apollo.AddAddonErrorText(self, strMessage)
	end
end

Apollo.RegisterPackage(SimpleLog, "Blaz:Lib:SimpleLog-0.1", 1, {})
