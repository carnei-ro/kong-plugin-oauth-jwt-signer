local plugin_name  = ({...})[1]:match("^kong%.plugins%.([^%.]+)")
local typedefs     = require("kong.db.schema.typedefs")
local openssl_pkey = require("resty.openssl.pkey")

local function validate_ssl_key(key)
  local _, err =  openssl_pkey.new(key)
  if err then
    return nil, "invalid RSA key"
  end

  return true
end


return {
  name = plugin_name,
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { state_algorithm = {
              type = "string",
              default = "sha256",
              required = true,
              one_of = { "sha256", "sha1", "md5" },
          }, },
          { state_secret = {
              type = "string",
              required = true,
          }, },
          { jwt_algorithm = {
              type = "string",
              default = "RS256",
              required = true,
              one_of = { "HS256", "HS384", "HS512", "RS256", "RS384", "RS512" },
          }, },
          { jwt_key_id = {
              type = "string",
              required = true,
          }, },
          { jwt_key_value = {
              type = "string",
              required = true,
          }, },
          { jwt_issuer = {
              type = "string",
              required = true,
              default = "kong",
          }, },
          { jwt_validity = {
              type = "number",
              default = 86400,
              required = true,
          }, },
          { jwt_cookie = {
              type = "boolean",
              default = true,
              required = true,
          }, },
          { jwt_cookie_name = {
              type = "string",
              default = "oauth_jwt",
              required = true,
          }, },
          { jwt_cookie_secure = {
              type = "boolean",
              default = true,
              required = true,
          }, },
          { jwt_cookie_http_only = {
              type = "boolean",
              default = true,
              required = true,
          }, },
          { jwt_cookie_domain = {
              type = "string",
              required = false,
          }, },
          { jwt_response = {
              type = "boolean",
              default = false,
              required = true,
          }, },
          { jwt_response_status_code = {
              type = "number",
              default = 200,
              required = true,
          }, },
          { jwt_response_payload_key = {
              type = "string",
              default = "access_token",
              required = true
          }, },
          { oauth_provider = {
              type = "string",
              default = "google",
              required = true,
              one_of = { "custom", "facebook", "github", "gitlab", "google", "microsoft", "yandex", "zoho" },
          }, },
          { oauth_provider_alias = {
              type = "string",
              required = false,
          }, },
          { oauth_ssl_verify = {
              type = "boolean",
              default = true,
              required = true,
          }, },
          { oauth_token_endpoint = {
              type = "string",
              required = false,
          }, },
          { oauth_token_endpoint_method = {
              type = "string",
              default = "POST",
              required = true,
              match = "^%u+$",
          }, },
          { oauth_token_endpoint_timeout = {
              type = "number",
              default = 3000,
              required = true,
          }, },
          { oauth_token_endpoint_grant_type = {
              type = "string",
              default = "authorization_code",
              required = true,
          }, },
          { oauth_userinfo_endpoint = {
              type = "string",
              required = false,
          }, },
          { oauth_userinfo_endpoint_method = {
              type = "string",
              default = "GET",
              required = true,
              match = "^%u+$",
          }, },
          { oauth_userinfo_endpoint_timeout = {
              type = "number",
              default = 3000,
              required = true,
          }, },
          { oauth_userinfo_endpoint_header_authorization = {
              type = "boolean",
              default = true,
              required = true,
          }, },
          { oauth_userinfo_endpoint_header_authorization_prefix = {
              type = "string",
              default = "Bearer",
              required = true,
          }, },
          { oauth_userinfo_endpoint_querystring_authorization = {
              type = "boolean",
              default = false,
              required = true,
          }, },
          { oauth_userinfo_endpoint_querystring_access_token = {
              type = "boolean",
              default = false,
              required = true,
          }, },
          { oauth_userinfo_endpoint_querystring_more = {
              type = "map",
              keys = {
                type = "string"
              },
              required = true,
              values = {
                type = "string",
                required = true,
              },
              default = {},
          }, },
          { oauth_userinfo_to_claims = {
              type = "set",
              required = true,
              default = {},
              elements = {
                type = "record",
                required = true,
                fields = {
                  { claim = {
                    type = "string",
                    required = true,
                    not_one_of = { "sub" },
                    err = "'sub' claim cannot be overridden"
                  }, },
                  { userinfo = {
                    type = "string",
                    required = true,
                  }, },
                },
              },
          }, },
          { oauth_client_id = {
              type = "string",
              required = true,
          }, },
          { oauth_client_secret = {
              type = "string",
              required = true,
          }, },
        },
      },
    },
  },
  entity_checks = {
    { conditional = {
        if_field = "config.oauth_provider",
        if_match = { eq = "custom" },
        then_field = "config.oauth_token_endpoint",
        then_match = { required = true },
    }, },
    { conditional = {
        if_field = "config.oauth_provider",
        if_match = { eq = "custom" },
        then_field = "config.oauth_userinfo_endpoint",
        then_match = { required = true },
    }, },
    { conditional = {
        if_field = "config.oauth_provider",
        if_match = { eq = "custom" },
        then_field = "config.oauth_provider_alias",
        then_match = { required = true },
    }, },
    { conditional = {
        if_field = "config.jwt_algorithm",
        if_match = { one_of = { "RS256", "RS384", "RS512" } },
        then_field = "config.jwt_key_value",
        then_match = { custom_validator = validate_ssl_key },
    }, },
  }
}
