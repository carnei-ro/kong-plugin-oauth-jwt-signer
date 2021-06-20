require "spec.helpers"

local PLUGIN_NAME = "oauth-jwt-signer"

local function table_eq(table1, table2)
  local avoid_loops = {}
  local function recurse(t1, t2)
     -- compare value types
     if type(t1) ~= type(t2) then return false end
     -- Base case: compare simple values
     if type(t1) ~= "table" then return t1 == t2 end
     -- Now, on to tables.
     -- First, let's avoid looping forever.
     if avoid_loops[t1] then return avoid_loops[t1] == t2 end
     avoid_loops[t1] = t2
     -- Copy keys from t2
     local t2keys = {}
     local t2tablekeys = {}
     for k, _ in pairs(t2) do
        if type(k) == "table" then table.insert(t2tablekeys, k) end
        t2keys[k] = true
     end
     -- Let's iterate keys from t1
     for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if type(k1) == "table" then
           -- if key is a table, we need to find an equivalent one.
           local ok = false
           for i, tk in ipairs(t2tablekeys) do
              if table_eq(k1, tk) and recurse(v1, t2[tk]) then
                 table.remove(t2tablekeys, i)
                 t2keys[tk] = nil
                 ok = true
                 break
              end
           end
           if not ok then return false end
        else
           -- t1 has a key which t2 doesn't have, fail.
           if v2 == nil then return false end
           t2keys[k1] = nil
           if not recurse(v1, v2) then return false end
        end
     end
     -- if t2 has a key which t1 doesn't have, fail.
     if next(t2keys) then return false end
     return true
  end
  return recurse(table1, table2)
end

describe("[" .. PLUGIN_NAME .. "] oauth_providers_defaults", function()

  local oauth_providers_defaults = require("kong.plugins." .. PLUGIN_NAME .. ".oauth_providers_defaults")
  local config = {
    ["jwt_algorithm"] = "ES256",
    ["jwt_cookie"] = true,
    ["jwt_cookie_http_only"] = true,
    ["jwt_cookie_name"] = "oauth_jwt",
    ["jwt_cookie_secure"] = true,
    ["jwt_issuer"] = "kong",
    ["jwt_response"] = false,
    ["jwt_response_payload_key"] = "access_token",
    ["jwt_response_status_code"] = 200,
    ["jwt_validity"] = 86400,
    ["oauth_ssl_verify"] = true,
    ["oauth_token_endpoint_grant_type"] = "authorization_code",
    ["oauth_token_endpoint_method"] = "POST",
    ["oauth_token_endpoint_timeout"] = 3000,
    ["oauth_userinfo_endpoint_header_authorization"] = true,
    ["oauth_userinfo_endpoint_header_authorization_prefix"] = "Bearer",
    ["oauth_userinfo_endpoint_method"] = "GET",
    ["oauth_userinfo_endpoint_querystring_access_token"] = false,
    ["oauth_userinfo_endpoint_querystring_authorization"] = false,
    ["oauth_userinfo_endpoint_querystring_more"] = {},
    ["oauth_userinfo_endpoint_timeout"] = 3000,
    ["state_algorithm"] = "sha256",
    ["state_secret"] = "mystatesecret",
    ["jwt_key_id"] = "privkey1",
    ["jwt_key_value"] = "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2\nOF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r\n1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G\n-----END PRIVATE KEY-----",
    ["oauth_client_id"] = "myclientid",
    ["oauth_client_secret"] = "myclientsecret",
  }

  describe("oauth providers defaults", function()
    it("defaults not implemented yet", function()
      
      config["oauth_provider"] = "defaults_not_implemented_yet"
      config["oauth_token_endpoint"] = "http://oauth.foo/token"
      config["oauth_userinfo_endpoint"] = "http://oauth.foo/user"

      local plugin_conf = oauth_providers_defaults:set_defaults(config)
      
      assert.is_truthy(plugin_conf)

      assert.equal(plugin_conf["jwt_algorithm"], "ES256")
      assert.equal(plugin_conf["jwt_cookie"], true)
      assert.equal(plugin_conf["jwt_cookie_http_only"], true)
      assert.equal(plugin_conf["jwt_cookie_name"], "oauth_jwt")
      assert.equal(plugin_conf["jwt_cookie_secure"], true)
      assert.equal(plugin_conf["jwt_issuer"], "kong")
      assert.equal(plugin_conf["jwt_response"], false)
      assert.equal(plugin_conf["jwt_response_payload_key"], "access_token")
      assert.equal(plugin_conf["jwt_response_status_code"], 200)
      assert.equal(plugin_conf["jwt_validity"], 86400)
      assert.equal(plugin_conf["oauth_ssl_verify"], true)
      assert.equal(plugin_conf["oauth_token_endpoint_grant_type"], "authorization_code")
      assert.equal(plugin_conf["oauth_token_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization"], true)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization_prefix"], "Bearer")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_method"], "GET")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_access_token"], false)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_authorization"], false)
      assert(table_eq(plugin_conf["oauth_userinfo_endpoint_querystring_more"], {}))
      assert.equal(plugin_conf["oauth_userinfo_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["state_algorithm"], "sha256")
      assert.equal(plugin_conf["state_secret"], "mystatesecret")
      assert.equal(plugin_conf["jwt_key_id"], "privkey1")
      assert.equal(plugin_conf["oauth_token_endpoint_method"], "POST")
      assert.equal(plugin_conf["jwt_key_value"], "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2\nOF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r\n1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G\n-----END PRIVATE KEY-----")
      assert.equal(plugin_conf["oauth_client_id"], "myclientid")
      assert.equal(plugin_conf["oauth_client_secret"], "myclientsecret")
      assert.equal(plugin_conf["oauth_provider"], "defaults_not_implemented_yet")
      assert.equal(plugin_conf["oauth_token_endpoint"], "http://oauth.foo/token")
      assert.equal(plugin_conf["oauth_userinfo_endpoint"], "http://oauth.foo/user")
    end)

    it("custom", function()
      
      config["oauth_provider"] = "custom"
      config["oauth_provider_alias"] = "oauth.foo"
      config["oauth_token_endpoint"] = "http://oauth.foo/token"
      config["oauth_userinfo_endpoint"] = "http://oauth.foo/user"

      local plugin_conf = oauth_providers_defaults:set_defaults(config)
      
      assert.is_truthy(plugin_conf)

      assert.equal(plugin_conf["jwt_algorithm"], "ES256")
      assert.equal(plugin_conf["jwt_cookie"], true)
      assert.equal(plugin_conf["jwt_cookie_http_only"], true)
      assert.equal(plugin_conf["jwt_cookie_name"], "oauth_jwt")
      assert.equal(plugin_conf["jwt_cookie_secure"], true)
      assert.equal(plugin_conf["jwt_issuer"], "kong")
      assert.equal(plugin_conf["jwt_response"], false)
      assert.equal(plugin_conf["jwt_response_payload_key"], "access_token")
      assert.equal(plugin_conf["jwt_response_status_code"], 200)
      assert.equal(plugin_conf["jwt_validity"], 86400)
      assert.equal(plugin_conf["oauth_ssl_verify"], true)
      assert.equal(plugin_conf["oauth_token_endpoint_grant_type"], "authorization_code")
      assert.equal(plugin_conf["oauth_token_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization"], true)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization_prefix"], "Bearer")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_method"], "GET")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_access_token"], false)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_authorization"], false)
      assert(table_eq(plugin_conf["oauth_userinfo_endpoint_querystring_more"], {}))
      assert.equal(plugin_conf["oauth_userinfo_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["state_algorithm"], "sha256")
      assert.equal(plugin_conf["state_secret"], "mystatesecret")
      assert.equal(plugin_conf["jwt_key_id"], "privkey1")
      assert.equal(plugin_conf["oauth_token_endpoint_method"], "POST")
      assert.equal(plugin_conf["jwt_key_value"], "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2\nOF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r\n1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G\n-----END PRIVATE KEY-----")
      assert.equal(plugin_conf["oauth_client_id"], "myclientid")
      assert.equal(plugin_conf["oauth_client_secret"], "myclientsecret")
      assert.equal(plugin_conf["oauth_provider"], "custom")
      assert.equal(plugin_conf["oauth_provider_alias"], "oauth.foo")
      assert.equal(plugin_conf["oauth_token_endpoint"], "http://oauth.foo/token")
      assert.equal(plugin_conf["oauth_userinfo_endpoint"], "http://oauth.foo/user")
    end)

    it("facebook", function()
      
      config["oauth_provider"] = "facebook"
      
      local plugin_conf = oauth_providers_defaults:set_defaults(config)
      
      assert.is_truthy(plugin_conf)

      assert.equal(plugin_conf["jwt_algorithm"], "ES256")
      assert.equal(plugin_conf["jwt_cookie"], true)
      assert.equal(plugin_conf["jwt_cookie_http_only"], true)
      assert.equal(plugin_conf["jwt_cookie_name"], "oauth_jwt")
      assert.equal(plugin_conf["jwt_cookie_secure"], true)
      assert.equal(plugin_conf["jwt_issuer"], "kong")
      assert.equal(plugin_conf["jwt_response"], false)
      assert.equal(plugin_conf["jwt_response_payload_key"], "access_token")
      assert.equal(plugin_conf["jwt_response_status_code"], 200)
      assert.equal(plugin_conf["jwt_validity"], 86400)
      assert.equal(plugin_conf["oauth_ssl_verify"], true)
      assert.equal(plugin_conf["oauth_token_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["state_algorithm"], "sha256")
      assert.equal(plugin_conf["state_secret"], "mystatesecret")
      assert.equal(plugin_conf["jwt_key_id"], "privkey1")
      assert.equal(plugin_conf["jwt_key_value"], "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2\nOF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r\n1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G\n-----END PRIVATE KEY-----")
      assert.equal(plugin_conf["oauth_client_id"], "myclientid")
      assert.equal(plugin_conf["oauth_client_secret"], "myclientsecret")
      assert.equal(plugin_conf["oauth_provider"], "facebook")
      assert.equal(plugin_conf["oauth_token_endpoint"], "https://graph.facebook.com/v11.0/oauth/access_token")
      assert.equal(plugin_conf["oauth_token_endpoint_grant_type"], "authorization_code")
      assert.equal(plugin_conf["oauth_token_endpoint_method"], "POST")
      assert.equal(plugin_conf["oauth_userinfo_endpoint"], "https://graph.facebook.com/v11.0/me")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_method"], "GET")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization"], false)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization_prefix"], "Bearer")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_authorization"], true)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_access_token"], true)
      assert(table_eq(plugin_conf["oauth_userinfo_endpoint_querystring_more"], {["fields"] = 'id,first_name,last_name,middle_name,name,picture{url},short_name,email'}))
    end)

    it("github", function()
      
      config["oauth_provider"] = "github"
      
      local plugin_conf = oauth_providers_defaults:set_defaults(config)
      
      assert.is_truthy(plugin_conf)

      assert.equal(plugin_conf["jwt_algorithm"], "ES256")
      assert.equal(plugin_conf["jwt_cookie"], true)
      assert.equal(plugin_conf["jwt_cookie_http_only"], true)
      assert.equal(plugin_conf["jwt_cookie_name"], "oauth_jwt")
      assert.equal(plugin_conf["jwt_cookie_secure"], true)
      assert.equal(plugin_conf["jwt_issuer"], "kong")
      assert.equal(plugin_conf["jwt_response"], false)
      assert.equal(plugin_conf["jwt_response_payload_key"], "access_token")
      assert.equal(plugin_conf["jwt_response_status_code"], 200)
      assert.equal(plugin_conf["jwt_validity"], 86400)
      assert.equal(plugin_conf["oauth_ssl_verify"], true)
      assert.equal(plugin_conf["oauth_token_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["state_algorithm"], "sha256")
      assert.equal(plugin_conf["state_secret"], "mystatesecret")
      assert.equal(plugin_conf["jwt_key_id"], "privkey1")
      assert.equal(plugin_conf["jwt_key_value"], "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2\nOF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r\n1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G\n-----END PRIVATE KEY-----")
      assert.equal(plugin_conf["oauth_client_id"], "myclientid")
      assert.equal(plugin_conf["oauth_client_secret"], "myclientsecret")
      assert.equal(plugin_conf["oauth_provider"], "github")
      assert.equal(plugin_conf["oauth_token_endpoint"], "https://github.com/login/oauth/access_token")
      assert.equal(plugin_conf["oauth_token_endpoint_grant_type"], "authorization_code")
      assert.equal(plugin_conf["oauth_token_endpoint_method"], "POST")
      assert.equal(plugin_conf["oauth_userinfo_endpoint"], "https://api.github.com/user")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_method"], "GET")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization"], true)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization_prefix"], "Bearer")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_authorization"], false)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_access_token"], false)
      assert(table_eq(plugin_conf["oauth_userinfo_endpoint_querystring_more"], {}))
    end)

    it("gitlab", function()
      
      config["oauth_provider"] = "gitlab"
      
      local plugin_conf = oauth_providers_defaults:set_defaults(config)
      
      assert.is_truthy(plugin_conf)

      assert.equal(plugin_conf["jwt_algorithm"], "ES256")
      assert.equal(plugin_conf["jwt_cookie"], true)
      assert.equal(plugin_conf["jwt_cookie_http_only"], true)
      assert.equal(plugin_conf["jwt_cookie_name"], "oauth_jwt")
      assert.equal(plugin_conf["jwt_cookie_secure"], true)
      assert.equal(plugin_conf["jwt_issuer"], "kong")
      assert.equal(plugin_conf["jwt_response"], false)
      assert.equal(plugin_conf["jwt_response_payload_key"], "access_token")
      assert.equal(plugin_conf["jwt_response_status_code"], 200)
      assert.equal(plugin_conf["jwt_validity"], 86400)
      assert.equal(plugin_conf["oauth_ssl_verify"], true)
      assert.equal(plugin_conf["oauth_token_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["state_algorithm"], "sha256")
      assert.equal(plugin_conf["state_secret"], "mystatesecret")
      assert.equal(plugin_conf["jwt_key_id"], "privkey1")
      assert.equal(plugin_conf["jwt_key_value"], "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2\nOF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r\n1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G\n-----END PRIVATE KEY-----")
      assert.equal(plugin_conf["oauth_client_id"], "myclientid")
      assert.equal(plugin_conf["oauth_client_secret"], "myclientsecret")
      assert.equal(plugin_conf["oauth_provider"], "gitlab")
      assert.equal(plugin_conf["oauth_token_endpoint"], "https://gitlab.com/oauth/token")
      assert.equal(plugin_conf["oauth_token_endpoint_grant_type"], "authorization_code")
      assert.equal(plugin_conf["oauth_token_endpoint_method"], "POST")
      assert.equal(plugin_conf["oauth_userinfo_endpoint"], "https://gitlab.com/oauth/userinfo")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_method"], "GET")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization"], false)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization_prefix"], "Bearer")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_authorization"], true)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_access_token"], true)
      assert(table_eq(plugin_conf["oauth_userinfo_endpoint_querystring_more"], {}))
    end)

    it("google", function()
      
      config["oauth_provider"] = "google"
      
      local plugin_conf = oauth_providers_defaults:set_defaults(config)
      
      assert.is_truthy(plugin_conf)

      assert.equal(plugin_conf["jwt_algorithm"], "ES256")
      assert.equal(plugin_conf["jwt_cookie"], true)
      assert.equal(plugin_conf["jwt_cookie_http_only"], true)
      assert.equal(plugin_conf["jwt_cookie_name"], "oauth_jwt")
      assert.equal(plugin_conf["jwt_cookie_secure"], true)
      assert.equal(plugin_conf["jwt_issuer"], "kong")
      assert.equal(plugin_conf["jwt_response"], false)
      assert.equal(plugin_conf["jwt_response_payload_key"], "access_token")
      assert.equal(plugin_conf["jwt_response_status_code"], 200)
      assert.equal(plugin_conf["jwt_validity"], 86400)
      assert.equal(plugin_conf["oauth_ssl_verify"], true)
      assert.equal(plugin_conf["oauth_token_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["state_algorithm"], "sha256")
      assert.equal(plugin_conf["state_secret"], "mystatesecret")
      assert.equal(plugin_conf["jwt_key_id"], "privkey1")
      assert.equal(plugin_conf["jwt_key_value"], "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2\nOF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r\n1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G\n-----END PRIVATE KEY-----")
      assert.equal(plugin_conf["oauth_client_id"], "myclientid")
      assert.equal(plugin_conf["oauth_client_secret"], "myclientsecret")
      assert.equal(plugin_conf["oauth_provider"], "google")
      assert.equal(plugin_conf["oauth_token_endpoint"], "https://accounts.google.com/o/oauth2/token")
      assert.equal(plugin_conf["oauth_token_endpoint_grant_type"], "authorization_code")
      assert.equal(plugin_conf["oauth_token_endpoint_method"], "POST")
      assert.equal(plugin_conf["oauth_userinfo_endpoint"], "https://www.googleapis.com/oauth2/v2/userinfo")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_method"], "GET")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization"], true)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization_prefix"], "Bearer")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_authorization"], false)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_access_token"], false)
      assert(table_eq(plugin_conf["oauth_userinfo_endpoint_querystring_more"], {}))
    end)

    it("microsoft", function()
      
      config["oauth_provider"] = "microsoft"
      
      local plugin_conf = oauth_providers_defaults:set_defaults(config)
      
      assert.is_truthy(plugin_conf)

      assert.equal(plugin_conf["jwt_algorithm"], "ES256")
      assert.equal(plugin_conf["jwt_cookie"], true)
      assert.equal(plugin_conf["jwt_cookie_http_only"], true)
      assert.equal(plugin_conf["jwt_cookie_name"], "oauth_jwt")
      assert.equal(plugin_conf["jwt_cookie_secure"], true)
      assert.equal(plugin_conf["jwt_issuer"], "kong")
      assert.equal(plugin_conf["jwt_response"], false)
      assert.equal(plugin_conf["jwt_response_payload_key"], "access_token")
      assert.equal(plugin_conf["jwt_response_status_code"], 200)
      assert.equal(plugin_conf["jwt_validity"], 86400)
      assert.equal(plugin_conf["oauth_ssl_verify"], true)
      assert.equal(plugin_conf["oauth_token_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["state_algorithm"], "sha256")
      assert.equal(plugin_conf["state_secret"], "mystatesecret")
      assert.equal(plugin_conf["jwt_key_id"], "privkey1")
      assert.equal(plugin_conf["jwt_key_value"], "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2\nOF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r\n1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G\n-----END PRIVATE KEY-----")
      assert.equal(plugin_conf["oauth_client_id"], "myclientid")
      assert.equal(plugin_conf["oauth_client_secret"], "myclientsecret")
      assert.equal(plugin_conf["oauth_provider"], "microsoft")
      assert.equal(plugin_conf["oauth_token_endpoint"], "https://login.microsoftonline.com/common/oauth2/v2.0/token")
      assert.equal(plugin_conf["oauth_token_endpoint_grant_type"], "authorization_code")
      assert.equal(plugin_conf["oauth_token_endpoint_method"], "POST")
      assert.equal(plugin_conf["oauth_userinfo_endpoint"], "https://graph.microsoft.com/v1.0/me")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_method"], "GET")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization"], true)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization_prefix"], "Bearer")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_authorization"], false)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_access_token"], false)
      assert(table_eq(plugin_conf["oauth_userinfo_endpoint_querystring_more"], {}))
    end)

    it("yandex", function()
      
      config["oauth_provider"] = "yandex"
      
      local plugin_conf = oauth_providers_defaults:set_defaults(config)
      
      assert.is_truthy(plugin_conf)

      assert.equal(plugin_conf["jwt_algorithm"], "ES256")
      assert.equal(plugin_conf["jwt_cookie"], true)
      assert.equal(plugin_conf["jwt_cookie_http_only"], true)
      assert.equal(plugin_conf["jwt_cookie_name"], "oauth_jwt")
      assert.equal(plugin_conf["jwt_cookie_secure"], true)
      assert.equal(plugin_conf["jwt_issuer"], "kong")
      assert.equal(plugin_conf["jwt_response"], false)
      assert.equal(plugin_conf["jwt_response_payload_key"], "access_token")
      assert.equal(plugin_conf["jwt_response_status_code"], 200)
      assert.equal(plugin_conf["jwt_validity"], 86400)
      assert.equal(plugin_conf["oauth_ssl_verify"], true)
      assert.equal(plugin_conf["oauth_token_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["state_algorithm"], "sha256")
      assert.equal(plugin_conf["state_secret"], "mystatesecret")
      assert.equal(plugin_conf["jwt_key_id"], "privkey1")
      assert.equal(plugin_conf["jwt_key_value"], "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2\nOF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r\n1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G\n-----END PRIVATE KEY-----")
      assert.equal(plugin_conf["oauth_client_id"], "myclientid")
      assert.equal(plugin_conf["oauth_client_secret"], "myclientsecret")
      assert.equal(plugin_conf["oauth_provider"], "yandex")
      assert.equal(plugin_conf["oauth_token_endpoint"], "https://oauth.yandex.com/token")
      assert.equal(plugin_conf["oauth_token_endpoint_grant_type"], "authorization_code")
      assert.equal(plugin_conf["oauth_token_endpoint_method"], "POST")
      assert.equal(plugin_conf["oauth_userinfo_endpoint"], "https://login.yandex.ru/info")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_method"], "GET")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization"], true)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization_prefix"], "Bearer")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_authorization"], false)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_access_token"], false)
      assert(table_eq(plugin_conf["oauth_userinfo_endpoint_querystring_more"], {}))
    end)

    it("zoho", function()
      
      config["oauth_provider"] = "zoho"
      
      local plugin_conf = oauth_providers_defaults:set_defaults(config)
      
      assert.is_truthy(plugin_conf)

      assert.equal(plugin_conf["jwt_algorithm"], "ES256")
      assert.equal(plugin_conf["jwt_cookie"], true)
      assert.equal(plugin_conf["jwt_cookie_http_only"], true)
      assert.equal(plugin_conf["jwt_cookie_name"], "oauth_jwt")
      assert.equal(plugin_conf["jwt_cookie_secure"], true)
      assert.equal(plugin_conf["jwt_issuer"], "kong")
      assert.equal(plugin_conf["jwt_response"], false)
      assert.equal(plugin_conf["jwt_response_payload_key"], "access_token")
      assert.equal(plugin_conf["jwt_response_status_code"], 200)
      assert.equal(plugin_conf["jwt_validity"], 86400)
      assert.equal(plugin_conf["oauth_ssl_verify"], true)
      assert.equal(plugin_conf["oauth_token_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_timeout"], 3000)
      assert.equal(plugin_conf["state_algorithm"], "sha256")
      assert.equal(plugin_conf["state_secret"], "mystatesecret")
      assert.equal(plugin_conf["jwt_key_id"], "privkey1")
      assert.equal(plugin_conf["jwt_key_value"], "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2\nOF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r\n1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G\n-----END PRIVATE KEY-----")
      assert.equal(plugin_conf["oauth_client_id"], "myclientid")
      assert.equal(plugin_conf["oauth_client_secret"], "myclientsecret")
      assert.equal(plugin_conf["oauth_provider"], "zoho")
      assert.equal(plugin_conf["oauth_token_endpoint"], "https://accounts.zoho.com/oauth/v2/token")
      assert.equal(plugin_conf["oauth_token_endpoint_grant_type"], "authorization_code")
      assert.equal(plugin_conf["oauth_token_endpoint_method"], "POST")
      assert.equal(plugin_conf["oauth_userinfo_endpoint"], "https://accounts.zoho.com/oauth/user/info")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_method"], "GET")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization"], true)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_header_authorization_prefix"], "Zoho-oauthtoken")
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_authorization"], false)
      assert.equal(plugin_conf["oauth_userinfo_endpoint_querystring_access_token"], false)
      assert(table_eq(plugin_conf["oauth_userinfo_endpoint_querystring_more"], {}))
    end)


  end)

end)
