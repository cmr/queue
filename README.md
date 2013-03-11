queue -- keeping track of things

Dependencies for irc bot:

lanes, lpeg, luasocket

Dependencies for web interface:

luasql, lua-cjson, luuid, a running postgres server

Also you'll need to be running luajit / lua patched with coco, because there's
a bug in the current webservice.lua where `wsapi_env.input:read()` raises a
"cannot yield across metamethod/C boundary" error. I couldn't track it down,
patches welcome.
