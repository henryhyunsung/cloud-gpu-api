# Paperspace

## Setup
```sh
# Build project
mix deps.get
mix compile

# Run? Unsure
iex -S mix
```

## Testing
The API Key can be set as an environment variable by using the `export` command in `/config/.env`:
```sh
export PAPERSPACE_APIKEY="<apikey>"
```
This allows tests to access this key.

Tests are designed to be run in an integrated terminal as follows:
```sh
# Run tests, excluding disabled tests
mix test --exclude disabled
# Run all tests. May take a couple minutes
mix test
```

To run a specific test, use `mix test test/paperspace_test.exs:<line_num>`.

## Vendor API Tasks

### Retrieve Access Token

API endpoints mostly require only an API key as authentication. Some requests such as listing machine events also requires the id of a machine.

### User/Account Identifier

In the 'authentication' endpoint, https://docs-next.paperspace.com/web-api/authentication, Paperspace has at least two types of user identifiers. The first, `id`, is a unique id that can be accessed through the GUI. The second, `analyticsId` is used internally, and is the value returned when quering machine events. There is a similar pair of ids for teams.

### List Info About Instance(s)

As per the specifications, information about the instances are outputted in the required response format. Note that Paperspace doesn't seem to support suspending a machine.

### Start/Stop/Delete

Upon attempting to perform these functions, Paperspace returns a number of possible, and well documented response messages. Note that these functions do not block until state change.

### Pricing

Pricing information is calculated using values from the monthly rate of storage and hourly rate of machine use, with the assumption that pricing is on-demand. 

### Audit Log

Machine events are returned, with the exception that no 'severity' value can be obtained, and the user id is equivalent to the `analyticsId` mentioned previously. The machine must exist in order to retrieve its' logs.

### Project List

Projects are not supported for Paperspace metal servers.

### Other

No rate limit could be found - the `RateLimit-Limit` header from a request does not return a value, and paperspace documentation provides no evidence that a limit exists.



# Demo Code
```sh
# Install elixir
sudo add-apt-repository ppa:rabbitmq/rabbitmq-erlang # Then [ENTER]
sudo apt update
sudo apt install -y elixir # May need [ENTER] if services popup

# If using SSH key for pulling repo, scp over key and start SSH agent.
# This may need to be done if 2FA enabled on git
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/your_private_key_name

# Pull repo and checkout right branch
git clone https://github.com/StrongUniversity/USYD-06-API-1.git
cd USYD-06-API-1
git checkout feature/paperspace

# Navigate to directory and build project
cd ex_paperspace
mix deps.get
mix compile

# Set Paperspace API key environment var, and run tests to see if installed correctly
export PAPERSPACE_APIKEY="the api key for paperspace"
mix test --exclude disabled

# Start program to run demo
iex -S mix
```


```elixir
# Read API key. Need the ; ... bit so that API key isn't echoed
apiKey = System.get_env("PAPERSPACE_APIKEY"); IO.puts("Read API key")

# Set machineId to the test machine
machineId = "pslhk2dea" # Update for actual demo

# List all machines
Paperspace.list_machines(apiKey)

# List the specific machine
Paperspace.list_machine(apiKey, machineId)

# Start the machine
Paperspace.start_machine(apiKey, machineId)

# Fetch billing rate information for machine
Paperspace.fetch_pricing_info(apiKey, machineId)

# Fetch audit log for machine
Paperspace.fetch_audit_log(apiKey, machineId)

# Shut down machine
Paperspace.stop_machine(apiKey, machineId)

# And delete machine
Paperspace.delete_machine(apiKey, machineId)
```
