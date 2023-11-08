# Cloud GPU API

## Setup

For guide on setting up both Github and Bitbucket remotes, see [here](#git-with-github-and-bitbucket).

If Elixir isn't installed, install with

```sh
sudo add-apt-repository ppa:rabbitmq/rabbitmq-erlang
sudo apt update
sudo apt install elixir-dev
```

Build the mix project with

```sh
mix deps.get
mix compile
```

Set the following environment variables:

```sh
# Datacrunch
export DATACRUNCH_SSHKEY='your datacrunch ssh key'
export DATACRUNCH_ID='your datacrunch ID'
export DATACRUNCH_SECRET='your datacrunch secret'

# E2E
export E2E_APIKEY="your e2e API key"
export E2E_AUTHTOKEN="your e2e authoken"

# Latitude.sh
export LATITUDESH_APIKEY="your latitude.sh API key"

# Oracle
export TENANCY="<tenancy_id>"
export USER="<user_id>"
export FINGERPRINT="<fingerprint>"
export KEYPATH="</absolute/path/to/private/key/file.pem>"
export REGION="<region>"

# Paperspace
export PAPERSPACE_APIKEY="your paperspace API key"

# Vultr
export VULTR_APIKEY="your vultr API key"

# Fluidstack
export FLUIDSTACK_APIKEY="<fluidstack_api_key>"
export FLUIDSTACK_APITOKEN="<fluidstack_api_token>"
export FLUIDSTACK_TESTID="<fluidstack_machine_id>"
```

Run tests with `mix test` to ensure project is built correctly. Alternatively, run `mix test --coverage` to generate code coverage documentation.

Run `mix docs` to generate some documentation in the `doc/` folder; open `index.html` in your browser to navigate.

## Supported Cloud Providers

- Datacrunch: SEe [README](vendors/datacrunch/README.md)
- E2E: See [README](vendors/e2e/README.md)
- Latitde.sh: See [README](vendors/latitude_sh/README.md)
- Oracle: See [README](vendors/oracle/README.md)
- Paperspace: See [README](vendors/paperspace/README.md)
- Vultr: See [README](vendors/vultr/README.md)

## Misc

### Git with Github and Bitbucket

Make sure you've added SSH keys for both [Github](https://github.com/settings/keys) and [Bitbucket](https://bitbucket.org/account/settings/ssh-keys/).

If not already generated, would probably be best to use Ed25519 instead of RSA as github sometimes complains with older key types

```sh
ssh-keygen -t ed25519
```

Clone the Github repo first

```sh
git clone git@github.com:StrongUniversity/USYD-06-API-1.git
```

If you'd rather the remote for Github be named something other than `origin`, you can rename it like such

```sh
# git remote rename <old name> <new name>
git remote rename origin origin-github
```

If you're used to typing `git push origin master` though for example, probably make sure `origin` is the one for Github as ideally that will be up to date first. You can list the current remotes with `git remote -v`

Add the Bitbucket remote

```sh
# git remote add <name> <url>
git remote add origin-bitbucket git@bitbucket.org:rbeh9716/comp3888_f15_02.git
```

Set the profile for this repo using name and uni email

```sh
git config user.name "Your Name"
git config user.email abcd1234@uni.sydney.edu.au
```

When working on the project, pull and fetch from the Github repo. We'll just occasionally push to Bitbucket.

```sh
# If didn't rename Github remote, use `origin` instead of `origin-github`

# Fetching
git fetch -v # -v will show if Github and Bitbucket repos are both up to date too

# Listing branches
git branch -v -a
# If these are showing the Bitbucket branches instead of Github branches, you
#  may need to be more verbose with checkout

# Checking out
git switch origin-github/develop
# OR if cloned from Github first, I believe it uses the first remote added and
#  no need to specify the remote
git switch develop

# Pulling
git pull origin-github

# Pushing
git push origin-github develop
git push origin-bitbucket develop
```
