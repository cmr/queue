local config = require "config"
local inspect = require "inspect"
local ltn12 = require "ltn12"
local http = require "socket.http"
local cjson = require "cjson"

local M = {}

function M.push(person, item, tags)
	local tab = {}
	print ("making request to " .. config.api_url .. person)
	local _, status = http.request{
		url = config.api_url .. person, 
		method = "POST",
		headers = {["Content-Length"]=#item},
		source = ltn12.source.string(item),
		sink = ltn12.sink.table(tab)
	}

	print ("got " .. table.concat(tab))
	return status == 200, cjson.decode(table.concat(tab))
end

function M.getall(person)
	local tab = {}
	local _, status = http.request{
		url = config.api_url .. person, 
		method = "GET",
		sink = ltn12.sink.table(tab)
	}

	return status == 200, cjson.decode(table.concat(tab))
end

function M.pop(person)
	local suc, things = M.getall(person)
	if not suc then return suc, things end

	local item = things[1]

	suc, things = M.delete(person, item.id)
	if not suc then
		msg = "(warning: failed to remove item!) "
	else
		msg = ""
	end

	return true, msg .. item.content
end

function M.getbytag(person, tag)
	local tab = {}
	local _, status = http.request{
		url = config.api_url .. person .. '?tag=' .. tag, 
		method = "GET",
		sink = ltn12.sink.table(tab)
	}

	return status == 200, cjson.decode(table.concat(tab))
end

function M.delete(person, id)
	local tab = {}
	local _, status = http.request{
		url = config.api_url .. person .. '?id=' .. id, 
		method = "DELETE",
		sink = ltn12.sink.table(tab)
	}

	return status == 200, cjson.decode(table.concat(tab))
end

return M
