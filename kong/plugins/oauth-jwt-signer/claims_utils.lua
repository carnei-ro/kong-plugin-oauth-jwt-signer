local ngx_time = ngx.time

local _M = {}

local function claims_custom(profile, claims)
  claims["sub"] = profile["email"]
  claims["email_verified"] = profile["email_verified"] or nil
  claims["user"] = profile["email"]:match("([^@]+)@.+") or nil
  claims["domain"] = profile["email"]:match("[^@]+@(.+)") or nil
  claims["picture"] = profile["picture"] or nil
  claims["name"] = profile["name"] or nil
  claims["family_name"] = profile["family_name"] or nil
  claims["given_name"] = profile["given_name"] or nil
  claims["roles"] = profile["roles"] and profile["roles"] or nil
  return claims
end

local function claims_facebook(profile, claims)
  claims["sub"] = profile["email"] and profile["email"] or profile["id"]
  claims["user"] = profile["email"]:match("([^@]+)@.+")
  claims["domain"] = profile["email"]:match("[^@]+@(.+)")
  claims["name"] = profile["name"]
  claims["family_name"] = profile["last_name"]
  claims["given_name"] = profile["first_name"]
  claims["picture"] = profile["picture"]["data"]["url"] or nil
  claims["email_verified"] = profile["email_verified"] or nil
  claims["roles"] = profile["roles"] and profile["roles"] or nil
  return claims
end

local function claims_github(profile, claims)
  if type(profile["email"]) == 'userdata' then
    claims["sub"] = profile["login"]
    claims["user"] = profile["login"]
  else
    claims["sub"] = profile["email"]
    claims["user"] = profile["email"]:match("([^@]+)@.+")
    claims["domain"] = profile["email"]:match("[^@]+@(.+)")
  end
  claims["name"] = profile["name"]
  return claims
end

local function claims_gitlab(profile, claims)
  claims["sub"] = profile["email"]
  claims["email_verified"] = profile["email_verified"]
  claims["user"] = profile["email"]:match("([^@]+)@.+")
  claims["domain"] = profile["email"]:match("[^@]+@(.+)")
  claims["name"] = profile["name"]
  claims["picture"] = profile["picture"]
  claims["groups"] = profile["groups"] and profile["groups"] or nil
  claims["nickname"] = profile["nickname"]
  claims["profile"] = profile["profile"]
  return claims
end

local function claims_google(profile, claims)
  claims["sub"] = profile["email"]
  claims["email_verified"] = profile["verified_email"] or nil
  claims["user"] = profile["email"]:match("([^@]+)@.+") or nil
  claims["domain"] = profile["email"]:match("[^@]+@(.+)") or nil
  claims["picture"] = profile["picture"] or nil
  claims["name"] = profile["name"] or nil
  claims["family_name"] = profile["family_name"] or nil
  claims["given_name"] = profile["given_name"] or nil
  claims["roles"] = profile["roles"] and profile["roles"] or nil
  return claims
end

local function claims_microsoft(profile, claims)
  claims["sub"] = profile["userPrincipalName"]
  claims["name"] = profile["displayName"]
  claims["user"] = profile["userPrincipalName"]:match("([^@]+)@.+")
  claims["domain"] = profile["userPrincipalName"]:match("[^@]+@(.+)")
  claims["given_name"] = profile["givenName"]
  claims["family_name"] = profile["surname"]
  return claims
end

local function claims_yandex(profile, claims)
  claims["sub"] = profile["login"]
  claims["name"] = profile["real_name"]
  claims["user"] = profile["login"]:match("([^@]+)@.+")
  claims["domain"] = profile["login"]:match("[^@]+@(.+)")
  claims["given_name"] = profile["first_name"]
  claims["family_name"] = profile["last_name"]
  return claims
end

local function claims_zoho(profile, claims)
  claims["sub"] = profile["Email"]
  claims["name"] = profile["Display_Name"]
  claims["user"] = profile["Email"]:match("([^@]+)@.+")
  claims["domain"] = profile["Email"]:match("[^@]+@(.+)")
  claims["given_name"] = profile["First_Name"]
  claims["family_name"] = profile["Last_Name"]
  return claims
end

local claims_provider = {
  ["custom"]    = claims_custom,
  ["facebook"]  = claims_facebook,
  ["github"]    = claims_github,
  ["gitlab"]    = claims_gitlab,
  ["google"]    = claims_google,
  ["microsoft"] = claims_microsoft,
  ["yandex"]    = claims_yandex,
  ["zoho"]      = claims_zoho,
}

function _M:generate_claims_table(conf, profile)
  local provider_alias = (conf['oauth_provider_alias'] and (conf['oauth_provider_alias'] ~= "")) and conf['oauth_provider_alias'] or conf['oauth_provider']
  local claims = {
    ["iss"] = conf['jwt_issuer'],
    ["iat"] = ngx_time(),
    ["exp"] = ngx_time() + conf['jwt_validity'],
    ["provider"] = provider_alias,
  }
  if claims_provider[conf.oauth_provider] == nil then
    for k,v in pairs(claims) do profile[k] = v end
    profile['sub'] = profile['sub'] and profile['sub'] or (profile["email"] or profile["Email"] or profile["name"] or profile["login"] or profile["user"] or profile["userPrincipalName"] or nil)
    return profile
  end
  claims = claims_provider[conf.oauth_provider](profile, claims)
  return claims
end


return _M
