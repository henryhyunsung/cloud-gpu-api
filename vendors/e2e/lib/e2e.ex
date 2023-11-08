defmodule E2E do
  @moduledoc """
  This module provides functions for performing API operations on E2E cloud.

  It includes functions as follows:
  - create/delete node
  - start/stop node
  - get node (by id/list)
  - get pricing
  - get audit log
  """

  import  E2E.API

  @generic_msg_400 "Bad Request [400] -- General client error, possible malformed data."
  @generic_msg_401 "Unauthorized [401] -- The Authorization token was Invalid."
  @generic_msg_404 "Not Found [404] -- The API key was invalid"
  @generic_msg_429 "Too Many Requests [429] -- The client has reached or exceeded a rate limit, or the server is overloaded."
  @generic_msg_500 "Server Error [500] - Something went wrong on our end."
  @generic_msg_unknown "An unknown error occurred."

  # details for blocking purposes
  @server_action_delay 1000
  @max_action_attempts 50

  # Handlers for errors in Tesla
  defp generic_errors({:ok, %Tesla.Env{status: status, body: body}}) do
    case body["errors"] do
    # if description of error does not exist use generic message
      nil ->
        case status do
          400 -> {:error, @generic_msg_400}
          401 -> {:error, @generic_msg_401}
          404 -> {:error, @generic_msg_404}
          429 -> {:error, @generic_msg_429}
          500 -> {:error, @generic_msg_500}
          other -> {:error, "[#{other}] #{@generic_msg_unknown}"}
        end
      value ->
        {:error, "[#{status}] #{body["message"]}: #{get_message(value)}"}
    end
  end
  defp generic_errors({status, body}), do: {:error, %{status: status, body: body}}


  defp get_message(message) when is_binary(message) do message end
  defp get_message(message) do inspect(message) end
  @doc """
  Create a new node/instance.

  :param name - node name.
  :param plan - node plan.
  :param image - node image.

  THis function makes an HTTP POST request to create a new node/instance
  using the E2E API.
  """
  def create_node(name, plan, image, region \\ "ncr") do
    method = "POST"
    endpoint = "nodes/?"
    payload = %{
      name: "#{name}",
      region: "#{region}",
      plan: "#{plan}",
      image: "#{image}",
      ssh_keys: []
    }

    case perform_request(method, endpoint, payload) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        case wait_for_action(body["data"]["id"], 0, "Creating") do
          {:ok, :success} -> {:ok, body["data"]}
          {:error, reason} -> {:error, reason}
        end
      other -> generic_errors(other)
    end
  end

  @doc """
  Delete node by ID.

  :param ID - node ID.

  This function makes an HTTP DELETE request to delete the node specified by
  its unique ID using the E2E API.
  """
  def delete_node(id) do
    method = "DELETE"
    endpoint = "nodes/#{id}/?"

    case perform_request(method, endpoint) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body["data"]}
      other -> generic_errors(other)
    end
  end

  @doc """
  Start node by ID.

  :param id - node ID.

  This function makes an HTTP POST request to the endpoint to start the node
  specified by its unique ID using the E2E API.
  """
  def start_node(id) do
    method = "POST"
    endpoint = "nodes/#{id}/actions/?"
    payload = %{type: "power_on"}

    case perform_request(method, endpoint, payload) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        case wait_for_action(id, 0, "Running") do
          {:ok, :success} -> {:ok, body["data"]}
          {:error, reason} -> {:error, reason}
        end
      other -> generic_errors(other)
    end
  end

  @doc """
  Stop node by ID.

  :param id - node ID.

  This function makes an HTTP POST request to the endpoint to stop the node
  specified by its unique ID using the E2E API.
  """
  def stop_node(id) do
    method = "POST"
    endpoint = "nodes/#{id}/actions/?"
    payload = %{type: "power_off"}

    case perform_request(method, endpoint, payload) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        case wait_for_action(body["data"]["id"], 0, "Powered off") do
          {:ok, :success} -> {:ok, body["data"]}
          {:error, reason} -> {:error, reason}
        end
      other -> generic_errors(other)
    end
  end

  @doc """
  Stop node by ID.

  This function makes an HTTP get request to the endpoint to get the list of instances using the E2E API.
  """
  def get_node_list() do
    starting_page_no = 1
    node_ids = get_next_list([], starting_page_no)

    case node_ids do
      {:ok, ids} ->
        node_resps = ids
        |> Enum.map(fn id -> get_node_by_id(id) end)

        status_list = node_resps |> Enum.map(fn x -> elem(x, 0) end)
        resp_list   = node_resps |> Enum.map(fn x -> elem(x, 1) end)

        # If we had any errors in any of the requests, return an error resp.
        if Enum.any?(status_list |> Enum.map(fn s -> s == :error end)) do
          {:error, "Unknown error in listing"}
        else
          {:ok, resp_list}
        end
      other -> generic_errors(other)
      end
  end

  # Get the next pagination sest of nodes
  defp get_next_list(current_ids, page_no) do
    method = "GET"
    endpoint = "nodes/?"

    per_page = 20

    pagination_details = "&page_no=#{page_no}&per_page=#{per_page}"

    response = case perform_request(method, endpoint, nil, pagination_details) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body["data"]}
      other -> generic_errors(other)
      end

      case response do
      {:ok, []} ->
        {:ok, current_ids}

      {:ok, nodes} ->

        new_ids = Enum.map(nodes, fn x -> x["id"] end)
        updated_ids = current_ids ++ new_ids
        get_next_list(updated_ids, page_no + 1)
      other -> generic_errors(other)
    end

  end

  @doc """
  Get node by id.

  :param id - node ID.

  This function makes an HTTP GET request to retrieve the node specified by
  its unique ID using the E2E API.
  """
  def get_node_by_id(id) do
    method = "GET"
    endpoint = "nodes/#{id}/?"

    case perform_request(method, endpoint) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, %{
          instance_id: body["data"]["id"],
          vm_id: body["data"]["vm_id"],
          name: body["data"]["name"],
          plan: body["data"]["plan"],
          image: body["data"]["os_info"]["full_name"],
          description: nil,
          os: body["data"]["os_info"]["name"],
          public_ip: body["data"]["public_ip_address"],
          private_ip: body["data"]["private_ip_address"],
          price: body["data"]["price"],
          status: body["data"]["status"]
        }}
      other -> generic_errors(other)
    end
  end

  @doc """
  Get pricing by node.

  :param id - node ID.

  This function makes an HTTP GET request to retrieve the node specified by its
  unique ID. The price attribute is retrieved as the price per hour, and is
  used to calculate the total price.

  total elapsed time = current time - time created
  total price = price per hour * total elapsed time
  """
  def get_pricing(id) do

    method = "GET"
    endpoint = "nodes/#{id}/?"

    case perform_request(method, endpoint) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {_, created_at, _} = DateTime.from_iso8601(body["data"]["created_at"])
        cur_time = DateTime.utc_now()
        time_diff = DateTime.diff(cur_time, created_at, :minute)
        rounded_up_hours = :math.ceil(time_diff / 60)

        price = Regex.scan(~r/USD ([0-9.]+)/, body["data"]["price"])
        [_, price_per_hour] = hd(price)
        total_price = :erlang.float_to_binary(rounded_up_hours * String.to_float(price_per_hour), decimals: 3)

        {:ok, %{
          body["data"]["id"] => %{
            net_cost_on_demand: total_price,
            net_cost_spot: price_per_hour
          }
        }}
      other -> generic_errors(other)
      end
  end

  @doc """
  Get audit log by node.

  :param name - node name.

  THis function makes an HTTP GET request to retrieve the complete audit log
  filtered by node. The response returns CSV text, which is processed to return
  a maximum of 50 entries about the given instance, starting from the most
  recent.
  """

  def get_audit_log(name) do
    method = "GET"
    endpoint = "audit-log/action-download/?year=2023&month=8&service_type=NODE&per_page=50&page_no=1&filter_type=filter_month&contact_person_id=null&"
    case perform_request(method, endpoint) do
      {:ok, %Tesla.Env{status: 200, body: csv_data}} ->
        entries = parse_csv(name, csv_data)
        case entries do
          [] -> {:error, "no entries found"}
          _ -> {:ok, entries}
        end
      other -> generic_errors(other)
    end
  end



  #This function filters the audit log CSV data by name and reformats the data structure to a map.
  defp parse_csv(name, csv_data) do
    csv_lines =
      csv_data
      |> String.split("\r\n")

    entries =
      for line <- csv_lines,
        String.contains?(line, name),
        [resource_name | _rest] = String.split(line, ","),
        resource_name == name do
          [resource_name, _service, event, timestamp, client_ip, _performer, _details, location] = String.split(line, ",")
          %{
            name: resource_name,
            time: timestamp,
            region: location,
            event: event,
            ip: client_ip
          }
        end
        |> Enum.take(50)
    entries
  end


  @doc """
  Get audit log by node id.

  :param id - node id.

  This function makes an HTTP GET request to retrieve the nodes vm_id which it then
  uses to get to the endpoint that stores all of the nodes audit logs.
  """
  def get_audit_log_id(id) do

    case get_node_by_id(id) do
      {:ok, data} ->
        method = "GET"

        endpoint = "nodes/nodeactionlog/#{data[:vm_id]}?"

        case perform_request(method, endpoint) do
        {:ok, %Tesla.Env{status: 200, body: body}} ->
          {:ok, Enum.map(
            body["data"], fn action -> %{
            event: action["event"],
            time: action["timestamp"],
            details: action["details"],
            ip: action["client_ip"]
            }
          end)}
        _ ->
          {:error, "failed to get customer details"}
        end
      other -> generic_errors(other)
    end
  end


  @doc """
  Get customer details


  This function returns the customer id for a given api key
  """
  def get_customer_details() do
    method = "GET"
    endpoint = "customer/details/?"

    case perform_request(method, endpoint) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, %{
          customerID: body["data"]["e2e_customer_id"]
        }}
      other -> generic_errors(other)
    end
  end

  @doc """
  Get user ids


  This function returns all the users corresponding to an E2E account
  """
  def get_user_ids() do
    method = "GET"
    endpoint = "all-contact-person-details/?"

    case perform_request(method, endpoint) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, Enum.map(
          body["data"]["contacts"], fn users -> %{
            first_name: users["first_name"],
            last_name: users["last_name"],
            userID: users["contact_person_id"],
            email: users["email"]
          }
        end)}
      other -> generic_errors(other)
    end
  end

  @doc """
  Get tags


  This function returns all the tags that can be used to group instances together
  """
  def get_tags() do
    method = "GET"
    endpoint = "label/?"

    case perform_request(method, endpoint) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, Enum.map(
          (body)["data"], fn tag -> %{
            id: tag["id"],
            name: tag["label_name"],
            description: tag["metadata"]
          }
        end)}
      other -> generic_errors(other)
    end
  end

  @doc """
  Get groups


  This function returns all the groups that can be used to group instances together
  """
  def get_groups() do
    method = "GET"
    endpoint = "nodes/label-list/?"

    case perform_request(method, endpoint) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, %{
          groups: body["data"]["label_list"]
        }}
      other -> generic_errors(other)
    end
  end

  @doc """
  set user id


  This function sets the user id such that all future actions will be attributed to the user
  """
  def set_user(name) do
    case get_user_ids() do
      {:ok, data} ->

        result = Enum.find(data, fn(dict) ->
          "#{Map.get(dict, :first_name)} #{Map.get(dict, :last_name)}" == name
        end)

        case result do
          nil ->
            {:error, "User with that name does not exist"}
          dict ->
            System.put_env("E2E_USER_IDENTIFIER", dict[:userID])
            {:ok, "Events linked to #{name} corresponding to email #{dict[:email]}"}
      end
      other -> generic_errors(other)
    end
  end

  defp wait_for_action(instance_id, no_attempts, target_status) when no_attempts < @max_action_attempts do
    :timer.sleep(@server_action_delay)
    case get_node_by_id(instance_id) do
      {:ok, %{status: ^target_status}} -> {:ok, :success}
      {:ok, %{status: _}} -> IO.puts "Waiting for instance to be in #{target_status} state Attempt #{no_attempts+1}/#{@max_action_attempts}";  wait_for_action(instance_id, no_attempts + 1, target_status)
      handled_error -> handled_error
    end
  end
  defp wait_for_action(_instance_id_id, no_attempts, target_status) when no_attempts >= @max_action_attempts, do: {:error, "Timeout: Instance action #{target_status} was received but has not been completed."}

end
