# ex_Datacrunch

An Elixir library for the Datacrunch Networks API. The Datacrunch API documentation can be found at [Docs](https://datacrunch.stoplight.io/docs/datacrunch-public/public-api.yml)

#### Features

### Datacrunch.fetch_access_token

Each time the elixir terminal is run the account access token must be fetched to be able to store the necessary authorization token to make API calls.

- `lib/api_wrapper.ex` - contains Tesla configuration and `perform_requests()` helper function that processes the HTTP request command with various arguments from the user functions.
- `lib/datacrunch.ex` - contains all user functions that correspond to an endpoint in the datacrunch API.
- `test/datacrunch_test.exs` - containts all unit and end to end tests, unit tests require a valid instance id to be run. Commented tests incur costs.

- All user functions return `{:ok, <response_body>}` upon successful execution
  and `{:error, <code: detail>}` upon failure with the error code and its description.
- The following user functions have been implemented exactly per the specifications:
- [x] `fetch_access_token`
- [x] `create_instance`
- [x] `delete_instance`
- [x] `start_instance`
- [x] `stop_instance`
- [x] `get_instance_by_id`
- [x] `get_instance_list`
- [x] `get_pricing_information`
- [x] `fetch_groups`
- [x] `test_rate_limit`
- [x] `get_instances_types`
- [x] `get_images`
- [x] `check_availability`

#### Setting up Credentials

Secret crendentials can be set up as environment variables to `config/.env` as follows:

```
export DATACRUNCH_SSHKEY='<ssh_key>'
export DATACRUNCH_ID='<id>'
export DATACRUNCH_SECRET= '<secret>'
```

#### Tests

All tests can be run by using mix test. Tests that incur costs are commented out by and tagged by a warning message. If the tests need to be run it is recommended to run these tests by uncommenting them one at a time and run it using the command: mix test --only {tag_name}.

#### Rate Limit

The exact rate limit is unknown and has passed tests for 10000 requests per hour
