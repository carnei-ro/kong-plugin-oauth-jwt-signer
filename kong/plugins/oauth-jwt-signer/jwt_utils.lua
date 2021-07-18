local json = require("cjson").new()

local openssl_digest = require "resty.openssl.digest"
local openssl_hmac = require "resty.openssl.hmac"
local openssl_pkey = require "resty.openssl.pkey"

local b64_encode   = require("ngx.base64").encode_base64url

local plugin_name   = ({...})[1]:match("^kong%.plugins%.([^%.]+)")
local vault_auth    = require("kong.plugins." .. plugin_name .. ".vault.auth")
local vault_signer  = require("kong.plugins." .. plugin_name .. ".vault.sign_rs")

json.decode_array_with_array_mt(true)

local alg_sign = {
  HS256 = function(data, key) return openssl_hmac.new(key, "sha256"):final(data) end,
  HS384 = function(data, key) return openssl_hmac.new(key, "sha384"):final(data) end,
  HS512 = function(data, key) return openssl_hmac.new(key, "sha512"):final(data) end,
  RS256 = function(data, key)
    local digest = openssl_digest.new("sha256")
    assert(digest:update(data))
    return openssl_pkey.new(key):sign(digest)
  end,
  RS384 = function(data, key)
    local digest = openssl_digest.new("sha384")
    assert(digest:update(data))
    return openssl_pkey.new(key):sign(digest)
  end,
  RS512 = function(data, key)
    local digest = openssl_digest.new("sha512")
    assert(digest:update(data))
    return openssl_pkey.new(key):sign(digest)
  end
}

local _M = {}

function _M:sign_token(conf, claims)
  local headers = {
    ['typ'] = 'JWT',
    ['alg'] = conf['jwt_algorithm'],
    ['kid'] = conf['jwt_key_id'],
  }
  local h = b64_encode(json.encode(headers))
  local c = b64_encode(json.encode(claims))
  local data = h .. "." .. c

  local signature, err
  if not conf.vault_enabled then
    signature, err = alg_sign[conf['jwt_algorithm']](data, conf['jwt_key_value'])
    if err then
      return nil, err
    end
    return (data .. "." .. b64_encode(signature)), nil
  else
    local vault_token = vault_auth:login(conf)
    signature = vault_signer:sign(conf, vault_token, data)
    return (data .. "." .. signature), nil
  end
end

return _M
