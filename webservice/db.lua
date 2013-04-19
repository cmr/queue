local config = require "config".db
local luasql = require "luasql.postgres"
local uuid = require "uuid"
local M = {}

local env = assert(luasql.postgres())

function M.get_user(context, username)
	local conn = assert(env:connect(config.name, config.user, config.pass,
	                                config.host, config.port))
	username = conn:escape(username)
	-- first, look for any aliases
	local userid
	userid = conn:execute(("SELECT userid FROM aliases WHERE alias = '%s'"):format(username)):fetch()
	if userid == nil then
		-- no? ok, look for a "real" user
		userid = conn:execute(("SELECT userid FROM users WHERE username = '%s'"):format(username)):fetch()
	end

	if userid == nil then
		-- still nothing? :(
		context.response:err(404, {code = 1, msg = "no such user"})
	end

	conn:close()
	return userid
end

function M.add_item(context, username, content, tags)
	local conn = assert(env:connect(config.name, config.user, config.pass,
	                                config.host, config.port))

	local userid = M.get_user(context, username)
	if userid == nil then
		return false
	end

	local query = [[ INSERT INTO items (itemid, content, sorted, userid) VALUES ('%s', '%s', FALSE, '%s'); ]]
	query = query:format(uuid.new(), conn:escape(content), userid)
	local suc, err = conn:execute(query)

	conn:commit()
	conn:close()

	return true
end

function M.get_all_by_user(context, username, tag)
	local conn = assert(env:connect(config.name, config.user, config.pass,
	                                config.host, config.port))

	local userid = M.get_user(context, username)
	if not userid then
		return
	end

	local query = [[ SELECT itemid, content, sort_index FROM items WHERE userid = '%s'; ]]
	local cursor = conn:execute(query:format(userid))
	local results = {}
	for i = 1, cursor:numrows() do
		local id, content, idx = cursor:fetch()
		results[i] = {id=id, content=content, idx=idx or -1}
	end

	cursor:close()
	conn:close()

	return results
end

function M.get_item(context, username, id)
	local conn = assert(env:connect(config.name, config.user, config.pass,
	                                config.host, config.port))

	local userid = M.get_user(context, username)
	if not userid then
		return
	end

	local query = [[ SELECT itemid, content, sort_index FROM items WHERE userid = '%s' AND itemid = '%s'; ]]
	local cursor = conn:execute(query:format(userid, conn:escape(id)))
	local results = {}
	for i = 1, cursor:numrows() do
		local id, content, idx = cursor:fetch()
		results[i] = {id=id, content=content, idx=idx or -1}
	end

	cursor:close()
	conn:close()

	return results
end

function M.delete_item(context, username, itemid)
	local conn = assert(env:connect(config.name, config.user, config.pass,
	                                config.host, config.port))

	local userid = M.get_user(context, username)
	if not userid then
		return
	end

	local query = [[ DELETE FROM items WHERE userid = '%s' AND itemid = '%s']]
	query = query:format(userid, conn:escape(itemid))
	conn:execute(query)

	conn:commit()
	conn:close()
end

return M
