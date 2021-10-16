# Kong Plugin OAuth JWT Signer

summary: Generate JWT based on OAuth/OpenID flow.

Use this plugin as OpenID Client **callback** endpoint. It signs a JWT to be used and validated with **Kong Plugin OAuth JWT**.

<!-- BEGINNING OF KONG-PLUGIN DOCS HOOK -->
## Plugin Priority

Priority: **1000**

## Plugin Version

Version: **0.3.0**

## config

| name | type | required | validations | default |
|-----|-----|-----|-----|-----|
| state_algorithm | string | <pre>true</pre> | <pre>- one_of:<br/>  - sha256<br/>  - sha1<br/>  - md5</pre> | <pre>sha256</pre> |
| state_secret | string | <pre>true</pre> |  |  |
| jwt_algorithm | string | <pre>true</pre> | <pre>- one_of:<br/>  - HS256<br/>  - HS384<br/>  - HS512<br/>  - RS256<br/>  - RS384<br/>  - RS512</pre> | <pre>RS256</pre> |
| jwt_key_id | string | <pre>true</pre> |  |  |
| jwt_key_value | string | <pre>false</pre> |  |  |
| jwt_issuer | string | <pre>true</pre> |  | <pre>kong</pre> |
| jwt_validity | number | <pre>true</pre> |  | <pre>86400</pre> |
| jwt_cookie | boolean | <pre>true</pre> |  | <pre>true</pre> |
| jwt_cookie_name | string | <pre>true</pre> |  | <pre>oauth_jwt</pre> |
| jwt_cookie_secure | boolean | <pre>true</pre> |  | <pre>true</pre> |
| jwt_cookie_http_only | boolean | <pre>true</pre> |  | <pre>true</pre> |
| jwt_cookie_domain | string | <pre>false</pre> |  |  |
| jwt_response | boolean | <pre>true</pre> |  | <pre>false</pre> |
| jwt_response_status_code | number | <pre>true</pre> |  | <pre>200</pre> |
| jwt_response_payload_key | string | <pre>true</pre> |  | <pre>access_token</pre> |
| oauth_provider | string | <pre>true</pre> | <pre>- one_of:<br/>  - custom<br/>  - facebook<br/>  - github<br/>  - gitlab<br/>  - google<br/>  - microsoft<br/>  - yandex<br/>  - zoho</pre> | <pre>google</pre> |
| oauth_provider_alias | string | <pre>false</pre> |  |  |
| oauth_ssl_verify | boolean | <pre>true</pre> |  | <pre>true</pre> |
| oauth_token_endpoint | string | <pre>false</pre> |  |  |
| oauth_token_endpoint_method | string | <pre>true</pre> | <pre>- match: ^%u+$</pre> | <pre>POST</pre> |
| oauth_token_endpoint_timeout | number | <pre>true</pre> |  | <pre>3000</pre> |
| oauth_token_endpoint_grant_type | string | <pre>true</pre> |  | <pre>authorization_code</pre> |
| oauth_userinfo_endpoint | string | <pre>false</pre> |  |  |
| oauth_userinfo_endpoint_method | string | <pre>true</pre> | <pre>- match: ^%u+$</pre> | <pre>GET</pre> |
| oauth_userinfo_endpoint_timeout | number | <pre>true</pre> |  | <pre>3000</pre> |
| oauth_userinfo_endpoint_header_authorization | boolean | <pre>true</pre> |  | <pre>true</pre> |
| oauth_userinfo_endpoint_header_authorization_prefix | string | <pre>true</pre> |  | <pre>Bearer</pre> |
| oauth_userinfo_endpoint_querystring_authorization | boolean | <pre>true</pre> |  | <pre>false</pre> |
| oauth_userinfo_endpoint_querystring_access_token | boolean | <pre>true</pre> |  | <pre>false</pre> |
| oauth_userinfo_endpoint_querystring_more | map[string][string] | <pre>true</pre> |  |  |
| oauth_userinfo_to_claims | set of records** | <pre>true</pre> |  |  |
| oauth_client_id | string | <pre>true</pre> |  |  |
| oauth_client_secret | string | <pre>true</pre> |  |  |
| vault_enabled | boolean | <pre>true</pre> |  | <pre>false</pre> |
| vault_aws_region | string | <pre>true</pre> |  | <pre>us-east-1</pre> |
| vault_protocol | string | <pre>true</pre> |  | <pre>https</pre> |
| vault_host | string | <pre>false</pre> |  |  |
| vault_port | number | <pre>true</pre> |  | <pre>443</pre> |
| vault_auth_method | string | <pre>true</pre> | <pre>- one_of:<br/>  - aws</pre> | <pre>aws</pre> |
| vault_auth_backend | string | <pre>true</pre> |  | <pre>aws</pre> |
| vault_role | string | <pre>false</pre> |  |  |
| vault_ssl_verify | boolean | <pre>true</pre> |  | <pre>false</pre> |
| vault_login_timeout | number | <pre>true</pre> |  | <pre>2000</pre> |
| vault_transit_backend | string | <pre>true</pre> |  | <pre>transit</pre> |
| vault_rsa_keyname | string | <pre>true</pre> |  | <pre>kong</pre> |
| vault_sign_timeout | number | <pre>true</pre> |  | <pre>2000</pre> |

### record** of oauth_userinfo_to_claims

| name | type | required | validations | default |
|-----|-----|-----|-----|-----|
| claim | string | <pre>true</pre> |  |  |
| userinfo | string | <pre>true</pre> |  |  |

## Usage

```yaml
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
      oauth_userinfo_to_claims:
        - claim: ''
          userinfo: ''
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
