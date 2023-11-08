# Fluidstack

The Fluidstack API has very recently been redesigned. 

- The previous API used conventions established in the documentation here:
https://fluidstack.notion.site/API-Documentation-1627d4a8fc3a406ab8b054fc63a56fcc

The current API still requires the same credential system but has updated
return models, http request requirements, and available information. 

- The new API documentation can be retrieved from: 
https://api.fluidstack.io/

A users api key and token can be retrieved (and generated) from the dashboard.

- This can be retrieved here: https://console2.fluidstack.io/

## Setup

Build the mix project with
```sh
mix deps.get
mix compile
```

When testing with `mix test`, include the following environment variables.
```sh
export FLUIDSTACK_APIKEY=<fluidstack_api_key>
export FLUIDSTACK_APITOKEN=<fluidstack_api_token>
export FLUIDSTACK_TESTID=<fluidstack_machine_id>"
```

To use the interactive shell, use the following command:
```sh
iex -S mix
```

## Testing

Before testing, ensure that the environment variables are set by running:
```sh
source config/.env
```

Tests are designed to be run in an integrated terminal as follows:
```sh
# Run all tests. 
mix test

# [RECOMMENDED] Run tests, excluding disabled tests.
mix test --exclude disabled

# [RECOMMENDED] Run individual tests by tag.
mix test --only <tag_name>
```

Disabled tests include starting and stopping machines. They are better run individually since: they may incur costs; the command `mix test` runs test in a random order.

## Deliverables

#### COMPLETE: Retrieve access token

An API key and token should be provided by the user. These credentials can be used to create generate a new token which invalidates the old.

#### COMPLETE: User/Account id

User account information can be retrieved. This displays information such as email, username, api key, ssh keys and other user properties.

#### COMPLETE: List information about all virtual machine instances

Information related to each current existing instance associated with a key-token pair will be returned.

#### COMPLETE: Get information about a specific virtual machine instance

Uses the previous deliverable to filter out instance information.

#### COMPLETE: Start, stop and delete a specific virtual machine instance

Each action has a different endpoint. Fluidstack will return a message indicating success or failure. 

#### COMPLETE: Retrieve pricing information about a virtual machine instance

Returns the price/hour of the each existing instance. 

#### COMPLETE: Retrieve audit logging about a specific virtual machine instance

Logging information can be returned about all instances. The creation, start/stop times, and deletion times of all machines are included.

#### UNAVAILABLE: Retrieve a list of projects

Fluidstack does not have a notion of grouping resources. It does however allow the use of sub-accounts.

#### Rate Limit
The rate limit is unknown. Tests indicate it is above 10000 requests per hour.
