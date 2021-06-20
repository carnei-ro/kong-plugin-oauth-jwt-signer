require "spec.helpers"

local PLUGIN_NAME = "oauth-jwt-signer"

describe("[" .. PLUGIN_NAME .. "] jwt_utils", function()

  local jwt_utils = require("kong.plugins." .. PLUGIN_NAME .. ".jwt_utils")

  describe("jwt_utils", function()
    it("RS256", function()
      local config = {
        ["jwt_algorithm"] = "RS256",
        ["jwt_key_id"] = "privkey1",
        ["jwt_key_value"] = [[-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2QX1yau1ZbKRs2lUm7YqY
xloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQJAGCthklQnXS4LsitISiUD
YA71akkNZwymfRcPjRWp7clQGmHj9JDKxoCHqRsbA9Ho5ovFWRZD3423Wv7o1PJ0
AQIhAP/hqi481mAFjnikFTEr2FWbVdFHQtbsvpEsPRB2jKqhAiEA76Nfs1L+xtOv
SgkNH+/5f3c0yccLJeT3dNpP3aCu6KECIHU9pIgDAAaHBTxpkfwxprGytqNpD0sC
tl418tS0PMeBAiEAhgP84kGZAEKkNihHscO36WQWHn31KxUYmr34ij5xcuECICsg
860obxqltjMuLFJCE47BhAv99+f/4z5lflA/A+Xo
-----END RSA PRIVATE KEY-----]],
      }

      local claims = {
        ['sub'] = "foo@bar.com",
        ['provider'] = "google",
        ['iss'] = "kong",
        ['iat'] = 1624128000,
        ['exp'] = 1624214400
      }

      local jwt, err = jwt_utils:sign_token(config, claims)
      local h,c,_ = jwt:match("([^.]*)%.([^.]*)%.([^.]*)")

      assert.is_truthy(jwt)
      assert.is_nil(err)
      assert.equal(h, "eyJraWQiOiJwcml2a2V5MSIsImFsZyI6IlJTMjU2IiwidHlwIjoiSldUIn0")
      assert.equal(c, "eyJwcm92aWRlciI6Imdvb2dsZSIsImlhdCI6MTYyNDEyODAwMCwiaXNzIjoia29uZyIsImV4cCI6MTYyNDIxNDQwMCwic3ViIjoiZm9vQGJhci5jb20ifQ")
    end)

    it("HS256", function()
      local config = {
        ["jwt_algorithm"] = "HS256",
        ["jwt_key_id"] = "privkey1",
        ["jwt_key_value"] = "my-jwt-secret",
      }

      local claims = {
        ['sub'] = "foo@bar.com",
        ['provider'] = "google",
        ['iss'] = "kong",
        ['iat'] = 1624128000,
        ['exp'] = 1624214400
      }

      local jwt, err = jwt_utils:sign_token(config, claims)
      local h,c,_ = jwt:match("([^.]*)%.([^.]*)%.([^.]*)")

      assert.is_truthy(jwt)
      assert.is_nil(err)
      assert.equal(h, "eyJraWQiOiJwcml2a2V5MSIsImFsZyI6IkhTMjU2IiwidHlwIjoiSldUIn0")
      assert.equal(c, "eyJwcm92aWRlciI6Imdvb2dsZSIsImlhdCI6MTYyNDEyODAwMCwiaXNzIjoia29uZyIsImV4cCI6MTYyNDIxNDQwMCwic3ViIjoiZm9vQGJhci5jb20ifQ")
    end)

  end)

end)
