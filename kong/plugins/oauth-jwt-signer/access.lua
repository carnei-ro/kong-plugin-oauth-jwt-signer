local plugin_name  = ({...})[1]:match("^kong%.plugins%.([^%.]+)")
local oauth        = require("kong.plugins." .. plugin_name .. ".oauth")
local state_utils  = require("kong.plugins." .. plugin_name .. ".state_utils")
local claims_utils = require("kong.plugins." .. plugin_name .. ".claims_utils")
local jwt_utils    = require("kong.plugins." .. plugin_name .. ".jwt_utils")

local kong         = kong
local cjson        = require("cjson.safe").new()

cjson.decode_array_with_array_mt(true)

local _M = {}

function _M.execute(conf)
  local state = kong.request.get_query_arg("state")
  local code = kong.request.get_query_arg("code")
  if ((not state) or (not code)) then
    kong.response.exit(400, {["err"] = "Missing query param 'state' and/or 'code'"})
  end

  local decoded_state, err, state_version = state_utils:validate_and_decode_state(
                                                          state,
                                                          conf['state_secret'],
                                                          conf['state_algorithm'])
  if err then
    kong.response.exit(400, {["err"] = err })
  end

  local parsed_state, err = state_utils:parse_state(state_version, decoded_state)
  if err then
    kong.response.exit(400, {["err"] = err })
  end

  local token_tbl, err = oauth:request_access_token(
    conf,
    code,
    (kong.request.get_scheme() .. '://' .. kong.request.get_host() .. kong.request.get_path())
  )
  if err then
    kong.response.exit(400, {["err"] = err })
  end

  local profile, err = oauth:request_profile(
    conf,
    token_tbl["access_token"],
    token_tbl["id_token"]
  )
  if err then
    kong.response.exit(400, {["err"] = err })
  end

  local claims = claims_utils:generate_claims_table(conf, profile)
  local jwt, err = jwt_utils:sign_token(conf, claims)
  if err then
    kong.response.exit(400, {["err"] = err })
  end

  local status_code = 302
  local payload = {}
  local headers = {}

  if conf['jwt_cookie'] then
    local cookie_tail = ";version=1;path=/;Max-Age=" .. (conf['jwt_validity'] - 5)
    cookie_tail = conf['jwt_cookie_secure'] and (cookie_tail .. ";secure") or cookie_tail
    cookie_tail = conf['jwt_cookie_http_only'] and (cookie_tail .. ";httponly") or cookie_tail
    cookie_tail = conf['jwt_cookie_domain'] and (cookie_tail .. ";domain=" .. conf['jwt_cookie_domain']) or cookie_tail
    headers['Set-Cookie'] = (conf['jwt_cookie_name'] .. "=" .. jwt .. cookie_tail)
  end

  if conf['jwt_response'] then
    status_code = conf['jwt_response_status_code']
    payload[conf['jwt_response_payload_key']] = jwt
  else
    headers['Location'] = parsed_state['redirect']
  end
  
  return kong.response.exit(status_code, payload, headers)
end

return _M
