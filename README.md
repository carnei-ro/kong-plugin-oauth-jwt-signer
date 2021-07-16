# Kong Plugin OAuth JWT Signer

summary: Generate JWT based on OAuth/OpenID flow.

Use this plugin as OpenID Client **callback** endpoint. It signs a JWT to be used and validated with **Kong Plugin OAuth JWT**.

<!-- BEGINNING OF KONG-PLUGIN DOCS HOOK -->
## Plugin Priority

Priority: **1000**

## Plugin Version

Version: **0.3.0**

## Configs

| name | type | required | default | validations |
| ---- | ---- | -------- | ------- | ----------- |
| config.state_algorithm | **string** | true | <pre>sha256</pre> | <pre>- one_of:<br/>  - sha256<br/>  - sha1<br/>  - md5</pre> |
| config.state_secret | **string** | true |  |  |
| config.jwt_algorithm | **string** | true | <pre>RS256</pre> | <pre>- one_of:<br/>  - HS256<br/>  - HS384<br/>  - HS512<br/>  - RS256<br/>  - RS384<br/>  - RS512</pre> |
| config.jwt_key_id | **string** | true |  |  |
| config.jwt_key_value | **string** | false |  |  |
| config.jwt_issuer | **string** | true | <pre>kong</pre> |  |
| config.jwt_validity | **number** | true | <pre>86400</pre> |  |
| config.jwt_cookie | **boolean** | true | <pre>true</pre> |  |
| config.jwt_cookie_name | **string** | true | <pre>oauth_jwt</pre> |  |
| config.jwt_cookie_secure | **boolean** | true | <pre>true</pre> |  |
| config.jwt_cookie_http_only | **boolean** | true | <pre>true</pre> |  |
| config.jwt_cookie_domain | **string** | false |  |  |
| config.jwt_response | **boolean** | true |  |  |
| config.jwt_response_status_code | **number** | true | <pre>200</pre> |  |
| config.jwt_response_payload_key | **string** | true | <pre>access_token</pre> |  |
| config.oauth_provider | **string** | true | <pre>google</pre> | <pre>- one_of:<br/>  - custom<br/>  - facebook<br/>  - github<br/>  - gitlab<br/>  - google<br/>  - microsoft<br/>  - yandex<br/>  - zoho</pre> |
| config.oauth_provider_alias | **string** | false |  |  |
| config.oauth_ssl_verify | **boolean** | true | <pre>true</pre> |  |
| config.oauth_token_endpoint | **string** | false |  |  |
| config.oauth_token_endpoint_method | **string** | true | <pre>POST</pre> | <pre>- match: "^%u+$"</pre> |
| config.oauth_token_endpoint_timeout | **number** | true | <pre>3000</pre> |  |
| config.oauth_token_endpoint_grant_type | **string** | true | <pre>authorization_code</pre> |  |
| config.oauth_userinfo_endpoint | **string** | false |  |  |
| config.oauth_userinfo_endpoint_method | **string** | true | <pre>GET</pre> | <pre>- match: "^%u+$"</pre> |
| config.oauth_userinfo_endpoint_timeout | **number** | true | <pre>3000</pre> |  |
| config.oauth_userinfo_endpoint_header_authorization | **boolean** | true | <pre>true</pre> |  |
| config.oauth_userinfo_endpoint_header_authorization_prefix | **string** | true | <pre>Bearer</pre> |  |
| config.oauth_userinfo_endpoint_querystring_authorization | **boolean** | true |  |  |
| config.oauth_userinfo_endpoint_querystring_access_token | **boolean** | true |  |  |
| config.oauth_userinfo_endpoint_querystring_more | **map[string][string]** (*check `'config.oauth_userinfo_endpoint_querystring_more' object`) | true |  |  |
| config.oauth_userinfo_to_claims | **set of records** | true |  |  |
| config.oauth_client_id | **string** | true |  |  |
| config.oauth_client_secret | **string** | true |  |  |
| config.vault_enabled | **boolean** | true |  |  |
| config.vault_aws_region | **string** | true | <pre>us-east-1</pre> |  |
| config.vault_protocol | **string** | true | <pre>https</pre> |  |
| config.vault_host | **string** | false |  |  |
| config.vault_port | **number** | true | <pre>443</pre> |  |
| config.vault_auth_method | **string** | true | <pre>aws</pre> | <pre>- one_of:<br/>  - aws</pre> |
| config.vault_auth_backend | **string** | true | <pre>aws</pre> |  |
| config.vault_role | **string** | false |  |  |
| config.vault_ssl_verify | **boolean** | true |  |  |
| config.vault_login_timeout | **number** | true | <pre>2000</pre> |  |
| config.vault_transit_backend | **string** | true | <pre>transit</pre> |  |
| config.vault_rsa_keyname | **string** | true | <pre>kong</pre> |  |
| config.vault_sign_timeout | **number** | true | <pre>2000</pre> |  |

### 'config.oauth_userinfo_endpoint_querystring_more' object

| keys_type | keys_validations | values_type | values_required | values_default | values_validations |
| --------- | ---------------- | ----------- | --------------- | -------------- | ------------------ |
| **string** |  | **string** | true |  |  |

## Usage

```yaml
---
plugins:
- name: oauth-jwt-signer
  enabled: true
  config:
    state_algorithm: sha256
    state_secret: ''
    jwt_algorithm: RS256
    jwt_key_id: ''
    jwt_key_value: ''
    jwt_issuer: kong
    jwt_validity: 86400
    jwt_cookie: true
    jwt_cookie_name: oauth_jwt
    jwt_cookie_secure: true
    jwt_cookie_http_only: true
    jwt_cookie_domain: ''
    jwt_response: false
    jwt_response_status_code: 200
    jwt_response_payload_key: access_token
    oauth_provider: google
    oauth_provider_alias: ''
    oauth_ssl_verify: true
    oauth_token_endpoint: ''
    oauth_token_endpoint_method: POST
    oauth_token_endpoint_timeout: 3000
    oauth_token_endpoint_grant_type: authorization_code
    oauth_userinfo_endpoint: ''
    oauth_userinfo_endpoint_method: GET
    oauth_userinfo_endpoint_timeout: 3000
    oauth_userinfo_endpoint_header_authorization: true
    oauth_userinfo_endpoint_header_authorization_prefix: Bearer
    oauth_userinfo_endpoint_querystring_authorization: false
    oauth_userinfo_endpoint_querystring_access_token: false
    oauth_userinfo_endpoint_querystring_more: {}
    oauth_userinfo_to_claims: []
    oauth_client_id: ''
    oauth_client_secret: ''
    vault_enabled: false
    vault_aws_region: us-east-1
    vault_protocol: https
    vault_host: ''
    vault_port: 443
    vault_auth_method: aws
    vault_auth_backend: aws
    vault_role: ''
    vault_ssl_verify: false
    vault_login_timeout: 2000
    vault_transit_backend: transit
    vault_rsa_keyname: kong
    vault_sign_timeout: 2000
```
<!-- END OF KONG-PLUGIN DOCS HOOK -->

### Gluu Example

```yaml
---
plugins:
  - name: oauth-jwt-signer
    enabled: true
    config:
      state_secret: mystatesecret
      jwt_key_id: privkey1
      jwt_key_value: |
        -----BEGIN RSA PRIVATE KEY-----
        MIIBOgIBAAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2QX1yau1ZbKRs2lUm7YqY
        xloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQJAGCthklQnXS4LsitISiUD
        YA71akkNZwymfRcPjRWp7clQGmHj9JDKxoCHqRsbA9Ho5ovFWRZD3423Wv7o1PJ0
        AQIhAP/hqi481mAFjnikFTEr2FWbVdFHQtbsvpEsPRB2jKqhAiEA76Nfs1L+xtOv
        SgkNH+/5f3c0yccLJeT3dNpP3aCu6KECIHU9pIgDAAaHBTxpkfwxprGytqNpD0sC
        tl418tS0PMeBAiEAhgP84kGZAEKkNihHscO36WQWHn31KxUYmr34ij5xcuECICsg
        860obxqltjMuLFJCE47BhAv99+f/4z5lflA/A+Xo
        -----END RSA PRIVATE KEY-----
      oauth_provider: custom
      oauth_provider_alias: gluu
      oauth_token_endpoint: https://my-gluu-server.com/oxauth/restv1/token
      oauth_userinfo_endpoint: https://my-gluu-server.com/oxauth/restv1/userinfo
      oauth_client_id: myclientid
      oauth_client_secret: myclientsecret
```

### Gluu Example with HashiCorp Vault (AWS auth method)

```yaml
---
plugins:
  - name: oauth-jwt-signer
    enabled: true
    config:
      state_secret: mystatesecret
      jwt_key_id: vault-kong-key01
      oauth_provider: custom
      oauth_provider_alias: gluu
      oauth_token_endpoint: https://my-gluu-server.com/oxauth/restv1/token
      oauth_userinfo_endpoint: https://my-gluu-server.com/oxauth/restv1/userinfo
      oauth_client_id: myclientid
      oauth_client_secret: myclientsecret
      vault_enabled: true
      vault_host: "vault.carnei.ro"
      vault_role: "jwt_signer"
      vault_transit_backend: "transit/keys/kong"
      vault_rsa_keyname: "kong-key01"
```
