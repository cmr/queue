local tweed = require "tweed"
local cjson = require "cjson"

local config = require "config"
local db = require "db"

local site = tweed.make_site {
	[tweed.string 'username'] = {
		[tweed.POST] = function(context)
			-- enqueue item
			local item = context.request.body

			if db.add_item(context, context.params.username, item) then
				context.response:json(cjson.encode({success = true}))
			end
		end,
		[tweed.GET] = function(context)
			local items = db.get_all_by_user(context, context.params.username)
            if items then
				context.response:json(cjson.encode(items))
			end
		end,
		[tweed.DELETE] = function(context)
			local id = context.request.body
			db.delete_item(context, id, context.params.username)

			context.response:json(cjson.encode({success=true}))
		end,
	}
}

site.error_handlers = {}

site.error_handlers.default = function(response, status, ...)
	local res = response
	local err = ...
	if type(err) == "table" then
		res:json(cjson.encode({success=false, code=err.code, msg=err.msg}))
	else
		res:json(cjson.encode({success=false, msg={...}}))
	end
end

return site
