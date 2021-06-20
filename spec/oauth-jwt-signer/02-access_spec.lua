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
  jwt_key_id              = "privkey1",
  jwt_key_value           = [[-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2QX1yau1ZbKRs2lUm7YqY
xloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQJAGCthklQnXS4LsitISiUD
YA71akkNZwymfRcPjRWp7clQGmHj9JDKxoCHqRsbA9Ho5ovFWRZD3423Wv7o1PJ0
AQIhAP/hqi481mAFjnikFTEr2FWbVdFHQtbsvpEsPRB2jKqhAiEA76Nfs1L+xtOv
SgkNH+/5f3c0yccLJeT3dNpP3aCu6KECIHU9pIgDAAaHBTxpkfwxprGytqNpD0sC
tl418tS0PMeBAiEAhgP84kGZAEKkNihHscO36WQWHn31KxUYmr34ij5xcuECICsg
860obxqltjMuLFJCE47BhAv99+f/4z5lflA/A+Xo
-----END RSA PRIVATE KEY-----]],
  oauth_client_id         = "myclientid",
  oauth_client_secret     = "myclientsecret",
  oauth_ssl_verify        = false,
}

for _, strategy in helpers.each_strategy() do
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

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

      local route2 = bp.routes:insert({
        hosts = { "cookie.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route2.id },
        config = kong.table.merge(default_configs, {
          jwt_cookie_name = 'access_token',
          jwt_cookie_secure = false,
          jwt_cookie_http_only = false,
          jwt_cookie_domain = '.carnei.ro',
          jwt_validity = 10,
        }),
      }

      local route3 = bp.routes:insert({
        hosts = { "response1.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route3.id },
        config = kong.table.merge(default_configs, {
          jwt_response = true,
        }),
      }

      local route4 = bp.routes:insert({
        hosts = { "response2.foo" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route4.id },
        config = kong.table.merge(default_configs, {
          jwt_response = true,
          jwt_response_payload_key = 'jwt',
          jwt_response_status_code = 418,
          jwt_cookie = false,
        }),
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


    describe("response", function()
      it("bad request when missing code and state", function()
        local r = client:get("/auth/callback", {
          headers = {
            host = "custom.foo"
          }
        })
        assert.response(r).has.status(400)
        local body = assert.response(r).has.jsonbody()
        assert.equal("Missing query param 'state' and/or 'code'", body['err'])
      end)

      it("bad request when missing state", function()
        local r = client:get("/auth/callback?code=9af3070e-df93-4748-b871-9c5b180474b7", {
          headers = {
            host = "custom.foo"
          }
        })
        assert.response(r).has.status(400)
        local body = assert.response(r).has.jsonbody()
        assert.equal("Missing query param 'state' and/or 'code'", body['err'])
      end)

      it("bad request when missing code", function()
        local r = client:get("/auth/callback?state=eyJ2IjoidjAiLCJkIjoidjA7aHR0cHM6Ly9odHRwYmluLm9yZy9hbnl0aGluZz9mb289YmFyJmE9YiIsInMiOiJxVVZaR0xBNHFQdW9hRFM2UFRERFBVbXBtUHV3cks1alZ4MVZJZXhrUzFJIn0", {
          headers = {
            host = "custom.foo"
          }
        })
        assert.response(r).has.status(400)
        local body = assert.response(r).has.jsonbody()
        assert.equal("Missing query param 'state' and/or 'code'", body['err'])
      end)

      it("token issued - redir=https://httpbin.org/anything?foo=bar&a=b", function()
        local r = client:get("/auth/callback?code=9af3070e-df93-4748-b871-9c5b180474b7&state=eyJ2IjoidjAiLCJkIjoidjA7aHR0cHM6Ly9odHRwYmluLm9yZy9hbnl0aGluZz9mb289YmFyJmE9YiIsInMiOiJxVVZaR0xBNHFQdW9hRFM2UFRERFBVbXBtUHV3cks1alZ4MVZJZXhrUzFJIn0", {
          headers = {
            host = "custom.foo"
          }
        })
        local header_location   = assert.response(r).has.header("Location")
        local header_set_cookie = assert.response(r).has.header("Set-Cookie")
        local jwt = header_set_cookie:match("%w+%=(.*);version.*")
        local _, jwt_claims_str, _ = jwt:match("([^.]*)%.([^.]*)%.([^.]*)")
        local jwt_claims = json.decode(b64_decode(jwt_claims_str))

        assert.response(r).has.status(302)
        assert.equal("https://httpbin.org/anything?foo=bar&a=b", header_location)
        assert.matches("^oauth_jwt=eyJraWQiOiJwcml2a2V5MSIsImFsZyI6IlJTMjU2IiwidHlwIjoiSldUIn0%.[a-zA-Z0-9_-]+%.[a-zA-Z0-9_-]+;version=1;path=/;Max%-Age=86395;secure;httponly$", header_set_cookie)
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

      it("token issued - tweaking cookie", function()
        local r = client:get("/auth/callback?code=9af3070e-df93-4748-b871-9c5b180474b7&state=eyJ2IjoidjAiLCJkIjoidjA7aHR0cHM6Ly9odHRwYmluLm9yZy9hbnl0aGluZz9mb289YmFyJmE9YiIsInMiOiJxVVZaR0xBNHFQdW9hRFM2UFRERFBVbXBtUHV3cks1alZ4MVZJZXhrUzFJIn0", {
          headers = {
            host = "cookie.foo"
          }
        })
        local header_location   = assert.response(r).has.header("Location")
        local header_set_cookie = assert.response(r).has.header("Set-Cookie")
        assert.response(r).has.status(302)
        assert.equal("https://httpbin.org/anything?foo=bar&a=b", header_location)
        assert.matches("^access_token=eyJraWQiOiJwcml2a2V5MSIsImFsZyI6IlJTMjU2IiwidHlwIjoiSldUIn0%.[a-zA-Z0-9_-]+%.[a-zA-Z0-9_-]+;version=1;path=/;Max%-Age=5;domain=.carnei.ro$", header_set_cookie)
      end)

      it("token issued - response1", function()
        local r = client:get("/auth/callback?code=9af3070e-df93-4748-b871-9c5b180474b7&state=eyJ2IjoidjAiLCJkIjoidjA7aHR0cHM6Ly9odHRwYmluLm9yZy9hbnl0aGluZz9mb289YmFyJmE9YiIsInMiOiJxVVZaR0xBNHFQdW9hRFM2UFRERFBVbXBtUHV3cks1alZ4MVZJZXhrUzFJIn0", {
          headers = {
            host = "response1.foo"
          }
        })
        assert.response(r).has.header("Set-Cookie")
        assert.is_nil(r.headers["Location"])
        local body = assert.response(r).has.jsonbody()
        assert.response(r).has.status(200)
        assert.matches("eyJraWQiOiJwcml2a2V5MSIsImFsZyI6IlJTMjU2IiwidHlwIjoiSldUIn0%.[a-zA-Z0-9_-]+%.[a-zA-Z0-9_-]+", body['access_token'])
      end)

      it("token issued - response2", function()
        local r = client:get("/auth/callback?code=9af3070e-df93-4748-b871-9c5b180474b7&state=eyJ2IjoidjAiLCJkIjoidjA7aHR0cHM6Ly9odHRwYmluLm9yZy9hbnl0aGluZz9mb289YmFyJmE9YiIsInMiOiJxVVZaR0xBNHFQdW9hRFM2UFRERFBVbXBtUHV3cks1alZ4MVZJZXhrUzFJIn0", {
          headers = {
            host = "response2.foo"
          }
        })
        assert.is_nil(r.headers["Set-Cookie"])
        assert.is_nil(r.headers["Location"])
        local body = assert.response(r).has.jsonbody()
        assert.response(r).has.status(418)
        assert.matches("eyJraWQiOiJwcml2a2V5MSIsImFsZyI6IlJTMjU2IiwidHlwIjoiSldUIn0%.[a-zA-Z0-9_-]+%.[a-zA-Z0-9_-]+", body['jwt'])
      end)

    end)

  end)
end
