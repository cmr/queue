module(..., package.seeall)

local config = require "config"
local luasql = require "luasql.postgres"
local json = require "cjson"
local uuid = require "uuid"

local env = assert(luasql.postgres())
local conn = assert(env:connect(config.db.name, config.db.user, config.db.pass, config.db.host, config.db.port))

local function error_()
	return 400, {["Content-Type"] = "application/json"}, coroutine.wrap(function()
		coroutine.yield([[{"success": false}]])
	end)
end

function run(wsapi_env)
	local req = wsapi_env.input:read()
	print(req)
	local success, table = pcall(function() return json.decode(req) end)
	if not success then
		return error_()
	else
		local command = table.command
		local account = table.account
		local item = table.item
		if command == "enqueue" then
			local query = [[ INSERT INTO items (itemid, content, sorted, userid) VALUES ('%s', '%s', FALSE,
			(SELECT userid FROM users WHERE username = '%s')); ]]
			assert(conn:execute(query:format(uuid.new(), conn:escape(item), conn:escape(account))))
			conn:commit()
		else
			return error_()
		end

		return 200, {["Content-Type"] = "application/json"}, coroutine.wrap(function()
			coroutine.yield([[{"success": true}]])
		end)
	end
end
