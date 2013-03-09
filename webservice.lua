local json = require "cjson"

function run(wsapi_env)
	local success, table = pcall(function() json.decode(wsapi_env.input:read()) end)
	if not success then
		return 400, {["Content-Type"] = "application/json"}, coroutine.wrap(function() end)
	else
		local command = table.command
		local person = table.person
		local item = table.item
		print(("%s %s %s"):format(command, person, item))
		local function suc()
			coroutine.yield([[{"success": true}]])
		end
		return 200, {["Content-Type"] = "application/json"}, coroutine.wrap(suc)
	end
end
