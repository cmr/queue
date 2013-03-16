local tweed = require "tweed"
local data = require "data"
local latte = require "latte"

local GET, POST = tweed.GET, tweed.POST

local site = tweed.make_site {
  about = function(context)
    local res = context.response
    res.status = 200
    res.type  = 'html'
    res:write(latte.render("about.latte"))
  end,
  signup = {
    [GET] = function(context)
      local res = context.response
      res:html(latte.render("signup.latte"))
    end,
    [POST] = function(context)
      local res = context.response
      local params = context.request:form_body()
      local success, errormsg = data.signup(params)
      if not success then
        res.status = 400
        res:html(latte.render("error.latte", {msg = errormsg}))
      else
        res:redirect("/")
      end
    end
  },
  ["string:person"] = function(person, context)
    local res = context.response
    local queue = data.queue_for_person(person)
    if queue then
      res:html(latte.render("person.latte", {queue = queue, person = person}))
    else
      res:e404(latte.render("404.latte"), context)
    end
  end
}

function site.error_handler(context, errmsg)
  res:html(latte.render("error.latte"), {msg = errmsg})
end

return site
