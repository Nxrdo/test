local api = {}
local methods = {}

local function startsWith(s, v)
	return s:sub(1, #v) == v
end

function api.New(prefix)
	return setmetatable({
		commands = {},
		prefix = prefix or '/'
	}, { __index = methods })
end

function methods:AddCommand(name, alias, callback)
	if not callback then
		callback, alias = alias, callback
	end
	
	if type(alias) == 'table' then
		for _, command in ipairs(alias) do
			self.commands[command] = callback
		end
	end
	
	self.commands[name] = type(callback) == 'function' and callback or alias
end

function methods:ParseCommand(speaker, input, prefix)
	prefix = prefix or self.prefix
	
	if not startsWith(input, prefix) then
		return false, 'Invalid prefix'
	end
	
	local split = input:split(' ')
	local command = split[1]:sub(#prefix + 1)
	
	if not self.commands[command] then
		return false, string.format('command \'%s\' does not exist', command)
	end
	
	local args = {table.unpack(split, 2)}
	
	return true, self.commands[command](args, speaker)
end

return api
