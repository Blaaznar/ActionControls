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
			Print(string.format("[%s] : %s", self.logName, tostring(message)))
		else
			Print(string.format("[%s] : %s", self.logName, string.format(message, unpack(arg))))
		end
	end
end

function SimpleLog:Info (message, ...) 
	if self.logLevel > 2 then
		if arg == nil then
            ChatSystemLib.PostOnChannel(2, string.format("[%s] : %s", self.logName, tostring(message)))
		else
			ChatSystemLib.PostOnChannel(2, string.format("[%s] : %s", self.logName, string.format(message, unpack(arg))))
		end
	end
end

function SimpleLog:Warn (message, ...) 
	if self.logLevel > 1 then
		if arg == nil then
			ChatSystemLib.PostOnChannel(2, string.format("[%s - Warning] : %s", self.logName, tostring(message)))
		else
			ChatSystemLib.PostOnChannel(2, string.format("[%s - Warning] : %s", self.logName, string.format(message, unpack(arg))))
		end
	end
end

function SimpleLog:Error (message, ...) 
	if self.logLevel > 0 then
		if arg == nil then
			ChatSystemLib.PostOnChannel(2, string.format("[%s - Error] : %s", self.logName, tostring(message)))
		else
			ChatSystemLib.PostOnChannel(2, string.format("[%s - Error] : %s", self.logName, string.format(message, unpack(arg))))
		end
	end
end

Apollo.RegisterPackage(SimpleLog, "Blaz:Lib:SimpleLog-0.1", 1, {})
