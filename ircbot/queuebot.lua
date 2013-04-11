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
	pop = "pop"
}

local qb = irc.new { nick = config.irc.nick }

qb:hook("OnChat", function(user, channel, message)
	local nick, command, item

	if message ~= config.irc.nick .. ": pop" then
		nick, command, item = target(message)
		if nick == nil then
			return
		end
	else
		nick, command = user.nick, "pop"
	end

	if commands[command] then
		local suc, res = api[commands[command]](nick, item)
		if suc then
			qb:sendChat(channel, "Success: " .. res)
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
