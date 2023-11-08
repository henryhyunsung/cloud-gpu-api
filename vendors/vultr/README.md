# Vultr
Elixir implementation for the [Vultr API](https://www.vultr.com/api/).

This implementation covers:
- Starting machines
- Stopping machines
- Deleting machines
- Listing machines
- Fetching billing rates for machines

Audit logs are not implemented as Vultr does not support this. Neither does Vultr support projects.


## Setup
To build this module, run
```sh
mix deps.get
mix compile
```

Tests can be run using
```sh
# Just run tests
mix test

# Run tests and generate a coverage report
mix test --cover
```

This library can be manually tested with
```sh
iex -S mix
```


## Notes
- Vultr does not support fetching information for a machine that was deleted.
- Sometimes fetching machines can be unreliable when changing states.
- Waiting for a state change when starting/stopping a machine will just poll the machine for state every five seconds. This is similar to the implementaiton for Paperspace, which was based on official Node.js package.
- Vultr has a different distinction of "bare metal" and GPU instances - it seems for GPU instances we want to not actually use "bare metal".



# TODO
- Tests for start/stop/delete.
- Increase code coverage for request methods by testing each different response status code.
