local openssl_hmac = require("resty.openssl.hmac")
local cjson        = require("cjson.safe").new()
local b64_decode   = require("ngx.base64").decode_base64url
local b64_encode   = require("ngx.base64").encode_base64url

cjson.decode_array_with_array_mt(true)

local _M = {}

function _M:validate_and_decode_state(state, key, alg)
  local state_tbl = cjson.decode(b64_decode(state))
  if not state_tbl then
    return nil, 'Could not parse state', nil
  end
  
  local signature, err = openssl_hmac.new(key, alg):final(state_tbl['d'])
  if err then
    return nil, err, nil
  end

  local signature_b64 = b64_encode(signature)
  if (state_tbl['s'] ~= signature_b64) then
    return nil, ('State signature does not match.\nState Signature: ' .. state_tbl['s'] .. ', Calculated Signature: ' .. signature_b64), nil
  end
  return state_tbl['d'], nil, state_tbl['v']
end

local parser = {
  ["v0"] = function(state_string) 
    local version, redirect = state_string:match("([^;]*)%;(.*)")
    if version ~= "v0" then
      return nil, "State version does not match state at state string."
    end
    return {
      ["redirect"] = redirect,
    }, nil
  end
}

function _M:parse_state(state_version, state_string)
  if parser[state_version] == nil then
    return nil, "Parser for State version " .. state_version .. " not implemented yet."
  end
  return parser[state_version](state_string)
end

return _M
