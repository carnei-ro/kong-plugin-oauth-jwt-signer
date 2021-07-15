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
        ['jwt_issuer'] = 'kong',
        ['oauth_userinfo_to_claims'] = {},
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

    it("custom - oauth_userinfo_to_claims", function()
      local conf = {
        ['oauth_provider'] = "custom",
        ['oauth_provider_alias'] = "gluu",
        ['jwt_validity'] = 86400,
        ['jwt_issuer'] = 'kong',
        ['oauth_userinfo_to_claims'] = {
          {
            ["userinfo"] = "profiles",
            ["claim"] = "idp_profiles",
          },
        },
      }
      local profile = {
        ['email'] = "foo@bar.com",
        ['profiles'] = {
          "developer@app1",
          "manager@app2"
        }
      }

      local claims = claims_utils:generate_claims_table(conf, profile)

      assert.is_truthy(claims)
      assert.equal(claims['sub'], profile['email'])
      assert.equal(claims['provider'], conf['oauth_provider_alias'])
      assert.equal(claims['iss'], conf['jwt_issuer'])
      assert(table_eq(claims['idp_profiles'], {"developer@app1", "manager@app2"}))
      assert.equal(claims['iat'], ngx.time())
      assert.equal(claims['exp'], (ngx.time() + conf['jwt_validity']) )
    end)

    it("google", function()
      local conf = {
        ['oauth_provider'] = "google",
        ['oauth_provider_alias'] = nil,
        ['jwt_validity'] = 86400,
        ['jwt_issuer'] = 'kong',
        ['oauth_userinfo_to_claims'] = {},
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
