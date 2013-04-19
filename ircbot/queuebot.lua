require "luarocks.loader"
require "irc"

local api = require "api"

local config = require "config"
local inspect = require "inspect"

local re = require "re"
local sleep = require "socket".sleep

local pat = ("'%s: ' {[^ ]*} ' ' {[^ ]*} ' ' {.*}"):format(config.irc.nick)

function target(message)
	local command, nick, item = re.match(message, pat)
	if nick == nil or command == nil or item == nil then
		return nil
	end
	return nick, command, item
end

commands = {
	push = "push",
	pop = "pop",
	list = "getall"
}

local qb = irc.new { nick = config.irc.nick }

qb:hook("OnChat", function(user, channel, message)
	local nick, command, item

	if message == config.irc.nick .. ": pop" then
		nick, command = user.nick, "pop"
	elseif message == config.irc.nick .. ": list" then
		nick, command = user.nick, "list"
	else
		nick, command, item = target(message)
		if nick == nil then
			return
		end
	end

	if commands[command] then
		local suc, res = api[commands[command]](nick, item)
		if suc then
			if command == "list" then
				for k, v in ipairs(res) do
					qb:sendChat(user.nick, ("(%s) %s"):format(v.id,v.content))
				end
			else
				qb:sendChat(channel, "Success: " .. res or '')
			end
			return
		else
			qb:sendChat(channel, "Error: " .. res.msg)
		end
	end
end)

qb:connect(config.irc.network)

for _, channel in ipairs(config.irc.channels) do
	qb:join(channel)
end

while true do
	qb:think()
	sleep(0.05)
end
