defmodule Paperspace do
  @moduledoc """
  Documentation for `Paperspace`.
  """

  # NOTE: Paperspace API may completely redo their API in the next
  #  couple months.

  # NOTE: Projects not supported for Paperspace metal servers


  # TODO: Add documentation for each URL being used, link to docs if
  #  available.

  # Generic error messages if API responses don't return an error
  #  message, used in `decode_unsuccessful_response`
  # Possible errors and their descriptions can be found in the paperspace
  #  docs: https://docs-next.paperspace.com/web-api/overview
  @generic_msg_400 "PARSE_ERROR [400] -- The request was unacceptable, often due to missing a required parameter or incorrect method."
  @generic_msg_401 "UNAUTHORIZED [401] -- The API key was invalid or expired."
  @generic_msg_403 "FORBIDDEN [403] -- The API key doesn't have permissions to perform the request."
  @generic_msg_404 "NOT_FOUND [404] -- The requested resource doesn't exist."
  @generic_msg_405 "METHOD_NOT_SUPPORTED [405] -- The requested method is not supported for the requested resource."
  @generic_msg_408 "TIMEOUT [408] -- The request took too long."
  @generic_msg_409 "CONFLICT [409] -- The request conflicts with another request."
  @generic_msg_412 "PRECONDITION_FAILED [412] -- The client did not meet one of the request's requirements."
  @generic_msg_413 "PAYLOAD_TOO_LARGE [413] -- The request is larger than the server is willing or able to process."
  @generic_msg_429 "TOO_MANY_REQUESTS [429] -- Too many requests hit the API too quickly. We recommend an exponential backoff of your requests."
  @generic_msg_499 "CLIENT_CLOSED_REQUEST [499] -- The client closed the request before the server could respond."
  @generic_msg_500 "INTERNAL_SERVER_ERROR [500] - Something went wrong on Paperspace's end."


  ################################
  # Fetching account information #
  ################################

  @doc """
  Get the current session. If a user is not logged in, this will be
  null. Otherwise, it will contain the current team and user.

  RETURN:
    --- ON SUCCESS
    {:ok, %{user_id: id}}

    --- ON FAILURE
    `{:error, reason}

  API docs: https://docs-next.paperspace.com/web-api/authentication
  """
  def fetch_account_identifier(api_key) do
    # Make request for an auth session. Cannot use make_get function, as
    #  this request needs different formatted headers
    # NOTE: Is this .com, or .io?
    url = "https://api.paperspace.com/v1/auth/session"
    headers = [{"accept", "application/json"}, {"authorization", "Bearer #{api_key}"}]
    {tesla_status, r} = Tesla.get(url, headers: headers)

    # Attempt to decode the response
    {status, resp} = decode_response(tesla_status, r)

    # Parse the response and return
    parse_account_identifier_response(status, resp)
  end


  # Successful request with 200 code, but no actual response
  defp parse_account_identifier_response(:ok, nil) do
    {:error, "Invalid API key"}
  end

  # Successful request with actual response and keys present
  defp parse_account_identifier_response(:ok, %{"user" => user}) do
    # Verify presence of 'id' field
    parse_user_id(user)
  end

  # Successful request with actual response, but missing keys
  defp parse_account_identifier_response(:ok, _resp) do
    {:error, "Failed to get user ID: Field 'user' missing from response"}
  end

  # Unsuccessful request
  defp parse_account_identifier_response(:error, resp) do
    {:error, resp}
  end

  # ID found in user map
  defp parse_user_id(%{"id" => user_id}) do
    {:ok, %{user_id: user_id}}
  end

  # ID missing from user map
  defp parse_user_id(_user) do
    {:error, "Failed to get user ID: Field 'id' missing from map 'user'"}
  end



  ####################################
  # Create New Machine #
  ####################################

  @doc """
  Create a new machine. Paperspace requires a post request with the following attributes:
      region: "",
      machineType: "",
      diskSize: "",
      billingType: "",
      name: "",
      templateId: ""
  Other attributes such as teamId or networkId are optional.

  API DOCS: https://docs.paperspace.com/core/api-reference/machines.

  RETURN:
  --- ON SUCCESS
    {:ok, New machine '<name>' was created!}
  --- ON FAILURE
    `{:error, reason}
  """
  def create_machine(api_key, name) do
    # TODO: Pass in settings as function arguments
    payload = %{
      # Valid regions: West Coast (CA1), East Coast (NY2), Europe (AMS1)
      region: "East Coast (NY2)",

      # Valid machines: Air, Standard, Pro, Advanced, GPU+, P4000,
      #  P5000, P6000, V100, C1, ... , C10
      machineType: "C1",

      # Storage size in GB: 50 GB is the smallest option
      diskSize: 50,

      # Hourly is the standard option
      billingType: "hourly",

      # A name for the machine
      name: "#{name}",

      # Valid templates: tkni3aa4 (Ubuntu 20.04 server)
      #  https://docs.paperspace.com/core/api-reference/templates/
      templateId: "tkni3aa4"
    }

    # Construct header containing API key and data format
    headers = [
      {"accept", "application/json"},
      {"authorization", "Bearer #{api_key}"},
      {"content-type", "application/json"}]

    # Make post request with machine attributes, encoded as payload data
    url = "https://api.paperspace.com/v1/machines"
    {tesla_status, r} = Tesla.post(url, Jason.encode!(payload), headers: headers)

    # Attempt to decode the response and return
    {status, resp} = decode_response(tesla_status, r)

    # Check response from post method
    if status == :error do
      {:error, resp, "Machine creation aborted!"}
    else
      {:ok, "New machine '#{name}' was created!"}
    end
  end



  #########################################
  # Listing information about instance(s) #
  #########################################

  @doc """
  Lists all machines, with the maximum amount of information.

  The /getMachines endpoint is not used for this, as that endpoint
  returns limited information for each machine. Instead, the IDs of each
  existing machine are used to make requests to the /getMachine endpoint
  to fetch more extensive information about each machine.

  This method can be quite slow due to this fetching method, and could
  possibly be sped up via asyncronous calls to the private
  `_list_machine` function, but for a small scale prototype this is not
  necessary.

  If the information required for listing machines does not need to be
  as extensive as for a specific machine, this could also be sped up by
  just using the /getMachines endpoint.
  """
  @doc since: "2023-08-28"
  def list_machines(api_key) do
    # Fetch all the machine IDs for each existing instance
    {status, ids_resp} = fetch_existing_machine_ids(api_key)
    if status == :ok do
      # Using each machine ID, fetch the extensive details for each
      #  machine individually. Just listing machines normally does not
      #  give the same level of detail.
      machine_resps = ids_resp
        |> Enum.map(fn id -> list_machine(api_key, id) end)

      # Split the responses from list_machine into two lists: One for all
      #  the status codes, and one for all the responses.
      status_list = machine_resps |> Enum.map(fn x -> elem(x, 0) end)
      resp_list   = machine_resps |> Enum.map(fn x -> elem(x, 1) end)

      # If we had any errors in any of the requests, return an error resp.
      if Enum.any?(status_list |> Enum.map(fn s -> s == :error end)) do
        # TODO: Use index of the error to show specific error message?
        {:error, "Unknown error in listing"}

      # Otherwise, return the list of machines with an :ok status
      else
        {:ok, resp_list}
      end
    else
      {:error, ids_resp}
    end
  end


  @doc """
  Fetches all possible information about a single machine. Is also
  called by `list_machines` to give more info per machine.
  """
  @doc since: "2023-08-28"
  def list_machine(api_key, machine_id) do
    # Make request to /getMachine for the single machine
    {status, resp} = api_request_get(api_key,
      "/machines/getMachine",
      [{"publicMachineId", machine_id}])

    # If we got an error on the request, return :error and that message.
    #  Otherwise, parse response
    if status == :error do
      {:error, resp}
    else
      parse_machine_response(resp)
    end
  end


  # A helper function for `list_machines`. Will use the /getMachines
  #  endpoint to fetch all existing machines, and return the IDs for
  #  each machine.
  defp fetch_existing_machine_ids(api_key, machine_ids \\ [], skip \\ 0) do
    # Pagination is done in a bit of a strange way for Paperspace.
    #  Instead of having a "next" attribute in the response to form the
    #  next request for a page or etc, it's expected that you check how
    #  many items were in the response, and then `skip` that many for
    #  the next response. When a response gives no items, that'll be
    #  the last page.

    # Page size max is 1000. We might as well use the max size.
    page_size = 1000

    # Make a request to /getMachines with given pagination skip
    {status, resp} = api_request_get(api_key,
      "/machines/getMachines",
      [{"limit", page_size}, {"skip", skip}])

    # Extract machine IDs from each response
    {status, resp} = parse_machine_ids(status, resp)

    # If there was an error in parsing, return that error
    #   Otherwise, update the ID list and paginate
    if status == :ok do
      # Extend the current list of IDs
      updated_ids = machine_ids ++ resp

      # If there was less than a full page of machines, we just got the
      #  last page and can finish. Otherwise, we need to make another
      #  request for the next page.
      if length(resp) < page_size do
        # If less than page size, return all ids
        {:ok, updated_ids}
      else
        # Otherwise, make request for next page, extending current list
        fetch_existing_machine_ids(api_key, updated_ids, skip + page_size)
      end
    else
      {status, resp}
    end
  end

  # Extracts the IDs of each machine in the response
  defp parse_machine_ids(:ok, machines) do
    # For each resp, extract its ID or, failing that, an error
    ids = Enum.map(machines, &parse_machine_id(&1))
    # If there were any errors in ID extraction, return an error and message
    #   Otherwise, return :ok and the extracted ID list
    if Enum.any?(ids, &(&1 == :error)) do
      {:error, "Failed to get machine IDs: Field 'id' missing from one or more responses"}
    else
      {:ok, ids}
    end
  end
  # If the API request had an error, just propagate that
  defp parse_machine_ids(:error, resp), do: {:error, resp}

  # Extracts the ID of one machine
  defp parse_machine_id(%{"id" => id}), do: id
  defp parse_machine_id(_), do: :error


  # Formatter for machines returned by the /getMachine endpoint.
  # This version expects a full response from a machine that has not yet
  #  been deleted.
  defp parse_machine_response(%{
    "xenName" => id,
    "name" => name,
    "metal" => machine_map, # Used for region name
    "usageRate" => usage_map, # Used for machine kind/desc., and spot/on_demand
    "publicIp" => public_ip,
    "privateIp" => private_ip_map, # May be missing, see next func
    "gpus" => gpu_list, # Used for GPU details. Assumed only one type
    "state" => state,
    "isRemoved" => is_deactivated?, # Used to determine if suspended, or deleted
    "isPreemptible" => is_preemptible?
  }) do
    {
      :ok,
      %{
        # A unique identifier for the instance. Usually a UUID or similar
        instance_id: id,
        # NOTE: id can be a number (id), but also a string (xenName). The
        #  string is used for other requests such as for pricing.

        # The user-friendly name of the instance
        name: name,

        # The zone, region, or other location identifier that the instance
        #  exists in.
        zone: machine_map["datacenter"]["region"]["name"],

        # A user-friendly description of the instance. Based on the model
        #  chosen for machine. e.g. "GPU+ hourly"
        description: usage_map["description"],

        # The cloud provider's "machine type" identifier
        machine_type: usage_map["kind"],

        # [Optional] IP addresses allocated to the machine
        external_ip: public_ip,
        internal_ip: private_ip_map["ipaddress"],
        # NOTE: Vendor API Tasks document states this should be a list,
        #  but the example response is two optional strings.

        # [Optional] The OS type of the machine
        os_type: nil,
        # NOTE: Could be inferred by "agentType" attribute. Otherwise,
        #  "os" attribute is usually just set to "".

        # The provisioning type of the machine - usually something like
        #  "spot" or "reserved", but cloud specific. Should be either
        #  :spot or :on_demand
        billing_type:
          case usage_map["type"] do
            "hourly"  -> :on_demand # Can delete any time
            "monthly" -> :spot
            _         -> :unknown # Unknown, could not test for other cases
          end,

        # Whether the machine is preemptible. Usually means that the
        #  machine is a spot instance which may be shut down without
        #  warning.
        preemptible: is_preemptible?,

        # The number, type, and memory size of the GPUs connected to the
        #  machine.
        accelerator_count:
          if length(gpu_list) > 0 do
            # Need to iterate through the GPU list, summing "gpuCount" for
            #  each type.
            gpu_list
              |> Enum.reduce(0, fn g, acc -> acc + g["gpuCount"] end)
              |> to_string()
          else
            "0"
          end,
        accelerator_type:
          if length(gpu_list) > 0 do
            # Use the first type seen as the accelerator_type. No plans
            #  currently have support for mixing GPU types.
            hd(gpu_list)["gpuModel"]["label"]
          else
            nil
          end,
        accelerator_memory: # In Mb
          if length(gpu_list) > 0 do
            # Sum the memory in Mb
            gpu_list
              |> Enum.reduce(0, fn g, acc -> acc + g["gpuModel"]["memInMb"] end)
          else
            0
          end,
        # NOTE: Example response only has count/type. Added memory size as
        #  mentioned in text of Vendor API Tasks
        # NOTE: Memory is in Mb

        # Status of the machine. Should be one of :Running, :Starting,
        #  :Suspending, :Suspended, :Stopping, :Stopped, :Unknown
        status:
          if is_deactivated? do
            :Destroyed # Has been deleted, not accessible in any way
          else
            case state do
              "AgentReady"   -> :Running
              "StartingUp"   -> :Starting
              "ShuttingDown" -> :Stopping
              "Off"          -> :Stopped
              "Restarting"   -> :Starting # Restarting implies starting again
              _              -> :Unknown
              # NOTE: Paperspace doesn't seem to support suspending
            end
          end
      }
    }
  end


  # Formatter for machines returned by the /getMachine endpoint.
  # This version expects a full response excluding `privateIp`, which
  #  can be missing if a machine has been deleted.
  # Will set up the `privateIp` map to have `nil` `ipaddress`, and pass
  #  the response from /getMachine to the main `parse_machine_response`
  #  method above.
  defp parse_machine_response(%{
    "xenName" => id,
    "name" => name,
    "metal" => machine_map, # Used for region name
    "usageRate" => usage_map, # Used for machine kind/desc., and spot/on_demand
    "publicIp" => public_ip,
    # Missing private IP
    "gpus" => gpu_list, # Used for GPU details. Assumed only one type
    "state" => state,
    "isRemoved" => is_deactivated?, # Used to determine if suspended, or deleted
    "isPreemptible" => is_preemptible?
  }) do
    # Call the main method, but setting privateIp map to just contain
    #  nil for the address
    parse_machine_response(%{
      "xenName" => id,
      "name" => name,
      "metal" => machine_map,
      "usageRate" => usage_map,
      "publicIp" => public_ip,
      "privateIp" => %{"ipaddress" => nil},
      "gpus" => gpu_list,
      "state" => state,
      "isRemoved" => is_deactivated?,
      "isPreemptible" => is_preemptible?
    })
  end


  # Formatter for machines returned by the /getMachine endpoint.
  # This version handles any unexpected format, which includes errors.
  defp parse_machine_response(_resp) do
    {:error, "Failed to unpack response: One or more expected fields missing"}
  end



  ###########################################
  # Start / Stop / Delete specific instance #
  ###########################################

  @doc """
  Makes a request to start an existing machine, using the
  machines/<machine_id>/start endpoint.

  Does not currently block on this request.
  """
  @doc since: "2023-08-28"
  def start_machine(api_key, machine_id) do
    # Make request to /machines/<machine_id>/start to start machine
    {status, resp} = api_request_post(api_key,
      "/machines/#{machine_id}/start")

    # Wait until machine is "ready"
    {status, resp} = wait_for_state_change(status, resp, api_key, machine_id, :Running)

    # Parse response from waiting and return formatted response!
    parse_start_response(status, resp)
  end

  defp parse_start_response(:ok, %{:instance_id => machine_id}) do
    {
      :ok,
      %{
        request_id: nil, # Paperspace has no request IDs
        message: "started Paperspace instance #{machine_id}"
      }
    }
  end

  defp parse_start_response(:ok, _) do
    # The machine started, just we don't know the ID as it was missing
    #  from response. Still return an ok from this
    {
      :ok,
      %{
        request_id: nil, # Paperspace has no request IDs
        message: "started Paperspace instance UNKNOWN ID"
      }
    }
  end

  defp parse_start_response(:error, resp), do: {:error, resp}



  @doc """
  Makes a request to shutdown an existing machine, using the
  machines/<machine_id>/stop endpoint.

  Does not currently block on this request.
  """
  @doc since: "2023-08-28"
  def stop_machine(api_key, machine_id) do
    # Make request to /machines/<machine_id>/stop to stop machine
    {status, resp} = api_request_post(api_key,
      "/machines/#{machine_id}/stop")

    # Wait until machine is "off"
    {status, resp} = wait_for_state_change(status, resp, api_key, machine_id, :Stopped)

    # Parse response from waiting and return formatted response!
    parse_stop_response(status, resp)
  end

  defp parse_stop_response(:ok, %{:instance_id => machine_id}) do
    {
      :ok,
      %{
        request_id: nil, # Paperspace has no request IDs
        message: "stopped Paperspace instance #{machine_id}"
      }
    }
  end

  defp parse_stop_response(:ok, _) do
    # The machine started, just we don't know the ID as it was missing
    #  from response. Still return an ok from this
    {
      :ok,
      %{
        request_id: nil, # Paperspace has no request IDs
        message: "stopped Paperspace instance UNKNOWN ID"
      }
    }
  end

  defp parse_stop_response(:error, resp), do: {:error, resp}



  @doc """
  Makes a request to delete an existing machine, using the
  machines/<machine_id>/destroyMachine endpoint.

  Does not block, as it's expected once a machine is deleted it will not
  be accessed for anything other than audit logs and pricing info.
  """
  @doc since: "2023-08-28"
  def delete_machine(api_key, machine_id) do
    # Make request to /machines/<machine_id>/destroyMachine to delete
    #  machine
    {status, resp} = api_request_post(api_key,
      "/machines/#{machine_id}/destroyMachine")

    # NOTE: If we got an error status, usually gives a non-descriptive
    #  "No such account found"
    if status == :ok do
      {
        :ok,
        %{
          request_id: nil, # Paperspace has no request IDs
          message: "deleted Paperspace instance: #{machine_id}"
        }
      }
    else
      {
        :error,
        "Failed to delete instance #{machine_id} for vendor Paperspace: #{resp}"
      }
    end
  end



  # Helpers for both start/stop
  @waitfor_interval 5_000 # ms, 5 seconds, we will repoll after this long
  @waitfor_timeout 300_000 # ms, 5 minutes, we will wait for up to this long
  defp wait_for_state_change(status, resp, api_key, machine_id, state, total_time \\ 0)
  defp wait_for_state_change(:ok, _resp, api_key, machine_id, state, total_time) do
    # No need for _resp argument, it is only set if POST request had an
    #  error, and can be used for passing on error

    # The endpoint waitFor
    #  (https://docs.paperspace.com/core/api-reference/machines/#waitfor)
    #  is not available to use via any request library. Lookint at the
    #  node.js implementation
    #  (https://github.com/Paperspace/paperspace-node/blob/d3c61d31d8aa93fc27cb149c7e6581ecc8e1dbdd/lib/machines/waitfor.js#L72)
    #  it just keeps polling the given machine until the state becomes
    #  what is desired. We will do the same here.

    # Wait for interval
    :timer.sleep(@waitfor_interval)
    total_time = total_time + @waitfor_interval

    # Fetch machine info
    {status, resp} = list_machine(api_key, machine_id)

    cond do
      # If status is error, use the wait_for_state_change error parser
      #  to give a message
      status == :error ->
        wait_for_state_change(:error, resp, nil, machine_id, state)

      # If status is ok, and machine is in desired state, return resp
      status == :ok and resp[:status] == state ->
        {:ok, resp}

      # If status is ok, but machine not in state yet, check if we have
      #  timed out in this request. If not, make another request
      status == :ok and total_time <= @waitfor_timeout ->
        wait_for_state_change(:ok, nil, api_key, machine_id, state, total_time)

      # If we have timed out, return an error saying so
      true ->
        {:error, "Timed out waiting for #{machine_id} for vendor Paperspace"}
    end
  end

  defp wait_for_state_change(:error, resp, _api_key, machine_id, state, _total_time) do
    # Last response had an error, construct an error message based on
    #  the state we were waiting for
    case state do
      :Running -> {:error, "Failed to start instance #{machine_id} for vendor Paperspace: #{resp}"}
      :Stopped -> {:error, "Failed to stop instance #{machine_id} for vendor Paperspace: #{resp}"}
      _        -> {:error, "Failed to UNKNOWN instance #{machine_id} for vendor Paperspace: #{resp}"}
    end
  end


  ####################################
  # Pricing information for instance #
  ####################################

  @doc """
  Fetches the hourly rate for renting the machine, and monthly rate for
  renting storage.

  Has not been tested on monthly spot instances.

  Cannot currently make the distinction between spot/on demand, but can
  be implemented using the private `_list_machine` function.
  """
  @doc since: "2023-08-28"
  def fetch_pricing_info(api_key, machine_id) do
    # We need the number of days in the current month to estimate the
    #  hourly rate for storage from the given monthly rate
    current_dt = DateTime.utc_now()
    nb_days = :calendar.last_day_of_the_month(current_dt.year, current_dt.month)

    # Make a request with /getMachine to get all machine info - more
    #  reliable than the getUtilization method
    {status, resp} = api_request_get(api_key,
      "/machines/getMachine",
      [{"publicMachineId", machine_id}])

    # Parse the response and return
    parse_pricing_info(status, resp, nb_days)
  end

  # If fields usageRate and xenName exist, continue parsing
  defp parse_pricing_info(:ok, %{"usageRate" => usageRate, "xenName" => name}, nb_days) do
    parse_pricing_from_usage(usageRate, name, nb_days)
  end

  # If fields are missing, return an error
  defp parse_pricing_info(:ok, _, _), do: {:error, "Unknown format response from /machines/getMachine"}

  # If API request returned error, propagate it
  defp parse_pricing_info(:error, msg, _nb_days), do: {:error, msg}

  # Assume valid usageRate map for subsequent parsing
  defp parse_pricing_from_usage(%{
    "rateHourly" => rateHourly,
    "rateMonthly" => rateMonthly,
    "type" => billing_type
  }, name, nb_days) do
    {machine_rate_hourly,  _str} = Float.parse(rateHourly)
    {storage_rate_monthly, _str} = Float.parse(rateMonthly)

    # Calculate the total hourly rate from these two values
    rate = machine_rate_hourly + storage_rate_monthly / (nb_days * 24)

    # From the usageRate type field, determine if spot or on demand. If
    #  unknown, respond with an error
    case billing_type do
      "hourly" -> {
        :ok, %{
          name => %{
            net_cost_on_demand: rate,
            net_cost_spot: nil
          }
        }
      }

      "monthly" -> {
        :ok, %{
          name => %{
            net_cost_on_demand: nil,
            net_cost_spot: rate
          }
        }
      }

      _ -> {:error, "Unknown billing type #{billing_type}"}
    end
  end

  defp parse_pricing_from_usage(_usageRate, _name, _nb_days) do
    {:error, "Failed to unpack usageRate: one or more fields missing"}
  end



  #######################################
  # Audit logging for specific instance #
  #######################################

  @doc """
  Fetches an audit log for the given instance, using the /getMachine
  endpoint and setting the `includeAllEvents` parameter to true.

  Does support user attribution, but it uses userId numbers instead of
  the general publicly accessible user tags. It's currently unclear how
  this number can be translated to a tag, or vice versa.

  Does not currently set the `severity`.
  """
  @doc since: "2023-08-28"
  # TODO: What is needed for severity?
  # TODO: Translating userId to something useable
  def fetch_audit_log(api_key, machine_id) do
    # Use the /getMachien endpoint with "includeAllEvents" flag set to
    #  fetch all events with user attribution.
    {status, resp} = api_request_get(api_key,
      "/machines/getMachine",
      [{"publicMachineId", machine_id}, {"includeAllEvents", true}])

    # Parse the response and return
    parse_audit_log(status, resp)
  end

  defp parse_audit_log(:ok, %{
    "events" => events,
    "metal" => %{
      "datacenter" => %{
        "region" => %{
          "name" => zone_name
        }
      }
    }
  }) do
    response_list = Enum.map(events, &parse_event(&1, zone_name))
    status_list   = Enum.map(response_list, &elem(&1, 0))
    events_list   = Enum.map(response_list, &elem(&1, 1))
    if Enum.any?(status_list, &(&1 == :error)) do
      # TODO: more specific error message
      {:error, "Error parsing one or more events"}
    else
      {:ok, events_list}
    end
  end

  defp parse_audit_log(:ok, _resp) do
    {:error, "Failed to parse audit log: one or more fields missing from response"}
  end
  defp parse_audit_log(:error, msg), do: {:error, msg}

  defp parse_event(%{
    "id" => id,
    "handle" => handle,
    "dtCreated" => dt_created,
    "machineId" => machine_id,
    "userId" => user_id,
    "name" => name,
    "errorMsg" => error_msg,
    "state" => state
  }, zone_name) do
    # An event in resp["events"] contains the following:
    # - userId
    # - machineId
    # - name (event type)
    # - state (status of that event, if it's done or not)
    # - errorMsg ('' if no error)
    # - handle (a string, UUID)
    # - dtModified
    # - dtFinished
    # - dtCreated
    # - dtStarted
    # - id (unique ID for the log)
    # Construct the actual response with these!
    {:ok,
      %{
        # Provider-generated unique event ID (string)
        cloud_log_id: id,
        # TODO: Cast to string

        # Provider-generated request ID (string)
        request_id: handle,

        # Time when event happened (ISO8601 string)
        cloud_timestamp: dt_created,
        # NOTE: dtModified, dtFinished, dtCreated, dtStarted are all
        #  valid options for the timestamp. Unsure which makes most
        #  sense given the context.

        # A severity (string)
        severity: "TODO: fetch severity", # Generally "NOTICE or ERROR"
        # TODO: Generate this somehow

        # Instance ID of the instance related to the event (string)
        instance_id: machine_id,
        # TODO: Cast to string

        # Zone/region/etc where event happened (string)
        zone: zone_name,

        # User identifier
        user_id: user_id,
        # TODO: Cast to string

        # The event type
        method_name: name,
        # TODO: Turn into :x format

        # Any error messages if there is one.
        # If "success" isn't necessary, can use this commented out line
        # status: (if event["errorMsg"] == "", do: event["state"], else: event["errorMsg"])
        status: (
          # If there's an error message, use that
          if error_msg != "", do: error_msg,

          # If the event state is "done", use "success" as status.
          # If the event is not "done", use the event state as status
          else: (
            if state == "done", do: "success", else: state
          )
        )
      }
    }
  end

  defp parse_event(_event, _zone_name) do
    {:error, "Failed to unpack event: one or more fields missing"}
  end



  ########################
  # Web Request Handling #
  ########################

  # API request making methods. Pass in the endpoint, along with api key
  #  and any params/data needed. Endpoint must include / at start
  defp api_request_get(api_key, endpoint, query) do
    # Construct the full URL using the endpoint
    url = "https://api.paperspace.io#{endpoint}"

    # Construct header containing API key
    headers = [{"X-Api-Key", api_key}]

    # Make GET request
    {tesla_status, r} = Tesla.get(url, headers: headers, query: query)

    # Attempt to decode the response and return
    decode_response(tesla_status, r)
  end
  defp api_request_post(api_key, endpoint, data \\ "") do
    # Construct the full URL using the endpoint
    url = "https://api.paperspace.io#{endpoint}"

    # Construct header containing API key
    headers = [{"X-Api-Key", api_key}]

    # Make POST request. "" is for the data field, unused for Paperspace
    # {tesla_status, r} = Tesla.post(url, "", headers: headers)
    {tesla_status, r} = Tesla.post(url, data, headers: headers)

    # Attempt to decode the response and return
    decode_response(tesla_status, r)
  end


  # Decoding a successful GET/POST request, but may still have errors
  defp decode_response(:ok, r) do
    cond do
      # If status of response was 200, attempt to decode content
      r.status == 200 ->
        decode_successful_response(r)

      # If status of response was 204, no content and can give nil
      r.status == 204 ->
        {:ok, nil}

      # If status was neither of these, we need to return an error of
      #  some form.
      true ->
        decode_unsuccessful_response(r)
    end
  end

  # Decoding a failed GET/POST request
  defp decode_response(:error, r) do
    # When Tesla fails in a fetch (not on the part of server), we just
    #  pass through the error
    {:error, r}
  end


  # Decode a successful 200 coded response.
  defp decode_successful_response(r) do
    # Attempt to decode r as json. If this fails, return an error
    {json_status, resp} = Jason.decode(r.body)
    if json_status != :ok do
      {:error, "Failed to decode json in request"}
    else
      {:ok, resp}
    end
  end

  # Decode an unsuccessful non-200 response
  defp decode_unsuccessful_response(r) do
    # Attempt to decode r as json. If this fails, return a generic error
    #  based on status of response
    {json_status, resp} = Jason.decode(r.body)

    # If json was successful and has an error message, return that
    if json_status == :ok and json_has_error_message?(resp) do
      {:error, resp["error"]["message"]}

    # Otherwise, return a generic error message
    else
      case r.status do
        400 -> {:error, @generic_msg_400}
        401 -> {:error, @generic_msg_401}
        403 -> {:error, @generic_msg_403}
        404 -> {:error, @generic_msg_404}
        405 -> {:error, @generic_msg_405}
        408 -> {:error, @generic_msg_408}
        409 -> {:error, @generic_msg_409}
        412 -> {:error, @generic_msg_412}
        413 -> {:error, @generic_msg_413}
        429 -> {:error, @generic_msg_429}
        499 -> {:error, @generic_msg_499}
        500 -> {:error, @generic_msg_500}
        _   -> {:error, "Unknown error code #{r.status}"}
      end
    end
  end

  defp json_has_error_message?(resp) do
    Map.has_key?(resp, "error") and Map.has_key?(resp["error"], "message")
  end
end
