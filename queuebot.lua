require "luarocks.loader"
require "irc"
local config = require "config".irc
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
	local tab = {}
	local req = item
	local _, status

	if command == "push" then
		_, status = http.request{
			url = "http://queue.octayn.net/webservice.lua/" .. account, 
			method = "POST",
			headers = {
				["Content-Length"] = #req,
				["Content-Type"] = "application/json"
			},
			source = ltn12.source.string(req),
			sink = ltn12.sink.table(tab)
		}
	end

	if status ~= 200 then
		linda:set(id, false)
		print("http req failed: " .. tostring(status) .. tostring(table.concat(tab)))
	else
		linda:set(id, true)
	end
end)

function target(message)
	nick, command, item = re.match(message, "{[^:]*} ': ' {[^ ]*} ' ' {.*}")
	if nick == nil or command == nil or item == nil then
		return nil
	end
	return nick, command, item
end

commands = {
	push = true,
	pop = true
}

local qb = irc.new { nick = config.nick }

qb:hook("OnChat", function(user, channel, message)
	nick, command, item = target(message)
	if nick == nil then
		return
	end

	if commands[command] then
		local id_ = tostring(id)
		id = id + 1
		send_request(command, nick, item, id_)
		queued_requests[id_] = channel
		qb:sendChat(channel, ("done [%s]"):format(id_))
	end
end)

qb:connect(config.network)

for _, channel in ipairs(config.channels) do
	qb:join(channel)
end

while true do
	qb:think()
	for k,v in pairs(queued_requests) do
		local val = linda:get(k)
		if val == false then
			queued_requests[k] = nil
			qb:sendChat(v, ("%s failed!"):format(k))
		end
	end
	sleep(0.3)
end
