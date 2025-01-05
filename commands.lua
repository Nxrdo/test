print(debug.info(1, 'n'))

if debug.info(1, 'n') ~= 'cool_function' then
	return
end

local function startsWith(s, prefix)
	return s:sub(1, #prefix) == prefix
end

local function assertf(condition, message, ...)
	return assert(condition, string.format(message, ...))
end

local function newInstance()
	local this = {
		prefix = '/',
		aliases = {},
		commands = {},
		metadata = {},
	}

	local __metadata = {}

	function this.create(cfg)
		local name = cfg.name
		local args = cfg.args or {}
		local desc = cfg.desc or 'No description'
		local places = cfg.places or {}
		local aliases = cfg.aliases or {}
		local callback = cfg.callback

		assert(name and name:match('^%s*$') == nil, 'field "name" not found or is empty')
		assert(callback and type(callback) == 'function', 'field "callback" not provided or is not a function')

		local metadata = {
			name = name,
			desc = desc,
			args = args,
			places = places,
			aliases = {}
		}

		local foundCommand = this.commands[name]
		local foundAlias = this.aliases[name]

		assertf(
			(foundAlias or foundCommand) == nil,
			'command %q conflicts with an existing %s', name, foundAlias and 'alias' or 'command')

		this.commands[name] = callback

		for _, alias in ipairs(aliases) do
			assertf(
				(this.commands[alias] or this.aliases[alias]) == nil,
				'alias %q conflicts with an existing %s', alias, this.commands[alias] and 'command' or 'alias')

			table.insert(metadata.aliases, alias)
			this.aliases[alias] = name
		end

		__metadata[callback] = metadata
		table.insert(this.metadata, metadata)
	end

	function this.parse(message, enforcePrefix)
		local args = message:split(' ')

		if not args[1] then return true end

		local command = args[1]:lower()
		local hasPrefix = startsWith(command, this.prefix)
		command = hasPrefix and command:sub(#this.prefix + 1) or command

		if not hasPrefix and enforcePrefix then return true end

		local found = this.commands[this.aliases[command] or command]

		if not found then
			return false, string.format('failed to find command %q', command)
		end

		local meta = __metadata[found]

		if #meta.places > 0 and not table.find(meta.places, game.PlaceId) then
			return false, string.format('command %q is not avaliable in this place', command)
		end

		return pcall(found, (unpack or table.unpack)(args, 2))
	end

	return this
end

return newInstance()
