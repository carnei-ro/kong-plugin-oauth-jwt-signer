local state_algorithm = "sha256"
local state_secret = "mystatesecret"
local string_to_sign = 'v0;https://httpbin.org/anything?foo=bar&a=b'


local openssl_hmac = require("resty.openssl.hmac")
local cjson        = require("cjson.safe").new()
local b64_encode   = require("ngx.base64").encode_base64url

cjson.decode_array_with_array_mt(true)

local signature, _ = openssl_hmac.new(state_secret, state_algorithm):final(string_to_sign)
local signature_b64 = b64_encode(signature)
print("signature_b64 = " .. signature_b64)
print("state = " .. b64_encode('{"v":"v0","d":"' .. string_to_sign .. '","s":"' .. signature_b64 ..'"}'))
print("state wrong_sig1 = " .. b64_encode('{"v":"v0","d":"' .. string_to_sign .. '","s":"' .. b64_encode('foobar') ..'"}'))
print("state wrong_sig2 = " .. b64_encode('{"v":"v0","d":"v0;https://hijack.it","s":"' .. signature_b64 ..'"}'))
