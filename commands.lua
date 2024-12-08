local function startsWith(str, start)
	return str:sub(1, #start) == start
end

local function assertf(condition, fmessage, ...)
	return assert(condition, string.format(fmessage, ...))
end

local function newInstance()
	local commands = {
		prefix = '/',
		aliases = {},
		commands = {},
	}
	
	function commands.create(cfg)
		local name = cfg.name
		local desc = cfg.desc or 'No description'
		local places = cfg.places or {}
		local aliases = cfg.aliases or {}
		local callback = cfg.callback

		assert(name and name:match('^%s*$') == nil, 'field "name" not found or is empty')
		assert(callback or type(callback) == 'function', 'field "callback" not provided or is not a function')

		local foundAlias = commands.aliases[name]
		local foundCommand = commands.commands[name]

		assertf(
			(foundAlias or foundCommand) == nil,
			'command %q conflicts with an existing %s', name, foundAlias and 'alias' or 'command')

		commands.commands[name] = {
			desc = desc,
			places = places,
			aliases = {},
			callback = callback
		}

		for _, alias in ipairs(aliases) do
			assertf(
				(commands.commands[alias] or commands.aliases[alias]) == nil,
				'alias %q conflicts with an existing %s',alias, commands.aliases[alias] and 'alias' or 'command')

			table.insert(commands.commands[name].aliases, alias)
			commands.aliases[alias] = name
		end
	end

	function commands.parse(message, enforcePrefix)
		local args = {}

		for word in message:gmatch('[%w%p]+') do
			table.insert(args, word)
		end

		if not args[1] then return true end

		local command = args[1]:lower()
		local hasPrefix = startsWith(command, commands.prefix)
		command = hasPrefix and command:sub(#commands.prefix + 1) or command

		if not hasPrefix and enforcePrefix then
			return false, 'prefix not found in message'
		end

		local found = commands.commands[commands.aliases[command] or command]

		if not found then
			return false, string.format('command %q does not exist', command)
		end

		if #found.places > 0 and not table.find(found.places, game.PlaceId) then
			return false, string.format('command %q is not available in this place', command)
		end

		return pcall(found.callback, (table.unpack or unpack)(args, 2))
	end
	
	return commands
end

return newInstance()
