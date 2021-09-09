local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")
local http        = require("kong.plugins." .. plugin_name .. ".vault.connect-better")
local cjson       = require("cjson.safe").new()
local split       = require("kong.tools.utils").split
local b64_encode  = ngx.encode_base64
cjson.decode_array_with_array_mt(true)

local _M = {}

local function prepare_vault_sign_body_tbl(conf, string_to_sign)
  return {
    ["input"]                = b64_encode(string_to_sign),
    ["marshaling_algorithm"] = "jws",
    ["hash_algorithm"]       = "sha2-" .. conf.jwt_algorithm:sub(3, 5),
    ["signature_algorithm"]  = "pkcs1v15",
  }
end

function _M:sign(conf, vault_token, string_to_sign)
  local client = http.new()
  client:set_timeout(conf.vault_sign_timeout)

  local ok, err = client:connect_better {
    scheme = conf.vault_protocol,
    host = conf.vault_host,
    port = conf.vault_port,
    ssl = { verify = conf.vault_ssl_verify },
  }
  if (not ok) or (err) then
    return kong.response.exit(500, {['err'] = err})
  end

  local vault_sign_body = prepare_vault_sign_body_tbl(conf, string_to_sign)

  local res, err = client:request {
    method = 'PUT',
    path = '/v1/' .. conf.vault_transit_backend .. '/sign/' .. conf.vault_rsa_keyname,
    body = cjson.encode(vault_sign_body),
    headers = {
      ["X-Vault-Token"] = vault_token,
      ["Accept"]        = "application/json",
      ["Content-Type"]  = "application/json",
    },
  }

  if (err) or (not res) or (not(res.status == 200)) then
    return kong.response.exit(500, {['err'] = 'Failed to sign JWT with Vault'})
  end

  local content = res:read_body()
  client:close()
  local body, err = cjson.decode(content)
  if err then
    return kong.response.exit(500, {['err'] = err})
  end

  return split(body.data.signature, ":")[3]
end

return _M
