local config = require "config"
local luasql = require "luasql.postgres"
local uuid = require "uuid"
local tweed = require "tweed"
local inspect = require "inspect"
local cjson = require "cjson"

local env = assert(luasql.postgres())

local site = tweed.make_site {
	[tweed.string 'username'] = {
		[tweed.POST] = function(context)
			-- enqueue item
			local item = context.request.body
			local conn = assert(env:connect(config.db.name, config.db.user, config.db.pass, config.db.host, config.db.port))
			local userid = conn:execute(("SELECT userid FROM users WHERE username = '%s'"):format(conn:escape(context.params.username))):fetch()
			if not userid then
				context.response:err(404, "no such user")
				return
			end

			print (item)
			local query = [[ INSERT INTO items (itemid, content, sorted, userid) VALUES ('%s', '%s', FALSE, '%s'); ]]
			query = query:format(uuid.new(), conn:escape(item), conn:escape(userid))
			assert(conn:execute(query))
			conn:commit()
			assert(conn:close())
		end,
		[tweed.GET] = function(context)
			local itemid = context.request.body
			local conn = assert(env:connect(config.db.name, config.db.user, config.db.pass, config.db.host, config.db.port))
			local userid = conn:execute(("SELECT userid FROM users WHERE username = '%s'"):format(conn:escape(context.params.username))):fetch()
			if not userid then
				context.response:err(404, "no such user")
				return
			end

			local query = [[ SELECT itemid, content, sort_index FROM items WHERE userid = '%s'; ]]
			local cursor = conn:execute(query:format(userid))
			local results = {}
			for i = 1, cursor:numrows() do
				local id, content, idx = cursor:fetch()
				results[i] = {id=id, content=content, idx=idx or -1}
			end

			context.response:json(cjson.encode(results))
			assert(cursor:close())
			assert(conn:close())
		end,
		[tweed.DELETE] = function(context)
			local id = context.request.body
			local conn = assert(env:connect(config.db.name, config.db.user, config.db.pass, config.db.host, config.db.port))
			local userid = conn:execute(("SELECT userid FROM users WHERE username = '%s'"):format(conn:escape(context.params.username))):fetch()
			if not userid then
				context.response:err(404, "no such user")
				return
			end

			local query = [[ DELETE FROM items WHERE itemid = '%s'; ]]
			local cursor = conn:execute(query:format(id))

			context.response:json(cjson.encode({success=true}))
			assert(conn:close())
		end,
	}
}

site.error_handlers[400] = function(site, ...)
	local res = context.response
	res:json(cjson.encode({success=false, err={...}}))
end

return site
