require "spec.helpers"

local PLUGIN_NAME = "oauth-jwt-signer"

describe("[" .. PLUGIN_NAME .. "] claims_utils", function()

  local claims_utils = require("kong.plugins." .. PLUGIN_NAME .. ".claims_utils")
  before_each(function()
    _G.ngx = {
      time = ngx.time,
    }
  end)

  describe("claims_utils", function()
    it("custom", function()
      local conf = {
        ['oauth_provider'] = "custom",
        ['oauth_provider_alias'] = "keycloak",
        ['jwt_validity'] = 86400,
        ['jwt_issuer'] = 'kong'
      }
      local profile = {
        ['email'] = "foo@bar.com"
      }

      local claims = claims_utils:generate_claims_table(conf, profile)

      assert.is_truthy(claims)
      assert.equal(claims['sub'], profile['email'])
      assert.equal(claims['provider'], conf['oauth_provider_alias'])
      assert.equal(claims['iss'], conf['jwt_issuer'])
      assert.equal(claims['iat'], ngx.time())
      assert.equal(claims['exp'], (ngx.time() + conf['jwt_validity']) )
    end)

    it("google", function()
      local conf = {
        ['oauth_provider'] = "google",
        ['oauth_provider_alias'] = nil,
        ['jwt_validity'] = 86400,
        ['jwt_issuer'] = 'kong'
      }
      local profile = {
        ['email'] = "foo@bar.com"
      }

      local claims = claims_utils:generate_claims_table(conf, profile)

      assert.is_truthy(claims)
      assert.equal(claims['sub'], profile['email'])
      assert.equal(claims['provider'], conf['oauth_provider'])
      assert.equal(claims['iss'], conf['jwt_issuer'])
      assert.equal(claims['iat'], ngx.time())
      assert.equal(claims['exp'], (ngx.time() + conf['jwt_validity']) )
    end)
  end)

end)
