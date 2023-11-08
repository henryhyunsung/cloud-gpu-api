# ex_E2E

An Elixir library for the E2E Networks API.

E2E Developer API documentation can be found [here](https://docs.e2enetworks.com/developersguide/api/index.html).

#### Features

- `api.ex` - contains Tesla configuration and `perform_requests()` helper function that processes the HTTP request command with various arguments from the user functions.
- `user.ex` - contains helper functions for setting user ID that corresponds to the user name.
- `e2e.ex` - contains all user functions that correspond to an endpoint in the E2E API.

- All user functions return `{:ok, <response_body>}` upon successful execution
  and `{:error, <code: detail>}` upon failure with the error code and its description.
- The following user functions have been implemented exactly per the specifications:
- [x] `create_node`
- [x] `delete_node`
- [x] `get_node_by_id`
- [x] `get_node_list`
- [x] `start_node`
- [x] `stop_node`
- [x] `get_customer_details`
- [x] `get_user_ids`
- [x] `get_pricing`
- [x] `get_audit_log "name" `
- [x] `get_audit_log_by_id id`
- [x] `get_tags`
- [x] `list get_groups`

To do user attribution the contact_person_id must be set, this is different from the customer registration number (received from get_customer_number) as this refers to the account that owns the project. Each user inside the project is given an id that is used for traceability and a list of this is returned using get_user_id. This id

For E2E both tags and groups give functionality to group nodes for management purposes (billing purposes TBD) and thus list_tags and list_groups both return the lists that can be used to link nodes together.

Rate limit is `5000` requests per hour per OAuth Token, as stated in [E2E Getting Started](https://docs.e2enetworks.com/developersguide/api/intro.html).

Access token can be created by following [E2E Access Token Guide](https://docs.e2enetworks.com/guides/create_API_access_token.html).

#### Setting up Credentials

API Key `E2E_APIKEY` and authorisation token `E2E_AUTHTOKEN` can be set up as environment variables to `config/.env` as follows:

```
E2E_APIKEY='<api_key>'
E2E_AUTHTOKEN='<auth_token>'
```

#### Vendor API Tasks

##### Retrieve Access Token

E2E uses the same authorisation token for every API call.
Therefore, tokens do not need to be regenerated for fetching results.
Hence, the authorisation token `E2E_AUTHTOKEN` is set up as an environment variable alongside API key `E2E_APIKEY`.

##### User/Account Identifier

Same credentials are used for all users within the account.
E2E differentiates users by `customer_id` when features are accessed through the GUI, but API calls are grouped to the single main user due to common credentials.

##### List/Specific Instance Info

Information about the instances are outputted in the response format written in the specifications.

##### Start/Stop/Delete

E2E provides comprehensive response messages.
Hence, we return the raw data.

##### Pricing

E2E returns the hourly price as part of the specific instance information response.
Total elapsed time for the instance is calculated by subtracting the time created from the current time, then rounded up to the nearest hour.
Pricing information are outputted in the response format written in the specifications.

##### Audit Log

E2E returns CSV text for the complete audit log of the account.
Each log has the attributes `name`, `time`, `region`, `event`, `ip`.
Some attributes required by the specifications are not present in the audit log from E2E.

There are two way to retrieve the audit_logs():

1. By node name. This retrieves the audit logs for all of the nodes and then filters by node name. This can fail if two or more nodes have had the same name.
2. By node ID. This is the preferred method if the node has been cached or not deleted however the access of this endpoint ('nodes/nodeactionlog/{vm_id}?) requires the value of the vm_id which can only be retrieved while the node has not been deleted. This endpoint also does not retrieve any user attribution details.

##### Project List

E2E offer two types of ways to sort youre nodes. Both groups and tags can be used to sort nodes for management purposes.
