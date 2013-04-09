require "luarocks.loader"
require "irc"
local config = require "config"
local inspect = require "inspect"
local lanes = require "lanes".configure()
local linda = lanes.linda()

local re = require "re"
local sleep = require "socket".sleep
local id = 0
local queued_requests = {}

local send_request = lanes.gen("*", function(command, account, item, id)
	local http = require "socket.http"
	local ltn12 = require "ltn12"
	local cjson = require "cjson"

	local tab = {}

	if command == "push" then
		local _, status = http.request{
			url = config.api_url .. account, 
			method = "POST",
			headers = {["Content-Length"]=#item},
			source = ltn12.source.string(item),
			sink = ltn12.sink.table(tab)
		}
		if status ~= 200 then
			linda:set(id, false)
			print("http req failed: " .. tostring(status) .. tostring(table.concat(tab)))
		else
			linda:set(id, true)
		end
	elseif command == "pop" then
		local _, status = http.request{
			url = config.api_url .. account, 
			method = "GET",
			sink = ltn12.sink.table(tab)
		}
		if status ~= 200 then
			linda:set(id, false)
			print("http req failed: " .. tostring(status) .. tostring(table.concat(tab)))
		else
			local obj = cjson.decode(table.concat(tab))[1]
			linda:set(id, obj.content)
			local _, status = http.request{
				url = config.api_url .. account, 
				method = "DELETE",
				headers = {["Content-Length"]=#obj.id},
				source = ltn12.source.string(obj.id),
				sink = ltn12.sink.table(tab)
			}
		end
	end
end)

local pat = ("'%s: ' {[^ ]*} ' ' {[^ ]*} ' ' {.*}"):format(config.irc.nick)

function target(message)
	local command, nick, item = re.match(message, pat)
	if nick == nil or command == nil or item == nil then
		return nil
	end
	return nick, command, item
end

commands = {
	push = true,
	pop = true
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
		local id_ = tostring(id)
		id = id + 1
		queued_requests[id_] = channel
		send_request(command, nick, item, id_)
		qb:sendChat(channel, ("done [%s]"):format(id_))
	end
end)

qb:connect(config.irc.network)

for _, channel in ipairs(config.irc.channels) do
	qb:join(channel)
end

while true do
	qb:think()
	for k,v in pairs(queued_requests) do
		local val = linda:get(k)
		if val == false then
			queued_requests[k] = nil
			qb:sendChat(v, ("%s failed!"):format(k))
		elseif type(val) == "string" then
			queued_requests[k] = nil
			qb:sendChat(v, val)
		end
	end
	sleep(0.3)
end
