# CHANGELOG

## Table of Contents

- [0.3.0](#030)
- [0.2.0](#020)
- [0.1.1](#011)
- [0.1.0](#010)

## [0.3.0]

> Release date: 2021-07-18

- feat: Support signing (RS) JWTs using HashiCorp Vault

## [0.2.0]

> Release date: 2021-07-15

- feat: Support creating Claims based on UserInfo from provider using `config.oauth_userinfo_to_claims`. Code from [carnei-ro/kong-gluu-oauth-jwt-signer](https://github.com/carnei-ro/kong-gluu-oauth-jwt-signer), thanks @robertoej.

    ```yaml
    plugins:
      - name: oauth-jwt-signer
        config:
          oauth_userinfo_to_claims:
            - claim: profile
              userinfo: profiles
    ```

## [0.1.1]

> Release date: 2021-06-21

- chore: linting code

## [0.1.0]

> Release date: 2021-06-20

- Initial release
- Support for Providers: custom, facebook, github, gitlab, google, microsoft, yandex, zoho
