#!/usr/bin/env lua

require "wsapi.fastcgi"
local ws = require "webservice"

wsapi.fastcgi.run(ws.run)
