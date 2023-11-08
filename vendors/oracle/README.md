# Oracle

## Introduction
This repository contains an implementation for interfacing with Oracle Cloud
Infrastructure (OCI) written in Elixir.
It was built with reference to the Python implementation from Team 7.
Many thanks to Team 7's expert software engineer, Jason Tang, for his Python
implementation and his extended help with my Elixir work, even thought it was
not part of his responsibility.

## Environment Variables
_**Note:**_ You can obtain all the required information mentioned below from your OCI account.
For detailed graphical assistance, please refer to
[Jason's Oracle Python Implementation Demo Video](https://www.youtube.com/watch?v=ivkkpdRRggc).

### Instructions
1. Create an `.env` file in `/config/` with the following template and
data:
```
export TENANCY="<tenancy_id>"
export USER="<user_id>"
export FINGERPRINT="<fingerprint>"
export KEYPATH="</absolute/path/to/private/key/file.pem>"
export REGION="<region>"
```
2. Source the environment variables in bash: `source /config/.env`
3. Place the private key file `.pem` in `/config/`.

### Signature
To authenticate requests, it is essential to sign them.
This requires the following information:
- Tenancy ID
- User ID
- Certificate fingerprint
- Private key (PEM string)

Together, the tenancy ID, user ID and fingerprint combine to form the API key.
(Please note that this information is implemented in code and is provided
here for informational purposes.)
```
<apikey> = <tenancy_id>/<user_id>/<fingerprint>
```

### Region
When creating an OCI account, it's important to note that the account must be
permanently registered to a specific server location.
This chosen location will determine the region string used to form the base
URL for accessing API endpoints.
For example, when selecting the Sydney server, the corresponding region
string would be `ap-sydney-1`.

## Signing Requests
_**Note:**_ Detailed information about signing OCI API requests can be found in
the official documentation about [Request Signatures](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/signingrequests.htm).

## Errors
_**Note:**_ Detailed information about errors returned can be found in the
official documentation about [API Errors](https://docs.oracle.com/en-us/iaas/Content/API/References/apierrors.htm#ErrorDetailsandTroubleshooting).