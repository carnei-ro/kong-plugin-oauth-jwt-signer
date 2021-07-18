local helpers = require "spec.helpers"
local json = require("cjson").new()
local b64_decode = require("ngx.base64").decode_base64url

local PLUGIN_NAME = "oauth-jwt-signer"

local default_configs = {
  oauth_provider          = "custom",
  oauth_provider_alias    = "gluu",
  oauth_token_endpoint    = "http://localhost:9000/oxauth/restv1/token",
  oauth_userinfo_endpoint = "http://localhost:9000/oxauth/restv1/userinfo",
  state_secret            = "mystatesecret",
  jwt_issuer              = "carneiro",
  jwt_key_id              = "vault-kong-key01",
  oauth_client_id         = "myclientid",
  oauth_client_secret     = "myclientsecret",
  oauth_ssl_verify        = false,
  vault_enabled           = true,
  vault_protocol          = "http",
  vault_host              = "localhost",
  vault_port              = 9000,
  vault_role              = "jwt_signer",
  vault_ssl_verify        = false,
  vault_transit_backend   = "transit/keys/kong",
  vault_rsa_keyname       = "kong-key01",
}

for _, strategy in helpers.each_strategy() do
  describe(PLUGIN_NAME .. ": (vault) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

      local mock_vault_login_endpoint = bp.routes:insert({
        paths = {"/v1/auth/aws/login"},
        methods = {"PUT"}
      })
      bp.plugins:insert {
        name = "request-termination",
        route = { id = mock_vault_login_endpoint.id },
        config = {
          status_code  = 200,
          content_type = "application/json",
          body         = [[
            {
              "lease_id": "",
              "warnings": "userdata: NULL",
              "renewable": false,
              "request_id": "00000000-0000-0000-0000-000000000000",
              "auth": {
                "renewable": true,
                "token_policies": [
                  "default"
                ],
                "lease_duration": 30,
                "token_type": "service",
                "metadata": {
                  "inferred_entity_type": "",
                  "inferred_aws_region": "",
                  "role_id": "00000000-0000-0000-0000-000000000000",
                  "auth_type": "iam",
                  "account_id": "000000000000",
                  "client_user_id": "AROA00000000000000000",
                  "canonical_arn": "arn:aws:iam::000000000000:role/kong",
                  "client_arn": "arn:aws:sts::000000000000:assumed-role/kong/i-00000000000000000",
                  "inferred_entity_id": ""
                },
                "accessor": "000000000000000000000000",
                "entity_id": "00000000-0000-0000-0000-000000000000",
                "policies": [
                  "default"
                ],
                "client_token": "s.000000000000000000000000",
                "orphan": true
              },
              "wrap_info": "userdata: NULL",
              "data": "userdata: NULL",
              "lease_duration": 0
            }
          ]]
        },
      }

      local mock_vault_sign_endpoint = bp.routes:insert({
        paths = {"/v1/transit/keys/kong/sign/kong-key01"},
        methods = {"PUT"}
      })
      bp.plugins:insert {
        name = "pre-function",
        route = { id = mock_vault_sign_endpoint.id },
        config = {
          access  = { [[
            local token_header = kong.request.get_header("x-vault-token")
            if not token_header then
              return kong.response.exit(400, {["errors"]={"missing client token"}}, {["content-type"]="application/json"})
            end
            if token_header == "s.000000000000000000000000" then
              return
            end
            return kong.response.exit(403, {["errors"]={"invalid vault token"}}, {["content-type"]="application/json"})
          ]]},
        },
      }
      bp.plugins:insert {
        name = "request-termination",
        route = { id = mock_vault_sign_endpoint.id },
        config = {
          status_code  = 200,
          content_type = "application/json",
          body         = [[
            {
              "request_id": "00000000-0000-0000-0000-000000000000",
              "lease_id": "",
              "renewable": false,
              "lease_duration": 0,
              "data": {
                "signature": "vault:v1:TFF-Iwx77cQgtT0g533R37vtuyr-L1j0agaGWiJX5-9iWPzM9CESH9jjYiBcapjxaQ2FuF8AquYmCV3NTtNZ49IkS_scBTjEbXSDnKeNSWNuNp2oqaQVM0yxJ43rNTchbOuBTUhpS1AyJMVgzopFbWlGeQSnAYJZDyPjIXdbx7UgCL8VYGx3lgpP6r1Ape2KdMw-pxmL6W_ymSN2HgxMflRxFkLNy-O0DmzPh4Rr2AFbDfx6fHYh-7doRs4kn92iKBnJ-MOiqo4xQ0NGsWihEzwl5sQXgqpNZPJyIKqlBTrjELc5H4J94hBNl2QMfl8_iyG9ZA8ECGkJZSXKJ-VtZA"
              },
              "wrap_info": null,
              "warnings": null,
              "auth": null
            }
          ]]
        },
      }

      local warmup_iam_credentials_cache = bp.routes:insert({
        paths = {"/warmup-iam-credentials-cache"},
        methods = {"GET"}
      })
      bp.plugins:insert {
        name = "pre-function",
        route = { id = warmup_iam_credentials_cache.id },
        config = {
          access  = { [[
            local function mock_cache_iam()
              return {
                ["access_key"]    = "foo",
                ["secret_key"]    = "bar",
                ["session_token"] = "baz",
              }
            end
            local PLUGIN_NAME = "oauth-jwt-signer"
            local IAM_CREDENTIALS_CACHE_KEY = "plugin." .. PLUGIN_NAME .. ".iam_role_temp_creds"
            local creds = kong.cache:get(IAM_CREDENTIALS_CACHE_KEY, nil, mock_cache_iam)
            return kong.response.exit(200, creds, {["content-type"]="application/json"})
          ]]},
        },
      }

      local mock_token_endpoint = bp.routes:insert({
        paths = {"/oxauth/restv1/token"}
      })
      bp.plugins:insert {
        name = "request-termination",
        route = { id = mock_token_endpoint.id },
        config = {
          status_code  = 200,
          content_type = "application/json",
          body         = '{"access_token":"bac34121-bda2-42db-9029-cadbea67dd51","id_token":"eyJraWQiOiI3NWNkYmE1Ni1kMGFmLTQ3NDEtYjc5Yy02NWFlZWExOTY0MGMiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdF9oYXNoIjoiWnhwYUNFcUo1OGt4R2lNWGpINTVIdyIsImF1ZCI6IjYzMWZhYmRlLTY0MjQtNDhiYy05NmRlLTk3ZjFlNjcwNjE0YiIsInN1YiI6IjVURGFUd3psTXhjcUlLZUxRR1dKWGlnd0xkX1NnYUhvUjd3djBHYWpQZmMiLCJhdXRoX3RpbWUiOjE2MjE4NTU1NDUsImlzcyI6Imh0dHA6Ly9rb25nLmxvY2FsIiwiZXhwIjoxNjIyNDYzNDUwLCJpYXQiOjE2MjI0MjAyNTAsIm94T3BlbklEQ29ubmVjdFZlcnNpb24iOiJvcGVuaWRjb25uZWN0LTEuMCJ9.Q2iSbJYLutmB5yj0MnAG1dvpX4EqHZMKR9KUd-ZqE8oXpZlh2mEz6n1_nOAmvNubratsXU-mPDeNN4PmjPckdAqAfZsPRHjq1HVcnmeM-YaIxbtfJ8H_NzxH_S8NnuR2_6932t-wN1Gfs7USfCvUZRsIUytHmfN3k9Ba-fcsM_IgzsdBYIsUD1y84cHK8icIfpoUqoyZfHb1Xf6AM28ZzSG8WdElmVcjwazFq8P45lSPYcVOYaM6L0-7lL9obY1tKpJqqsxjhwhj-MWNQJni4RFGRObV3AsIcVvmW_wjinaWntKqbc6uQA9FjDc7lVHZTjL6qmX8xTy1o7zjydfQhA","token_type":"bearer","expires_in":299}'
        },
      }

      local mock_userinfo_endpoint = bp.routes:insert({
        paths = {"/oxauth/restv1/userinfo"}
      })
      bp.plugins:insert {
        name = "request-termination",
        route = { id = mock_userinfo_endpoint.id },
        config = {
          status_code  = 200,
          content_type = "application/json",
          body         = '{"sub":"5TDaTwzlMxcqIKeLQGWJXigwLd_SgaHoR7wv0GajPfc","email_verified":true,"roles":["Admin"],"name":"Leandro Carneiro","given_name":"Leandro","family_name":"Carneiro","email":"leandro@carnei.ro"}'
        },
      }

      local route1 = bp.routes:insert({
        hosts = { "custom.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = default_configs,
      }

      -- start kong
      assert(helpers.start_kong({
        database   = strategy,
        nginx_conf = "spec/fixtures/custom_nginx.template",
        plugins = "bundled," .. PLUGIN_NAME,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)

    describe("[" .. PLUGIN_NAME .. "] sign tokens with vault =>", function()

      it("token issued - redir=https://httpbin.org/anything?foo=bar&a=b", function()
        -- Warming up IAM Cache Credentials
        local r = client:get("/warmup-iam-credentials-cache", {
          headers = {
            ["x-kong-plugin-name"] = PLUGIN_NAME
          }
        })
        print(r.body_reader())

        r = client:get("/auth/callback?code=9af3070e-df93-4748-b871-9c5b180474b7&state=eyJ2IjoidjAiLCJkIjoidjA7aHR0cHM6Ly9odHRwYmluLm9yZy9hbnl0aGluZz9mb289YmFyJmE9YiIsInMiOiJxVVZaR0xBNHFQdW9hRFM2UFRERFBVbXBtUHV3cks1alZ4MVZJZXhrUzFJIn0", {
          headers = {
            host = "custom.foo"
          }
        })
        local header_location   = assert.response(r).has.header("Location")
        local header_set_cookie = assert.response(r).has.header("Set-Cookie")
        local jwt = header_set_cookie:match("%w+%=(.*);version.*")
        local _, jwt_claims_str, _ = jwt:match("([^.]*)%.([^.]*)%.([^.]*)")
        local jwt_claims = json.decode(b64_decode(jwt_claims_str))

        -- print(require('pl.pretty').write(jwt))

        assert.response(r).has.status(302)
        assert.equal("https://httpbin.org/anything?foo=bar&a=b", header_location)
        assert.matches("^oauth_jwt=eyJraWQiOiJ2YXVsdC1rb25nLWtleTAxIiwiYWxnIjoiUlMyNTYiLCJ0eXAiOiJKV1QifQ%.[a-zA-Z0-9_-]+%.[a-zA-Z0-9_-]+;version=1;path=/;Max%-Age=86395;secure;httponly$", header_set_cookie)
        assert.equal('carneiro',          jwt_claims['iss'])
        assert.equal('Leandro Carneiro',  jwt_claims['name'])
        assert.equal('carnei.ro',         jwt_claims['domain'])
        assert.equal('Admin',             jwt_claims['roles'][1])
        assert.equal('gluu',              jwt_claims['provider'])
        assert.equal('leandro',           jwt_claims['user'])
        assert.equal('Leandro',           jwt_claims['given_name'])
        assert.equal('leandro@carnei.ro', jwt_claims['sub'])
        assert.equal(true,                jwt_claims['email_verified'])
        assert.equal('Carneiro',          jwt_claims['family_name'])
      end)

    end)

  end)
end
