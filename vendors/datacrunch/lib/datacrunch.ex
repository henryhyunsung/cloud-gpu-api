defmodule Datacrunch do
  @moduledoc """
  This is a module designed to interact with the Datacrunch API.
  It is currently run in the terminal (using `iex -S mix`).

  The module requires that the DATACRUNCH_ID and DATACRUNCH_SECRET System environment variables is set to the
  users' API key before running; otherwise any method call will result in a 401 return code.

  Each method interacting with the API has some expected return codes that can be found on the
  API page, most often in [this list](https://datacrunch.stoplight.io/docs/datacrunch-public/ZG9jOjM1ODcxNjI-errors).

  To see documentation for each function, run `mix docs` and open `doc/datacrunch.html` in your browser.
  """
  import Datacrunch.ApiWrapper
  require Logger

  @generic_msg_400 "Bad Request [400] -- One or more of the inputs were invalid."
  @generic_msg_401 "Unauthorized [401] -- Access token is missing or invalid."
  @generic_msg_403 "Forbidden [403] -- The action is forbidden."
  @generic_msg_404 "Not Found [404] -- The instance was not found."
  @generic_msg_500 "Not Found [500] -- Error on datacrunch's side."
  @generic_msg_503 "Not Found [503] -- Not enough resources at the moment. try again later."

  # details for blocking purposes
  @server_action_delay 1000
  @max_action_attempts 50

  defp generic_errors({:ok, %Tesla.Env{status: status, body: body}}) do
    case status do
      400 -> {:error, "#{@generic_msg_400} -> Code: #{body["code"]} Message: #{body["message"]}"}
      401 -> {:error, "#{@generic_msg_401} -> Code: #{body["code"]} Message: #{body["message"]}"}
      403 -> {:error, "#{@generic_msg_403} -> Code: #{body["code"]} Message: #{body["message"]}"}
      404 -> {:error, "#{@generic_msg_404} -> Code: #{body["code"]} Message: #{body["message"]}"}
      500 -> {:error, "#{@generic_msg_500} -> Code: #{body["code"]} Message: #{body["message"]}"}
      503 -> {:error, "#{@generic_msg_503} -> Code: #{body["code"]} Message: #{body["message"]}"}
      _ -> {:error, "Unkown error status #{status}  -> Code: #{body["code"]} Message: #{body["message"]}"}
    end
  end
  defp generic_errors({status, body}), do: {:error, %{status: status, body: body}}

  defp api_format_error(endpoint, decoded_body) do
    Logger.debug(decoded_body)
    {:error, endpoint <> " response format has changed; see the full body in logs."}
  end


  @doc """
  Fetches information about the access token the user's account is accessing.

  Response is of the form:
    `{:ok, %{token: auth-token}}`
  or
    `{:error, reason}`

  API docs: [here](https://datacrunch.stoplight.io/docs/datacrunch-public/c0c4ae12d0d97-get-access-token)
  """
  def fetch_access_token do
    method = "POST"
    endpoint = "oauth2/token"

    payload = %{
      grant_type: "client_credentials",
      client_id: System.get_env("DATACRUNCH_ID"),
      client_secret: System.get_env("DATACRUNCH_SECRET")
    }

    case perform_request(method, endpoint, payload) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        access_token(body)
      other -> generic_errors(other)
    end
  end

  defp access_token(%{"access_token" => version}), do:  (System.put_env("DATACRUNCH_AUTHTOKEN", version); {:ok, %{token: version}})
  defp access_token(body), do: api_format_error("/auth/current_version", body)

  @doc """
  Starts an instance, an error state is returned if the action is unable to be performed

  Response is of the form:
    `{:ok, %{message: instance (instance_id) was successfully started}`
  or
    `{:error, reason}`

  API docs on starting instances is [here](https://datacrunch.stoplight.io/docs/datacrunch-public/016cf76f15565-perform-action-on-instance).
  """
  def start_instance(instance_id) do
    endpoint = "instances"
    payload = %{
      id: instance_id,
      action: "start"
    }

    case perform_request("PUT", endpoint, payload) do
      {:ok, %Tesla.Env{status: 202}} ->
        case wait_for_action(instance_id, 0, "running") do
          {:ok, :success} -> {:ok, %{message: "Started instance " <> instance_id}}
          {:error, reason} -> {:error, reason}
        end
      other -> generic_errors(other)
    end
  end

  @doc """
  Stops an instance, an error state is returned if the action is unable to be performed

  Response is of the form:
    `{:ok, %{messge: instance (instance_id) was successfully stopped}`
  or
    `{:error, reason}`

  API docs on starting instances is [here](https://datacrunch.stoplight.io/docs/datacrunch-public/016cf76f15565-perform-action-on-instance).
  """
  def stop_instance(instance_id) do
    endpoint = "instances"
    payload = %{
      id: instance_id,
      action: "shutdown"
    }

    case perform_request("PUT", endpoint, payload) do
      {:ok, %Tesla.Env{status: 202}} ->
        case wait_for_action(instance_id, 0, "offline") do
          {:ok, :success} -> {:ok, %{message: "Stopped instance " <> instance_id}}
          {:error, reason} -> {:error, reason}
        end
      other -> generic_errors(other)
    end
  end

  @doc """
  Deletes an instance, an error state is returned if the action is unable to be performed

  Response is of the form:
    `{:ok, %{message: instance (instance_id) was successfully deleted}`
  or
    `{:error, reason}`

  API docs on starting instances is [here](https://datacrunch.stoplight.io/docs/datacrunch-public/016cf76f15565-perform-action-on-instance).
  """
  def delete_instance(instance_id) do
    endpoint = "instances"
    payload = %{
      id: instance_id,
      action: "delete"
    }

    case perform_request("PUT", endpoint, payload) do
      {:ok, %Tesla.Env{status: 202}} ->
        {:ok, %{message: "Instance #{instance_id} was successfully deleted"}}
      other -> generic_errors(other)
    end
  end


  @doc """
  Lists information relating to a single exisiting instance, identified by an integer ID.

  Response is of the form:
    ```{:ok, %{
       instance_id: ID (str),
       name: instance hostname,
       description: short description of instance,
       created: time created in UTC
       gpu_specs: {description, number_of_gpus}
       gpu_memory: {description, size_in_GB}
       region: location code,
       image: operating system of instance
       instance_type: type of instance
       ip: ip_address
       is_spot: whether instance is spot or on_demand,
       price: price_per_hour
       status: Current status of instance
     }}```
  or
    `{:error, reason}`

  Notes:

  API docs on listing instances are [here](https://datacrunch.stoplight.io/docs/datacrunch-public/d3db047d0d076-get-instance-by-id).
  """
  def get_instance_by_id(instance_id) do
    endpoint = "instances/#{instance_id}"

    case perform_request("GET", endpoint) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, %{
          instance_id: body["id"],
          name: body["hostname"],
          description: body["description"],
          created: body["created_at"],
          gpu_specs: body["gpu"],
          gpu_memory: body["gpu_memory"],
          region: body["location"],
          image: body["image"],
          instance_type: body["instance_type"],
          ip: body["ip"],
          is_spot: body["is_spot"],
          price: body["price_per_hour"],
          status: body["status"]
        }}
      other -> generic_errors(other)
    end
  end


  @doc """
  Lists all the user's existing instances

  Response is of the form.
    ```{:ok, [%{
       instance_id: ID (str),
       name: instance hostname,
       description: short description of instance,
       created_at: time created in UTC
       gpu_specs: {description, number_of_gpus}
       gpu_memory: {description, size_in_GB}
       region: location code,
       image: operating system of instance
       instance_type: type of instance
       ip: ip_address
       is_spot: whether instance is spot or on_demand,
       price: price_per_hour
       status: Current status of instance
     }]}```
  or
    `{:error, reason}`

  Notes:

  API docs: [listing instances](https://datacrunch.stoplight.io/docs/datacrunch-public/db11bd3c5d656-get-all-instances)
  """
  def get_instance_list() do
    endpoint = "instances"

    case perform_request("GET", endpoint) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, Enum.map(body, fn instance -> %{
          instance_id: instance["id"],
          name: instance["hostname"],
          description: instance["description"],
          created: instance["created_at"],
          gpu_specs: instance["gpu"],
          gpu_memory: instance["gpu_memory"],
          region: instance["location"],
          image: instance["image"],
          instance_type: instance["instance_type"],
          ip: instance["ip"],
          is_spot: instance["is_spot"],
          price: instance["price_per_hour"],
          status: instance["status"]
        }
         end)}
      other -> generic_errors(other)
    end
  end

  @doc """
  Get pricing for instance

  :param id - node ID.

  This function makes an HTTP GET request to retrieve the node specified by its
  unique ID. The price attribute is retrieved as the price per hour, and is
  used to calculate the total price.

  total elapsed time = current time - time created
  total price = price per hour * total elapsed time

  Response is of the form:
    `{:ok, %{is_spot, price_per_hour, total_price}`
  or
    `{:error, reason}`

  """
  def get_pricing_information(instance_id) do
    case get_instance_by_id(instance_id) do
      {:ok, data} ->

          {_, created_at, _} = DateTime.from_iso8601(data[:created])
          cur_time = DateTime.utc_now()
          time_diff = DateTime.diff(cur_time, created_at, :minute)
          rounded_up_hours = :math.ceil(time_diff / 60)

          price_per_hour =  data[:price]
          total_price = rounded_up_hours * price_per_hour
          {:ok, %{
              is_spot: data[:is_spot],
              total_price: total_price,
              price_per_hour: price_per_hour
            }
          }
      other -> other
    end
  end


  @doc """
  Attempts to create a new  instance
  instance_type: is the inputted type of instance
  image: operating system running
  location_code: is location of the instance
  hostname: name of the instance- must contain alphanumeric values or dash only, and be shorter than 60
  Description: short description of the instances

  Response is of the form:
    `{:ok, %{request_id: request_id, message: deployed message}`
  or
    `{:error, reason}`

  Notes:
  - The instance will be run on success.

  API docs on instance creation are [here](https://datacrunch.stoplight.io/docs/datacrunch-public/d1a75ccb721a7-deploy-new-instance).
  """
  def create_instance(instance_type, image, location_code, hostname \\ "DefaultNode", description \\ "Default description") do
    endpoint = "instances"
    payload = %{
      instance_type: instance_type,
      image: image,
      ssh_key_ids: System.get_env("DATACRUNCH_SSHKEY"),
      hostname: hostname,
      description: description,
      location_code: location_code
    }


    case perform_request("POST", endpoint, payload) do
      {:ok, %Tesla.Env{status: 202, body: instance_id}} ->
        case wait_for_action(instance_id, 0, "running") do
          {:ok, :success} -> {:ok, %{instance_id: instance_id}}
          {:error, reason} -> {:error, reason}
        end
      {:ok, %Tesla.Env{status: 402}} -> {:error, "Not Acceptable [403] -- Invalid funds."}
      other ->  generic_errors(other)
    end
  end

  @doc """
  Iterates through each server and sorts them into spot and non spot instances
  Response is of the form:
    `{:ok, [%{spot: [spot_instances], on_demand: [on_demand instances] }]}`
  or
    `{:error, reason}`

  Notes:

  API docs on projects are [here](https://datacrunch.stoplight.io/docs/datacrunch-public/db11bd3c5d656-get-all-instances).
  """
  def get_groups() do
    case get_instance_list() do
      {:ok, data} ->
        spot_instances =
          data
          |> Enum.filter(fn x -> x[:is_spot] == true end)

        demand_instances =
            data
            |> Enum.filter(fn x -> x[:is_spot] == false end)

        {:ok, %{
          spot_instances: spot_instances,
          on_demand_instances: demand_instances
        }}
      other -> other
    end
  end

  defp wait_for_action(instance_id, no_attempts, target_status) when no_attempts < @max_action_attempts do
    :timer.sleep(@server_action_delay)
    case get_instance_by_id(instance_id) do
      {:ok, %{status: ^target_status}} -> {:ok, :success}
      {:ok, %{status: _}} -> IO.puts "Waiting for instance to be in #{target_status} state Attempt #{no_attempts+1}/#{@max_action_attempts}";  wait_for_action(instance_id, no_attempts + 1, target_status)
      handled_error -> handled_error
    end
  end
  defp wait_for_action(_instance_id_id, no_attempts, target_status) when no_attempts >= @max_action_attempts, do: {:error, "Timeout: Instance action #{target_status} was received but has not been completed."}



  @doc """
  Attempts to make up to `limit` requests to the same endpoint `"oauth2/token"`,
  until an error is triggered, in which case the limit is returned.

  Response is in the form:
    `{:ok, %{triggered: bool, limit: int}}`
  or
    `{:error, reason}`
  """
  def test_rate_limit(limit), do: repeat_query(0, limit)

  defp repeat_query(n, max) when n < max do
    if rem(n, 10) == 0, do: Logger.info(%{n: n})
    case fetch_access_token() do
      {:ok, _} -> repeat_query(n + 1, max)
      {:error, _} -> {:ok, %{triggered: true, rate_limit: n}}
      other -> generic_errors(other)
    end
  end
  defp repeat_query(n, max) when n >= max, do: {:ok, %{triggered: false, rate_limit: n}}

  @doc """
  Get all instance-types, an error state is returned if the action is unable to be performed

  Response is of the form:
    `{:ok, %{instances: [instances]}}
  or
    `{:error, reason}`

  API docs on starting instances is [here](https://datacrunch.stoplight.io/docs/datacrunch-public/1868c9661ab19-get-all-instance-types).
  """
  def get_instances_types() do
    endpoint = "instance-types"

    case perform_request("GET", endpoint) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, %{instances: body}}
      other -> generic_errors(other)
    end
  end

  @doc """
  Get all images, an error state is returned if the action is unable to be performed

  Response is of the form:
    `{:ok, %{images: [images]}}
  or
    `{:error, reason}`

  API docs on starting instances is [here](https://datacrunch.stoplight.io/docs/datacrunch-public/c46ab45dbc508-get-all-image-types).
  """
  def get_images() do
    endpoint = "images"

    case perform_request("GET", endpoint) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, %{images: body}}
      other -> generic_errors(other)
    end
  end

  @doc """
  get list of all instance-types that are available, an error state is returned if the action is unable to be performed

  Response is of the form if no instance_id:
    `{:ok, [%{availabilities: [instance-types], location_code: location}]}
    or
      {ok: %{availabilities: "true/false"} if instance_id is specified
  or
    `{:error, reason}`

  API docs on starting instances is [here](https://datacrunch.stoplight.io/docs/datacrunch-public/53f55567436d8-check-all-availability).
  """
  def check_availability(instance_type \\ "") do
    endpoint = "instance-availability/#{instance_type}"

    case perform_request("GET", endpoint) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, %{availabilities: body}}
      other -> generic_errors(other)
    end
  end

end
