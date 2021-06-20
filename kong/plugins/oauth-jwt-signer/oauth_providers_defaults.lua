local _M = {}

local function facebook(config)
  config.oauth_token_endpoint = "https://graph.facebook.com/v11.0/oauth/access_token"
  config.oauth_token_endpoint_grant_type = "authorization_code"
  config.oauth_token_endpoint_method = "POST"
  config.oauth_userinfo_endpoint = "https://graph.facebook.com/v11.0/me"
  config.oauth_userinfo_endpoint_method = "GET"
  config.oauth_userinfo_endpoint_header_authorization = false
  config.oauth_userinfo_endpoint_querystring_authorization = true
  config.oauth_userinfo_endpoint_querystring_access_token = true
  config.oauth_userinfo_endpoint_querystring_more = {["fields"] = 'id,first_name,last_name,middle_name,name,picture{url},short_name,email'}
  return config
end

local function github(config)
  config.oauth_token_endpoint = "https://github.com/login/oauth/access_token"
  config.oauth_token_endpoint_grant_type = "authorization_code"
  config.oauth_token_endpoint_method = "POST"
  config.oauth_userinfo_endpoint = "https://api.github.com/user"
  config.oauth_userinfo_endpoint_method = "GET"
  config.oauth_userinfo_endpoint_header_authorization_prefix = "Bearer"
  config.oauth_userinfo_endpoint_header_authorization = true
  config.oauth_userinfo_endpoint_querystring_authorization = false
  config.oauth_userinfo_endpoint_querystring_access_token = false
  config.oauth_userinfo_endpoint_querystring_more = {}
  return config
end

local function gitlab(config)
  config.oauth_token_endpoint = "https://gitlab.com/oauth/token"
  config.oauth_token_endpoint_grant_type = "authorization_code"
  config.oauth_token_endpoint_method = "POST"
  config.oauth_userinfo_endpoint = "https://gitlab.com/oauth/userinfo"
  config.oauth_userinfo_endpoint_method = "GET"
  config.oauth_userinfo_endpoint_header_authorization = false
  config.oauth_userinfo_endpoint_querystring_authorization = true
  config.oauth_userinfo_endpoint_querystring_access_token = true
  config.oauth_userinfo_endpoint_querystring_more = {}
  return config
end

local function google(config)
  config.oauth_token_endpoint = "https://accounts.google.com/o/oauth2/token"
  config.oauth_token_endpoint_grant_type = "authorization_code"
  config.oauth_token_endpoint_method = "POST"
  config.oauth_userinfo_endpoint = "https://www.googleapis.com/oauth2/v2/userinfo"
  config.oauth_userinfo_endpoint_method = "GET"
  config.oauth_userinfo_endpoint_header_authorization_prefix = "Bearer"
  config.oauth_userinfo_endpoint_header_authorization = true
  config.oauth_userinfo_endpoint_querystring_authorization = false
  config.oauth_userinfo_endpoint_querystring_access_token = false
  config.oauth_userinfo_endpoint_querystring_more = {}
  return config
end

local function microsoft(config)
  config.oauth_token_endpoint = "https://login.microsoftonline.com/common/oauth2/v2.0/token"
  config.oauth_token_endpoint_grant_type = "authorization_code"
  config.oauth_token_endpoint_method = "POST"
  config.oauth_userinfo_endpoint = "https://graph.microsoft.com/v1.0/me"
  config.oauth_userinfo_endpoint_method = "GET"
  config.oauth_userinfo_endpoint_header_authorization_prefix = "Bearer"
  config.oauth_userinfo_endpoint_header_authorization = true
  config.oauth_userinfo_endpoint_querystring_authorization = false
  config.oauth_userinfo_endpoint_querystring_access_token = false
  config.oauth_userinfo_endpoint_querystring_more = {}
  return config
end

local function yandex(config)
  config.oauth_token_endpoint = "https://oauth.yandex.com/token"
  config.oauth_token_endpoint_grant_type = "authorization_code"
  config.oauth_token_endpoint_method = "POST"
  config.oauth_userinfo_endpoint = "https://login.yandex.ru/info"
  config.oauth_userinfo_endpoint_method = "GET"
  config.oauth_userinfo_endpoint_header_authorization_prefix = "Bearer"
  config.oauth_userinfo_endpoint_header_authorization = true
  config.oauth_userinfo_endpoint_querystring_authorization = false
  config.oauth_userinfo_endpoint_querystring_access_token = false
  config.oauth_userinfo_endpoint_querystring_more = {}
  return config
end

local function zoho(config)
  config.oauth_token_endpoint = "https://accounts.zoho.com/oauth/v2/token"
  config.oauth_token_endpoint_grant_type = "authorization_code"
  config.oauth_token_endpoint_method = "POST"
  config.oauth_userinfo_endpoint = "https://accounts.zoho.com/oauth/user/info"
  config.oauth_userinfo_endpoint_method = "GET"
  config.oauth_userinfo_endpoint_header_authorization_prefix = "Zoho-oauthtoken"
  config.oauth_userinfo_endpoint_header_authorization = true
  config.oauth_userinfo_endpoint_querystring_authorization = false
  config.oauth_userinfo_endpoint_querystring_access_token = false
  config.oauth_userinfo_endpoint_querystring_more = {}
  return config
end

local defaults = {
  ["custom"]    = function(config) return config end,
  ["facebook"]  = facebook,
  ["github"]    = github,
  ["gitlab"]    = gitlab,
  ["google"]    = google,
  ["microsoft"] = microsoft,
  ["yandex"]    = yandex,
  ["zoho"]      = zoho,
}

function _M:set_defaults(config)
  if defaults[config.oauth_provider] == nil then
    return config
  end
  return defaults[config.oauth_provider](config)
end

return _M
