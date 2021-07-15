local PLUGIN_NAME = "oauth-jwt-signer"

-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end


describe(PLUGIN_NAME .. ": (schema)", function()

  it("oauth custom - missing fields", function()
    local ok, err = validate({
        ["oauth_provider"] = "custom",
        ["state_secret"]   = "mystatesecret",
        ["jwt_key_id"]     = "privkey1",
        ["jwt_key_value"]  = [[-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2QX1yau1ZbKRs2lUm7YqY
xloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQJAGCthklQnXS4LsitISiUD
YA71akkNZwymfRcPjRWp7clQGmHj9JDKxoCHqRsbA9Ho5ovFWRZD3423Wv7o1PJ0
AQIhAP/hqi481mAFjnikFTEr2FWbVdFHQtbsvpEsPRB2jKqhAiEA76Nfs1L+xtOv
SgkNH+/5f3c0yccLJeT3dNpP3aCu6KECIHU9pIgDAAaHBTxpkfwxprGytqNpD0sC
tl418tS0PMeBAiEAhgP84kGZAEKkNihHscO36WQWHn31KxUYmr34ij5xcuECICsg
860obxqltjMuLFJCE47BhAv99+f/4z5lflA/A+Xo
-----END RSA PRIVATE KEY-----]],
        ["oauth_client_id"]     = "myclientid",
        ["oauth_client_secret"] = "myclientsecret",
      })
    assert.is_truthy(err)
    assert.is_nil(ok)
    assert.equal('required field missing', err['config']['oauth_provider_alias'])
    assert.equal('required field missing', err['config']['oauth_token_endpoint'])
    assert.equal('required field missing', err['config']['oauth_userinfo_endpoint'])
  end)

  it("oauth custom - ok", function()
    local ok, err = validate({
        ["oauth_provider"]          = "custom",
        ["oauth_provider_alias"]    = "oauth.foo",
        ["oauth_token_endpoint"]    = "https://oauth.foo/token",
        ["oauth_userinfo_endpoint"] = "https://oauth.foo/user",
        ["state_secret"]            = "mystatesecret",
        ["jwt_key_id"]              = "privkey1",
        ["jwt_key_value"]           = [[-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2QX1yau1ZbKRs2lUm7YqY
xloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQJAGCthklQnXS4LsitISiUD
YA71akkNZwymfRcPjRWp7clQGmHj9JDKxoCHqRsbA9Ho5ovFWRZD3423Wv7o1PJ0
AQIhAP/hqi481mAFjnikFTEr2FWbVdFHQtbsvpEsPRB2jKqhAiEA76Nfs1L+xtOv
SgkNH+/5f3c0yccLJeT3dNpP3aCu6KECIHU9pIgDAAaHBTxpkfwxprGytqNpD0sC
tl418tS0PMeBAiEAhgP84kGZAEKkNihHscO36WQWHn31KxUYmr34ij5xcuECICsg
860obxqltjMuLFJCE47BhAv99+f/4z5lflA/A+Xo
-----END RSA PRIVATE KEY-----]],
        ["oauth_client_id"]     = "myclientid",
        ["oauth_client_secret"] = "myclientsecret",
      })
    assert.is_truthy(ok)
    assert.is_nil(err)
  end)

  it("invalid key when rs*", function()
    local ok, err = validate({
        ["oauth_provider"]          = "custom",
        ["oauth_provider_alias"]    = "oauth.foo",
        ["oauth_token_endpoint"]    = "https://oauth.foo/token",
        ["oauth_userinfo_endpoint"] = "https://oauth.foo/user",
        ["state_secret"]            = "mystatesecret",
        ["jwt_key_id"]              = "privkey1",
        ["jwt_key_value"]           = "foobar",
        ["oauth_client_id"]         = "myclientid",
        ["oauth_client_secret"]     = "myclientsecret",
      })
    assert.is_truthy(err)
    assert.is_nil(ok)
    assert.equal('invalid RSA key', err['config']['jwt_key_value'])
  end)

  it("cannot overwrite sub via oauth_userinfo_to_claims", function()
    local ok, err = validate({
      ["oauth_provider"]           = "custom",
      ["oauth_provider_alias"]     = "oauth.foo",
      ["oauth_token_endpoint"]     = "https://oauth.foo/token",
      ["oauth_userinfo_endpoint"]  = "https://oauth.foo/user",
      ["oauth_userinfo_to_claims"] = {
        {
          ["userinfo"] = "profiles",
          ["claim"] = "idp_profiles",
        },
        {
          ["userinfo"] = "sub",
          ["claim"] = "sub",
        },
      },
      ["state_secret"]             = "mystatesecret",
      ["jwt_key_id"]               = "privkey1",
      ["jwt_key_value"]            = [[-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2QX1yau1ZbKRs2lUm7YqY
xloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQJAGCthklQnXS4LsitISiUD
YA71akkNZwymfRcPjRWp7clQGmHj9JDKxoCHqRsbA9Ho5ovFWRZD3423Wv7o1PJ0
AQIhAP/hqi481mAFjnikFTEr2FWbVdFHQtbsvpEsPRB2jKqhAiEA76Nfs1L+xtOv
SgkNH+/5f3c0yccLJeT3dNpP3aCu6KECIHU9pIgDAAaHBTxpkfwxprGytqNpD0sC
tl418tS0PMeBAiEAhgP84kGZAEKkNihHscO36WQWHn31KxUYmr34ij5xcuECICsg
860obxqltjMuLFJCE47BhAv99+f/4z5lflA/A+Xo
-----END RSA PRIVATE KEY-----]],
      ["oauth_client_id"]     = "myclientid",
      ["oauth_client_secret"] = "myclientsecret",
    })
    assert.is_truthy(err)
    assert.is_nil(ok)
    assert.equal("'sub' claim cannot be overridden", err['config']['oauth_userinfo_to_claims'][2]['claim'])
  end)

  it("cannot overwrite sub via oauth_userinfo_to_claims - ok", function()
    local ok, err = validate({
      ["oauth_provider"]           = "custom",
      ["oauth_provider_alias"]     = "oauth.foo",
      ["oauth_token_endpoint"]     = "https://oauth.foo/token",
      ["oauth_userinfo_endpoint"]  = "https://oauth.foo/user",
      ["oauth_userinfo_to_claims"] = {
        {
          ["userinfo"] = "profiles",
          ["claim"] = "idp_profiles",
        },
      },
      ["state_secret"]             = "mystatesecret",
      ["jwt_key_id"]               = "privkey1",
      ["jwt_key_value"]            = [[-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2QX1yau1ZbKRs2lUm7YqY
xloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQJAGCthklQnXS4LsitISiUD
YA71akkNZwymfRcPjRWp7clQGmHj9JDKxoCHqRsbA9Ho5ovFWRZD3423Wv7o1PJ0
AQIhAP/hqi481mAFjnikFTEr2FWbVdFHQtbsvpEsPRB2jKqhAiEA76Nfs1L+xtOv
SgkNH+/5f3c0yccLJeT3dNpP3aCu6KECIHU9pIgDAAaHBTxpkfwxprGytqNpD0sC
tl418tS0PMeBAiEAhgP84kGZAEKkNihHscO36WQWHn31KxUYmr34ij5xcuECICsg
860obxqltjMuLFJCE47BhAv99+f/4z5lflA/A+Xo
-----END RSA PRIVATE KEY-----]],
      ["oauth_client_id"]     = "myclientid",
      ["oauth_client_secret"] = "myclientsecret",
    })
    assert.is_truthy(ok)
    assert.is_nil(err)
  end)

end)
