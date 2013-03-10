local config = require "config"
local luasql = require "luasql.postgres"
local json = require "cjson"

local env = luasql.postgres()
local conn = env:connect(config.db.name, config.db.user, config.db.pass, config.db.host, config.db.port)

function run(wsapi_env)
	local success, table = pcall(function() json.decode(wsapi_env.input:read()) end)
	if not success then
		return 400, {["Content-Type"] = "application/json"}, coroutine.wrap(function() end)
	else
		local command = table.command
		local person = table.person
		local item = table.item
		local query = [[ WITH uid AS (SELECT userid FROM users WHERE username = '%s')
		INSERT INTO items (itemid, content, sorted, user) VALUES ('%s', '%s', FALSE, uid); ]]
		print(("%s %s %s"):format(command, person, item))
		local function suc()
			coroutine.yield([[{"success": true}]])
		end
		return 200, {["Content-Type"] = "application/json"}, coroutine.wrap(suc)
	end
end
