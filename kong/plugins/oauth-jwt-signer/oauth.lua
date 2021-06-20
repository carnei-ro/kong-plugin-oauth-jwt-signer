local http         = require("resty.http")
local cjson        = require("cjson.safe").new()
local encode_args  = ngx.encode_args

cjson.decode_array_with_array_mt(true)

local _M = {}

function _M:request_access_token(conf, code, redirect_uri)
  local request = http.new()

  request:set_timeout(conf['oauth_token_endpoint_timeout'])

  local res, err = request:request_uri(conf['oauth_token_endpoint'], {
      method = conf['oauth_token_endpoint_method'],
      body = encode_args({
        code          = code,
        client_id     = conf['oauth_client_id'],
        client_secret = conf['oauth_client_secret'],
        redirect_uri  = redirect_uri,
        grant_type    = conf['oauth_token_endpoint_grant_type'],
      }),
      headers = {
        ["Content-type"] = "application/x-www-form-urlencoded"
      },
      ssl_verify = conf['oauth_ssl_verify'],
  })
  if not res then
    return nil, (err or "auth token request failed: " .. (err or "unknown reason"))
  end

  if res.status ~= 200 then
    return nil, "received " .. res.status .. " from ".. conf['oauth_token_endpoint'] .. ": " .. res.body
  end

  return cjson.decode(res.body), nil
end


function _M:request_profile(conf, access_token, id_token)
  local request = http.new()

  request:set_timeout(conf['oauth_userinfo_endpoint_timeout'])

  local querystring = conf['oauth_userinfo_endpoint_querystring_more']
  querystring['authorization'] = conf['oauth_userinfo_endpoint_querystring_authorization'] and id_token or nil
  querystring['access_token'] = conf['oauth_userinfo_endpoint_querystring_access_token'] and access_token or nil
  local url_suffix = ""
  if next(querystring) then
    url_suffix = "?" .. encode_args(querystring)
  end

  local headers = {
    ["Accept"] = "application/json",
  }
  headers['Authorization'] = conf['oauth_userinfo_endpoint_header_authorization'] and
                              (conf['oauth_userinfo_endpoint_header_authorization_prefix'] .. " " .. access_token)
                              or nil

  local res, err = request:request_uri(conf['oauth_userinfo_endpoint'] .. url_suffix, {
    method = conf['oauth_userinfo_endpoint_method'],
    ssl_verify = conf['oauth_ssl_verify'],
    headers = headers,
  })
  if not res then
    return nil, "auth info request failed: " .. (err or "unknown reason")
  end

  if res.status ~= 200 then
    return nil, "received " .. res.status .. " from " .. conf['oauth_userinfo_endpoint']
  end

  return cjson.decode(res.body), nil
end

return _M
