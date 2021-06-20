require "spec.helpers"

local PLUGIN_NAME = "oauth-jwt-signer"

describe("[" .. PLUGIN_NAME .. "] state_utils", function()

  local state_utils = require("kong.plugins." .. PLUGIN_NAME .. ".state_utils")
  local state_algorithm = "sha256"
  local state_secret = "mystatesecret"

  describe("validate_and_decode_state", function()
    it("validates state v0", function()
      local state = 'eyJ2IjoidjAiLCJkIjoidjA7aHR0cHM6Ly9odHRwYmluLm9yZy9hbnl0aGluZz9mb289YmFyJmE9YiIsInMiOiJxVVZaR0xBNHFQdW9hRFM2UFRERFBVbXBtUHV3cks1alZ4MVZJZXhrUzFJIn0'
      local state_string, err, state_version = state_utils:validate_and_decode_state(state, state_secret, state_algorithm)
      
      assert.is_nil(err)
      assert.is_truthy(state_string)
      assert.is_truthy(state_version)
      assert.equal(state_string, "v0;https://httpbin.org/anything?foo=bar&a=b")
      assert.equal(state_version, "v0")
    end)

    it("validates wrong signature 1", function()
      local state = 'eyJ2IjoidjAiLCJkIjoidjA7aHR0cHM6Ly9odHRwYmluLm9yZy9hbnl0aGluZz9mb289YmFyJmE9YiIsInMiOiJabTl2WW1GeSJ9'
      local state_string, err, state_version = state_utils:validate_and_decode_state(state, state_secret, state_algorithm)
      
      assert.is_truthy(err)
      assert.is_nil(state_string)
      assert.is_nil(state_version)
      assert.equal(err, "State signature does not match.\nState Signature: Zm9vYmFy, Calculated Signature: qUVZGLA4qPuoaDS6PTDDPUmpmPuwrK5jVx1VIexkS1I")
    end)

    it("validates wrong signature 2", function()
      local state = 'eyJ2IjoidjAiLCJkIjoidjA7aHR0cHM6Ly9oaWphY2suaXQiLCJzIjoicVVWWkdMQTRxUHVvYURTNlBURERQVW1wbVB1d3JLNWpWeDFWSWV4a1MxSSJ9'
      local state_string, err, state_version = state_utils:validate_and_decode_state(state, state_secret, state_algorithm)
      
      assert.is_truthy(err)
      assert.is_nil(state_string)
      assert.is_nil(state_version)
      assert.equal(err, "State signature does not match.\nState Signature: qUVZGLA4qPuoaDS6PTDDPUmpmPuwrK5jVx1VIexkS1I, Calculated Signature: VB_oafwlyO_R8msB1JVMjc8GETX7aEv6D8v7C2EpFQA")
    end)
  end)

  describe("parse_state", function()
    it("truthy", function()
      local state_version = "v0"
      local state_string = "v0;https://httpbin.org/anything?foo=bar&a=b"
      local state_tbl, err = state_utils:parse_state(state_version, state_string)
      
      assert.is_nil(err)
      assert.is_truthy(state_tbl)
      assert.equal(state_tbl["redirect"]   , "https://httpbin.org/anything?foo=bar&a=b")
    end)

    it("parser version not implemented", function()
      local state_version = "v1"
      local state_string = "v0;https://httpbin.org/anything?foo=bar&a=b"
      local state_tbl, err = state_utils:parse_state(state_version, state_string)
      
      assert.is_nil(state_tbl)
      assert.is_truthy(err)
      assert.equal(err, "Parser for State version " .. state_version .. " not implemented yet.")
    end)

    it("fail when spoofing state version", function()
      local state_version = "v0"
      local state_string = "v1;https://httpbin.org/anything?foo=bar&a=b"
      local state_tbl, err = state_utils:parse_state(state_version, state_string)
      
      assert.is_nil(state_tbl)
      assert.is_truthy(err)
      assert.equal(err, "State version does not match state at state string.")
    end)
  end)

end)
