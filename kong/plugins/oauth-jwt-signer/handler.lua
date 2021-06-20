local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")
local access = require("kong.plugins." .. plugin_name .. ".access")
local oauth_providers_defaults = require("kong.plugins." .. plugin_name .. ".oauth_providers_defaults")

local plugin = {
  PRIORITY = 1000,
  VERSION = "0.1.0",
}

function plugin:access(plugin_conf)
  plugin_conf = oauth_providers_defaults:set_defaults(plugin_conf)
  access.execute(plugin_conf)
end

return plugin
