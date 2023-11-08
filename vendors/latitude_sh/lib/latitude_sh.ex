defmodule LatitudeSh do
  @moduledoc """
  This is a module designed to interact with the Latitude.sh API.
  It is currently run in the terminal (using `iex -S mix`).

  The module requires that the LATITUDESH_APIKEY System environment variable is set to the
  users' API key before running; otherwise any method call will result in a 401 return code.

  Each method interacting with the API has some expected return codes that can be found on the
  API page, most often in [this list](https://docs.latitude.sh/reference/http-responses). We have
  default responses for each, but methods can override defaults to provide more information.

  To see documentation for each function, run `mix docs` and open `doc/LatitudeSh.html` in your browser.
  """
  import LatitudeSh.ApiWrappers
  require Logger

  @generic_msg_400 "Bad Request [400] -- General client error, possible malformed data."
  @generic_msg_401 "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."
  @generic_msg_403 "Forbidden [403] -- The request is not allowed."
  @generic_msg_404 "Not Found [404] -- The resource was not found."
  @generic_msg_422 "Unprocessable Entity [422] -- The data was well-formed but invalid."
  @generic_msg_429 "Too Many Requests [429] -- The client has reached or exceeded a rate limit, or the server is overloaded."
  @generic_msg_500 "Server Error [500] - Something went wrong on our end."

  @server_creation_delay 2000
  @initial_server_action_delay 4000
  @recurring_server_action_delay 1000

  defp generic_errors({:ok, %Tesla.Env{status: status}}) do
    case status do
      400 -> {:error, @generic_msg_400}
      401 -> {:error, @generic_msg_401}
      403 -> {:error, @generic_msg_403}
      404 -> {:error, @generic_msg_404}
      422 -> {:error, @generic_msg_422}
      429 -> {:error, @generic_msg_429}
      500 -> {:error, @generic_msg_500}
    end
  end
  defp generic_errors({status, body}), do: {:error, %{status: status, body: body}}

  defp api_format_error(endpoint, decoded_body) do
    Logger.debug(decoded_body)
    {:error, endpoint <> " response format has changed; see the full body in logs."}
  end

  @doc """
  Fetches information about the API version the user's account is accessing.
  Currently the only data available in the response is the version's release date.

  Response is of the form:
    `{:ok, %{token: api_version_date}}`
  or
    `{:error, reason}`

  API docs: [here](https://docs.latitude.sh/reference/get-current-version)
  """
  def fetch_access_token do
    case get_wrapper("/auth/current_version") do
      {:ok, %Tesla.Env{status: 200, body: body}} -> api_version(Jason.decode!(body))
      other -> generic_errors(other)
    end
  end

  defp api_version(%{"data" => %{"attributes" => %{"current_version" => version}}}), do: {:ok, %{token: version}}
  defp api_version(body), do: api_format_error("/auth/current_version", body)

  @doc """
  Fetches the user's profile data and returns its ID.

  Response is of the form:
    `{:ok, %{user_id: id}}`
  or
    `{:error, reason}`

  API docs: [here](https://docs.latitude.sh/reference/get-user-profile)
  """
  def fetch_account_identifier do
    case LatitudeSh.ApiWrappers.get_wrapper("/user/profile") do
      {:ok, %Tesla.Env{status: 200, body: body}} -> account_id(Jason.decode!(body))
      other -> generic_errors(other)
    end
  end

  defp account_id(%{"data" => %{"id" => id}}), do: {:ok, %{user_id: id}}
  defp account_id(body), do: api_format_error("/user/profile", body)

  @doc """
  Lists all the user's existing server instances. Takes in parameters to adjust pagination.

  Response is of the form.
    ```{:ok, [%{
       instance_id: ID (str),
       name: server hostname,
       region: %{country: country name, site: site slug},
       plan: %{id: plan id, slug: plan slug},
       specs: %{
         machine_type: "bare metal" or others (not tested),
         ip_address: ipv4 address,
         os_type: os name,
         accelerators: ?,
       },
       billing_type: :on_demand or :spot,
       status: :running, :stopped, :deploying, :failed or :unknown
     }]}```
  or
    `{:error, reason}`

  Notes:
  - The API utilizes Offset Pagination; page size and number can be specified in the query.
    The API's default values are page size of 20 and page number 1.
  - The accelerator field has been untested due to GPU unavailability during development.

  API docs: [listing servers](https://docs.latitude.sh/reference/get-servers) and [pagination](https://docs.latitude.sh/reference/pagination).
  """
  def list_servers(page_size \\ 20, page_number \\ 1)
  def list_servers(page_size, page_number) do
    query_params = ['page[size]': page_size, 'page[number]': page_number]
    case get_wrapper("/servers", query_params) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        servers = read_servers(Jason.decode!(body))
        case Enum.find(servers, &(match?({:error, _}, &1))) do
          nil -> {:ok, servers}
          error -> error
        end
      other -> generic_errors(other)
    end
  end

  defp read_servers(%{"data" => []}), do: []
  defp read_servers(%{"data" => servers}), do: Enum.map(servers, &(parse_server(&1)))
  defp read_servers(servers), do: [api_format_error("/servers", servers)]

  defp parse_server(%{
    "id" => server_id,
    "attributes" => %{
      "hostname" => name,
      "plan" => %{"id" => plan_id, "slug" => plan_slug, },
      "team" => %{"hourly_billing" => is_hourly, },
      "role" => machine_type,
      "region" => %{"country" => country, "site" => %{"slug" => site_slug, }},
      "status" => status,
      "primary_ipv4" => ip_address,
      "specs" => %{"gpu" => gpu_specs, },
      "operating_system" => %{"distro" => %{"slug" => os_type, }}
    }
  }) do
    %{
      instance_id: server_id,
      name: name,
      region: %{country: country, site: site_slug},
      plan: %{id: plan_id, slug: plan_slug},
      specs: %{
        machine_type: machine_type,
        ip_address: ip_address,
        os_type: os_type,
        accelerators: gpu_specs
      },
      billing_type: if(is_hourly, do: :on_demand, else: :spot),
      status: parse_status(status)
    }
  end
  defp parse_server(server), do: api_format_error("/servers", server)

  defp parse_status(status) do
    case status do
      "on" -> :running
      "off" -> :stopped
      "deploying" -> :deploying
      "failed_deployment" -> :failed
      _ -> :unknown
    end
  end

  @doc """
  Lists information relating to a single exisiting server instance, identified by an integer ID.

  Response is of the form:
    ```{:ok, %{
       instance_id: ID (str),
       name: server hostname,
       region: %{country: country name, site: site slug},
       plan: %{id: plan id, slug: plan slug},
       specs: %{
         machine_type: "bare metal" or others (not tested),
         ip_address: ipv4 address,
         os_type: os name,
         accelerators: ?,
       },
       billing_type: :on_demand or :spot,
       status: :running, :stopped, :deploying, :failed or :unknown
     }}```
  or
    `{:error, reason}`

  Notes:

  API docs on listing servers are [here](https://docs.latitude.sh/reference/get-server).
  """
  def list_server(server_id) do
    case get_wrapper("/servers/#{server_id}") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        case server = read_server(Jason.decode!(body)) do
          {:error, reason} -> {:error, reason}
          _ -> {:ok, server}
        end
      other -> generic_errors(other)
    end
  end

  defp read_server(%{"data" => server}), do: parse_server(server)
  defp read_server(server), do: api_format_error("/servers/{server_id}", server)

  @doc """
  Attempts to make up to `limit` requests to the same endpoint `https://api.latitude.sh/endpoint`,
  until a 429 error is triggered, in which case the limit is returned.

  Response is in the form:
    `{:ok, %{triggered: bool, limit: int}}`
  or
    `{:error, reason}`
  """
  def test_rate_limit(endpoint, limit), do: repeat_query(endpoint, 0, limit)

  defp repeat_query(endpoint, n, max) when n < max do
    if rem(n, 10) == 0, do: Logger.info(%{n: n})
    case get_wrapper(endpoint) do
      {:ok, %Tesla.Env{status: 200}} -> repeat_query(n + 1, max)
      {:ok, %Tesla.Env{status: 429}} -> {:ok, %{triggered: true, rate_limit: n}}
      {:error, %Tesla.Env{status: 429}} -> {:ok, %{triggered: true, rate_limit: n}}
      other -> generic_errors(other)
    end
  end
  defp repeat_query(n, max) when n >= max, do: {:ok, %{triggered: false, rate_limit: n}}

  @doc """
  Returns a list of plan maps, with a list of corresponding sites. These are filtered to be
  available if given `true`, and unavailable if given `false`.

  Response is in the form:
    ```{:ok, [%{
      plan: plan-slug,
      regions: [%{
        sites: [1+ site-slugs],
        pricing: %{hourly: float, monthly: float, yearly: float}
      }]}```
  or
    `{:error, reason}`

    API docs on plans are [here](https://docs.latitude.sh/reference/get-plans).
  """
  def fetch_plans_by_availability(is_available?) do
    case get_wrapper("/plans") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        plans = parse_plans(is_available?, Jason.decode!(body))
        case Enum.find(plans, &(match?({:error, _}, &1))) do
          nil -> {:ok, plans}
          error -> error
        end
      other -> generic_errors(other)
    end
  end

  defp parse_plans(_is_available?, %{"data" => []}), do: []
  defp parse_plans(is_available?, %{"data" => plans}) do
    plans = parse_each_plan(is_available?, plans)
    case Enum.find(plans, &(match?({:error, _}, &1))) do
      nil -> Enum.filter(plans, &(&1[:regions] != []))
      error -> [error]
    end
  end
  defp parse_plans(_is_available?, plans), do: [api_format_error("/plans", plans)]

  defp parse_each_plan(is_available?, [%{"attributes" => plan} | plans]) do
    case format_plan(is_available?, plan) do
      {:error, reason} -> [{:error, reason}]
      {:ok, plan_data} -> [plan_data | parse_each_plan(is_available?, plans)]
    end
  end
  defp parse_each_plan(_is_available?, []), do: []
  defp parse_each_plan(_is_available?, plans), do: [api_format_error("/plans (individual)", plans)]

  defp format_plan(is_available?, %{"slug" => slug, "available_in" => regions}) do
    regions = regions_or_errs(is_available?, regions)
    case Enum.find(regions, &(match?({:error, _}, &1))) do
      nil -> {:ok, %{plan: slug, regions: Enum.filter(regions, &(&1[:sites] != []))}}
      error -> error
    end
  end
  defp format_plan(_is_available?, plan), do: api_format_error("/plans", plan)

  defp regions_or_errs(is_available?, [%{"pricing" => %{"USD" => _prices}, "sites" => []} | regions]) do
    regions_or_errs(is_available?, regions)
  end
  defp regions_or_errs(is_available?, [%{"pricing" => %{"USD" => prices}, "sites" => sites} | regions]) do
    prices = prices_or_errs(prices)
    sites = sites_or_errs(is_available?, sites)
    case Enum.find([prices | sites], &(match?({:error, _}, &1))) do
      nil -> [%{pricing: prices, sites: sites} | regions_or_errs(is_available?, regions)]
      error -> [error]
    end
  end
  defp regions_or_errs(_is_available?, []), do: []
  defp regions_or_errs(_is_available?, regions), do: [api_format_error("/plans (regions)", regions)]

  defp prices_or_errs(%{"hour" => hourly, "month" => monthly, "year" => yearly}) do
    %{hourly: hourly, monthly: monthly, yearly: yearly}
  end
  defp prices_or_errs(prices) when prices == %{}, do: %{}
  defp prices_or_errs(prices), do: api_format_error("/plans (prices)", prices)

  defp sites_or_errs(_is_available?, []), do: []
  defp sites_or_errs(is_available?, [%{"slug" => slug, "in_stock" => is_available?} | sites]) do
    [slug | sites_or_errs(is_available?, sites)]
  end
  defp sites_or_errs(is_available?, [%{"slug" => _slug, "in_stock" => _bad} | sites]) do
    sites_or_errs(is_available?, sites)
  end
  defp sites_or_errs(_is_available?, sites), do: [api_format_error("/plans (sites)", sites)]

  @doc """
  Returns a single plan-site combination which is available if given `true`,
  or unavailable if given `false`.

  Response is in the form:
    ```{:ok, %{
      plan: plan-slug,
      regions: [%{
        sites: [1+ site-slugs],
        pricing: %{hourly: float, monthly: float, yearly: float}
      }]
    }```
  or
    `{:error, reason}`

    Notes:
    - This function still lists all plans, so it is more about efficiency than anything.

    API docs on plans are [here](https://docs.latitude.sh/reference/get-plans).
  """
  def fetch_one_plan_by_availability(is_available?) do
    case fetch_plans_by_availability(is_available?) do
      {:ok, plans} ->
        plans = plans
        |> Enum.filter(&(&1[:site] != []))
        [%{plan: plan, regions: [%{sites: [site | _], pricing: pricing} | _]} | _] = plans
        {:ok, %{plan: plan, site: site, pricing: pricing}}
      handled_error -> handled_error
    end
  end

  @doc """
  Fetches a list of projects the user's account is part of.

  Response is of the form:
    `{:ok, [%{id: project-id, name: project-name}]}`
  or
    `{:error, reason}`

  Notes:

  API docs on projects are [here](https://docs.latitude.sh/reference/get-projects).
  """
  def fetch_projects do
    case get_wrapper("/projects") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        projects = parse_projects(Jason.decode!(body))
        case error_if_any = List.last(projects) do
          {:error, _} -> error_if_any
          _ -> {:ok, projects}
        end
      other -> generic_errors(other)
    end
  end

  defp parse_projects(%{"data" => [project | projects]}) do
    case formatted_project = format_project(project) do
      {:error, reason} -> {:error, reason}
      _ -> [formatted_project | parse_projects(%{"data" => projects})]
    end
  end
  defp parse_projects(%{"data" => []}), do: []

  defp format_project(%{"id" => id, "attributes" => %{"name" => name}}), do: %{id: id, name: name}
  defp format_project(project), do: api_format_error("/projects", project)

  @doc """
  Attempts to create a new server instance - blocks until success or timeout.
  `plan` and `site` are slugs, as given by the plan-fetching functions; `project_id` must be the
  string of an ID as given by `fetch_projects/0`; and `server_name` is an arbitrary string.
  Create an unavailable server fails.

  Response is of the form:
    `{:ok, %{request_id: request_id, message: deployed message}`
  or
    `{:error, reason}`

  Notes:
  - HTTP code 422 can be triggered by giving any empty parameters or when the server is unavailable.
  - The server will be run on success.

  API docs on server creation are [here](https://docs.latitude.sh/reference/create-server).
  """
  def create_server(project_id, server_name, plan, site) do
    specs = %{data: %{
      type: "servers",
      attributes: %{
        operating_system: "ubuntu_22_04_x64_lts",
        hostname: server_name,
        project: project_id,
        plan: plan,
        site: site
      }
    }}
    case post_wrapper("/servers", specs) do
      {:ok, %Tesla.Env{status: 201, body: body}} -> parse_create_201_response(Jason.decode!(body))
      {:ok, %Tesla.Env{status: 400, body: body}} -> parse_create_400_response(body)
      {:ok, %Tesla.Env{status: 422, body: body}} -> parse_create_422_response(body)
      other -> generic_errors(other)
    end
  end

  defp parse_create_201_response(%{"data" => %{"id" => server_id, "attributes" => %{"status" => response}}}) do
    case wait_for_creation(server_id) do
      {:ok, :success} -> {:ok, %{request_id: server_id, message: response}}
      {:error, reason} -> {:error, reason}
    end
  end
  defp parse_create_201_response(response), do: api_format_error("/servers (creation success)", response)

  defp wait_for_creation(server_id) do
    :timer.sleep(@server_creation_delay)
    case list_server(server_id) do
      {:ok, _} -> {:ok, :success}
      {:error, @generic_msg_404} -> {:error, "Provisioning failure: server was not created"}
      handled_error -> handled_error
    end
  end

  defp parse_create_400_response(%{"errors" => [%{"detail" => error} | _errors]}) do
    {:error, "Bad Request [400] -- " <> error <> " from request body"}
  end
  defp parse_create_400_response(errors), do: api_format_error("/servers (creation 400-status)", errors)

  defp parse_create_422_response(%{"errors" => [%{"detail" => error} | _errors]}) do
    case error do
      "We do not have servers in stock for this plan" ->
        {:error, "Validation Error [422] -- This plan-site combination is unavailable."}
      "must be filled" ->
        {:error, "Validation Error [422] -- No empty parameters allowed."}
      error ->
        {:error, "Validation Error [422] -- " <> error}
    end
  end
  defp parse_create_422_response(errors), do: api_format_error("/servers (creation 422-status)", errors)

  @doc """
  Starts a stopped server instance, and blocks until success or timeout.
  An error state is returned if the server is already running.

  Response is of the form:
    `{:ok, %{request_id: action-id, message: started message}`
  or
    `{:error, reason}`

  API docs on starting servers is [here](https://docs.latitude.sh/reference/create-server-action).
  """
  def start_server(server_id) do
    start_request = %{data: %{
      type: "actions",
      attributes: %{action: "power_on"}
    }}
    case post_wrapper("/servers/#{server_id}/actions", start_request) do
      {:ok, %Tesla.Env{status: 201, body: body}} ->
        case is_integer(server_id) do
          true -> parse_startup_201_response(Integer.to_string(server_id), Jason.decode!(body))
          false -> parse_startup_201_response(server_id, Jason.decode!(body))
        end
      {:ok, %Tesla.Env{status: 406}} -> {:error, "Not Acceptable [406] -- Device is already on."}
      other -> generic_errors(other)
    end
  end

  defp parse_startup_201_response(server_id, %{"data" => %{"id" => request_id, "attributes" => %{"status" => response}}}) do
    Logger.info(%{message: response})
    :timer.sleep(@initial_server_action_delay)
    case wait_for_startup(server_id, 0) do
      {:ok, :success} -> {:ok, %{request_id: request_id, message: "Started server " <> server_id}}
      {:error, reason} -> {:error, reason}
    end
  end
  defp parse_startup_201_response(_server_id, response), do: api_format_error("/servers/{server_id}/actions (start) success", response)

  defp wait_for_startup(server_id, no_attempts) when no_attempts < 5 do
    :timer.sleep(@recurring_server_action_delay)
    case list_server(server_id) do
      {:ok, %{status: :running}} -> {:ok, :success}
      {:ok, %{status: _}} -> wait_for_startup(server_id, no_attempts + 1)
      handled_error -> handled_error
    end
  end
  defp wait_for_startup(_server_id, no_attempts) when no_attempts >= 5, do: {:error, "Server has not started up yet."}

  @doc """
  Stops a running server instance. Returns an error if the server is already stopped.

  Response is of the form:
    `{:ok, %{request_id: action-id, message: stopping status message}`
  or
    `{:error, reason}`

  API docs on stopping servers are [here](https://docs.latitude.sh/reference/create-server-action).
  """
  def stop_server(server_id) do
    stop_request = %{data: %{
      type: "actions",
      attributes: %{action: "power_off"}
    }}
    case post_wrapper("/servers/#{server_id}/actions", stop_request) do
      {:ok, %Tesla.Env{status: 201, body: body}} ->
        case is_integer(server_id) do
          true -> parse_stop_201_response(Integer.to_string(server_id), Jason.decode!(body))
          false -> parse_stop_201_response(server_id, Jason.decode!(body))
        end
      {:ok, %Tesla.Env{status: 406}} -> {:error, "Not Acceptable [406] -- Device is already off."}
      other -> generic_errors(other)
    end
  end

  defp parse_stop_201_response(server_id, %{"data" => %{"id" => request_id, "attributes" => %{"status" => response}}}) do
    Logger.info(%{message: response})
    :timer.sleep(@initial_server_action_delay)
    case wait_for_stop(server_id, 0) do
      {:ok, :success} -> {:ok, %{request_id: request_id, message: "Stopped server " <> server_id}}
      {:error, reason} -> {:error, reason}
    end
  end
  defp parse_stop_201_response(_server_id, response), do: api_format_error("/servers/{server_id}/actions (stop) success", response)

  defp wait_for_stop(server_id, no_attempts) when no_attempts < 5 do
    :timer.sleep(@recurring_server_action_delay)
    case list_server(server_id) do
      {:ok, %{status: :stopped}} -> {:ok, :success}
      {:ok, %{status: _}} -> wait_for_stop(server_id, no_attempts + 1)
      handled_error -> handled_error
    end
  end
  defp wait_for_stop(_server_id, no_attempts) when no_attempts >= 5, do: {:error, "Server has not stopped yet."}

  @doc """
  Deletes a server instance, running or not. Returns an error if the server is already deleted.

  Response is of the form:
    `{:ok, %{request_id: nil, message: success-message}}`
  or
    `{:error, reason}`

  Notes:
  - Successful responses have no request ID.

  API docs on deleting servers are [here](https://docs.latitude.sh/reference/destroy-server).
  """
  def delete_server(server_id) do
    case delete_wrapper("/servers/#{server_id}") do
      {:ok, %Tesla.Env{status: 200}} -> {:ok, %{request_id: nil, message: "Deleted successfully."}}
      other -> generic_errors(other)
    end
  end

  @doc """
  Fetches pricing information associated with a server instance.

  Response is of the form:
    `{:ok, {hourly: hourly-rate, monthly: monthly-rate, yearly: yearly-rate}`
  or
    `{:error, reason}`

  Notes:
  - The hourly rate is on-demand, while monthly and yearly rates are in reserve.

  API docs on pricing are [here](https://docs.latitude.sh/reference/get-plan).
  """
  def fetch_pricing_info(server_id) do
    case list_server(server_id) do
      {:ok, server} ->
        %{plan: %{id: plan_id, slug: plan}, region: %{site: site}} = server
        pricing_info(plan_id, plan, site)
      handled_error -> handled_error
    end
  end

  defp pricing_info(plan_id, plan, site) do
    case get_wrapper("plans/#{plan_id}") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        pricing_options = body
        |> Jason.decode!
        |> get_plan_regions
        |> Enum.map(&(%{
          pricing: case get_region_price_or_errs(&1) do
            {:ok, prices} -> prices
            {:error, reason} -> {:error, reason}
          end,
          sites: case get_region_sites_or_errs(&1) do
            {:ok, sites} -> sites
            {:error, reason} -> {:error, reason}
          end
        }))
        case pricing_options
        |> Enum.map(&(&1[:sites]))
        |> Enum.find(&match?({:error, _}, &1)) do
          nil -> pricing_out(pricing_options, plan, site)
          error -> error
        end
      other -> generic_errors(other)
    end
  end

  defp pricing_out(pricing_options, plan, site) do
    case pricing_options
    |> Enum.filter(&(site in &1[:sites]))
    |> Enum.map(&(&1[:pricing])) do
      [] -> get_cached_price(plan, site)
      [pricing] -> cache_price(pricing, plan, site)
    end
  end

  defp get_plan_regions(%{"data" => %{"attributes" => %{"available_in" => regions}}}), do: regions
  defp get_plan_regions(plan), do: api_format_error("/plans/{plan_id}", plan)

  defp get_region_price_or_errs(%{"pricing" => %{"USD" => %{"hour" => hour, "month" => month, "year" => year}}}) do
    {:ok, %{hourly: hour, monthly: month, yearly: year}}
  end
  defp get_region_price_or_errs(%{"pricing" => %{"USD" => price}}) when price == %{}, do: {:ok, %{}}
  defp get_region_price_or_errs(region), do: api_format_error("/plans/{plan_id} (region)", region)

  defp get_region_sites_or_errs(%{"sites" => sites}) do
    sites = get_sites(sites)
    case Enum.find(sites, &(match?({:error, _}, &1))) do
      nil -> {:ok, sites}
      error -> error
    end
  end
  defp get_region_sites_or_errs(region), do: api_format_error("/plans/{plan_id} (regions)", region)

  defp get_sites([%{"slug" => site} | sites]), do: [site | get_sites(sites)]
  defp get_sites([]), do: []
  defp get_sites(sites), do: [api_format_error("/plans/{plan_id} (region sites)", sites)]

  defp cache_price(pricing, plan, site) do
    endfile = "json/" <> plan <> "_" <> site <> ".json"
    case File.write(endfile, Jason.encode!(pricing)) do
      {:error, reason} ->
        Logger.debug({:error, %{message: "Could not cache price", reason: reason}})
        {:ok, pricing}
      :ok -> {:ok, pricing}
    end
  end

  @doc """
  Returns the cached price for a plan-site combination, or an empty response if it does not exist.

  Response is in the form:
    `{:ok, %{hourly: hourly-rate, monthly: monthly-rate, yearly: yearly-rate}}`
  or
    `{:error, reason}`
  """
  def get_cached_price(plan, site) do
    endfile = "json/" <> plan <> "_" <> site <> ".json"
    case File.read(endfile) do
      {:error, :enoent} -> {:ok, %{}}
      {:error, reason} -> {:error, reason}
      {:ok, contents} -> {:ok, Jason.decode!(contents, keys: :atoms)}
    end
  end

  @doc """
  A function that retrieves event logs and then filters by 'server_id'. Page size and page number have been
  assigned default values of 1000 and 1 respectively in the function head.

  Response is of the form:
    ```{:ok, %{
              event_id: <string>,
              request_id: nil,
              event_time: <string>,
              event_severity: nil.
              target_id: <integer>,
              location: nil,
              user_id: <string>,
              event_type: <string>,
              error_msg: nil
            }
      }```
  or
    `{:error, reason}`

  Notes:
  - Event logs contain no information for request_id, event_severity, location or error_msg
  - user_id info retreived from an author field that also includes email address and name info.
  - start_server and stop_server actions are not distinguished and just assigned the type 'create.actions'
  - Responses from the API are paginated, API utilizes Offset Pagination, page size and number can be specified in the query. API defaults to a page size of 20 and page number 1
  - Other object type ID's can be targetted such as team ID or project ID.
  - Calling fetch_audit_log/0 will return possbile event log target_id's

  API docs:
  - https://docs.latitude.sh/reference/get-events
  - https://docs.latitude.sh/reference/pagination
  """
  def fetch_audit_log(server_id, page_size \\ 20, page_number \\ 1)
  def fetch_audit_log(server_id, page_size, page_number) when is_bitstring(server_id), do: fetch_audit_log(String.to_integer(server_id), page_size, page_number)
  def fetch_audit_log(server_id, page_size, page_number) do
    query_params = ['page[size]': page_size, 'page[number]': page_number]
    case get_wrapper("/events", query_params) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        target_events = Jason.decode!(body)
          |> Map.get("data")
          |> Enum.map(&format_event/1)
          |> Enum.filter(fn %{target_id: target_id} -> target_id == server_id end)
        {:ok, target_events}
      other ->
        generic_errors(other)
    end
  end

  @doc"""
  A function that fetches all possible target ID's that can be used to retreive logs with fetch_audit_log/1

  Response is of the form:
    `{:ok, [id1, id2, ..., idn]}`
  Or
    `{:error, reason}`
  """
  def fetch_target_ids_for_events(page_size \\ 20, page_number \\ 1)
  def fetch_target_ids_for_events(page_size, page_number) do
    query_params = ['page[size]': page_size, 'page[number]': page_number]
    case get_wrapper("/events", query_params) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        target_ids = Jason.decode!(body)
          |> Map.get("data")
          |> Enum.group_by(fn event -> event["attributes"]["target"]["id"] end)
          |> Map.keys()
        {:ok, target_ids}
      other ->
        generic_errors(other)
    end
  end

  # Helper functions for fetch_audit_log/1.
  # Note that the atoms used as the secondary argument for these functions represent the keys in the provided event data where applicable.
  defp format_event(%{"id" => id, "attributes" => attributes}) do
    %{
      event_id: id,
      request_id: parse_attributes(attributes, :request_id), # No corresponding event property.
      event_time: parse_attributes(attributes, :created_at),
      event_severity: parse_attributes(attributes, :event_severity), # No corresponding event property.
      target_id: parse_attributes(attributes, :target_id),
      location: parse_attributes(attributes, :location), # No corresponding event property,
      user_id: parse_attributes(attributes, :user_id), # author also includes a name and email field.
      event_type: parse_attributes(attributes, :action),
      error_msg: parse_attributes(attributes, :error_message) # No corresponding event property.
    }
  end
  #Ensure that errors are logged if api returns data in unexpected format. May cause issues as this is called for every event pulled.
  defp format_event(body), do: api_format_error("/events (event log)", body)

  defp parse_attributes(%{"created_at" => created_at}, key) when key == :created_at, do: created_at
  defp parse_attributes(%{"action" => action}, key) when key == :action, do: action
  defp parse_attributes(%{"target" => target}, key) when key == :target_id do
    parse_target(target, :id)
  end
  defp parse_attributes(%{"author" => author}, key) when key == :user_id do
    parse_author(author, :id)
  end
  defp parse_attributes(_, _), do: nil
  defp parse_target(%{"id" => id}, _key), do: id
  defp parse_target(_, _), do: nil
  defp parse_author(%{"id" => id}, _key), do: id
  defp parse_author(_, _), do: nil

  def fetch_regions do
    case get_wrapper("/regions") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        data = Jason.decode!(body)["data"]
        #IO.puts(length(data))
        data
      other ->
        generic_errors(other)
    end
  end
end
