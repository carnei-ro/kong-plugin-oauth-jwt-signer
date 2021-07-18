local plugin_name   = ({...})[1]:match("^kong%.plugins%.([^%.]+)")
local aws_v4        = require("kong.plugins." .. plugin_name .. ".vault.v4")
local http          = require("kong.plugins." .. plugin_name .. ".vault.connect-better")
local cjson         = require("cjson.safe").new()
local b64_encode    = ngx.encode_base64

cjson.decode_array_with_array_mt(true)

local _M = {}

local IAM_CREDENTIALS_CACHE_KEY = "plugin." .. plugin_name .. ".iam_role_temp_creds"
local VAULT_TOKEN_CACHE_KEY     = "plugin." .. plugin_name .. ".vault_token"

local fetch_credentials
do
  local credential_sources = {
    require("kong.plugins." .. plugin_name .. ".vault.iam-ecs-credentials"),
    -- The EC2 one will always return `configured == true`, so must be the last!
    require("kong.plugins." .. plugin_name .. ".vault.iam-ec2-credentials"),
  }

  for _, credential_source in ipairs(credential_sources) do
    if credential_source.configured then
      fetch_credentials = credential_source.fetchCredentials
      break
    end
  end
end

local function patch_table_with_aws_credentials(conf, opts)
  -- Get AWS Access and Secret Key from conf or AWS Access, Secret Key and Token from cache or iam role
  if not conf.aws_key then
    -- no credentials provided, so try the IAM metadata service
    local iam_role_credentials = kong.cache:get(
      IAM_CREDENTIALS_CACHE_KEY,
      nil,
      fetch_credentials
    )

    if not iam_role_credentials then
      return kong.response.exit(500, {
        message = "Could not set access_key, secret_key and/or session_token"
      })
    end

    opts.access_key = iam_role_credentials.access_key
    opts.secret_key = iam_role_credentials.secret_key
    opts.headers["X-Amz-Security-Token"] = iam_role_credentials.session_token

  else
    opts.access_key = conf.aws_key
    opts.secret_key = conf.aws_secret
  end
end

local function prepare_get_caller_identity_tbl(region)
  return {
    region = region,
    service = 'sts',
    method = 'POST',
    headers = {
      ["Content-Length"] = "43",
      ["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8",
      ["Host"] = "sts.amazonaws.com",
    },
    path = '/',
    host = 'sts.amazonaws.com',
    port = 443,
    query = nil,
    body = 'Action=GetCallerIdentity&Version=2011-06-15',
  }
end

local function prepare_vault_aws_login_body_tbl(conf, signed_values)
  return {
    ["role"]                    = conf.vault_role,
    ["iam_http_request_method"] = signed_values.method,
    ["iam_request_url"]         = b64_encode('https://' .. signed_values.headers['Host'] .. '/'),
    ["iam_request_body"]        = b64_encode(signed_values.body),
    ["iam_request_headers"]     = b64_encode(cjson.encode({
                                  ["Authorization"] = { signed_values.headers['Authorization'] },
                                  ["Content-Length"] = { signed_values.headers['Content-Length'] },
                                  ["Content-Type"] = { signed_values.headers['Content-Type'] },
                                  ["X-Amz-Date"] = { signed_values.headers['X-Amz-Date'] },
                                  ["X-Amz-Security-Token"] = { signed_values.headers['X-Amz-Security-Token'] },
                                  ["Host"] = { signed_values.headers['Host'] },
                                })),
  }
end

local function vault_aws_login(conf)
  local opts = prepare_get_caller_identity_tbl(conf.vault_aws_region)
  patch_table_with_aws_credentials(conf, opts)

  local signed_values, err = aws_v4(opts)
  if err then
    return kong.response.exit(500, {['err'] = err})
  end

  local client = http.new()
  client:set_timeout(conf.vault_login_timeout)

  local ok, err = client:connect_better {
    scheme = conf.vault_protocol,
    host = conf.vault_host,
    port = conf.vault_port,
    ssl = { verify = conf.vault_ssl_verify },
  }
  if (not ok) or (err) then
    return kong.response.exit(500, {['err'] = err})
  end

  local vault_aws_login_body = prepare_vault_aws_login_body_tbl(conf, signed_values)

  local res, err = client:request {
    method = 'PUT',
    path = '/v1/auth/' .. conf.vault_auth_backend .. '/login',
    body = cjson.encode(vault_aws_login_body),
    headers = {
      ["X-Vault-Request"] = "true",
      ["Accept"]          = "application/json",
      ["Content-Type"]    = "application/json",
    },
  }
  if (err) or (not res) or (not(res.status == 200)) then
    return kong.response.exit(500, {['err'] = 'Failed to Login at Vault'})
  end

  local content = res:read_body()
  client:close()
  local body, err = cjson.decode(content)
  if err then
    return kong.response.exit(500, {['err'] = err})
  end

  return body.auth.client_token, nil, ( body.auth.lease_duration - 1 )
end

function _M:login(conf)
  local vault_token, err

  if conf.vault_auth_method == "aws" then
    vault_token, err = kong.cache:get(
      VAULT_TOKEN_CACHE_KEY,
      nil,
      vault_aws_login,
      conf
    )
    if err then
      return kong.response.exit(500, {['err'] = err})
    end
  end

  return vault_token
end

return _M
