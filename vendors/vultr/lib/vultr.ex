defmodule Vultr do
  @moduledoc """
  Methods for the Vultr cloud vendor. Includes: listing instances,
  creating instances, starting/stopping/deleting instances, listing
  plans, fetching billing rates for instances
  """
  import Vultr.RequestMethods
  # require Logger


  # NOTE: Most methods assume regular instances are used instead of
  #  bare-metal instances. This is so that testing wasn't extremely
  #  expensive. Changes that would need to be made to support bare-metal
  #  instances is changing some endpoints. See:
  #    https://www.vultr.com/api/#tag/baremetal


  ##################
  # Fetching plans #
  ##################

  # Helper for fetching plan information. This needs to be done to
  #  handle billing and some machine listing details.
  # NOTE: This method should be implemented to fetch a local copy rather
  #  than fetching all plans every time.
  def fetch_plans(api_key) do
    {status, resp} = fetch_plans_priv(api_key)
    if status == :ok do
      {status, resp}
    else
      {status, "Failed to fetch plans: #{resp}"}
    end
  end

  defp fetch_plans_priv(api_key) do
    # Fetch all plans for GPUs
    # https://www.vultr.com/api/#tag/plans/operation/list-plans
    {status, resp} = api_request_get_paginated(api_key,
      "/plans", [{"type", "all"}])
    # NOTE: vcg filters plans for machines with GPUs
    # This will be a list of responses

    # Get plans from paginated response
    {status, plans} = flatten_paginated_response_by_key(status, resp, "plans")

    # Parse each plan and return status with plans
    parse_plans(status, plans)
  end

  # Parsing a list of raw plans
  # TODO: Swap out with reduce_while
  defp parse_plans(:ok, plans) do
    # Parse each plan, getting a (status, plan) tuple for each.
    status_plan_list = plans |> Enum.map(fn p -> parse_plan(p) end)

    # Check if any errors. If so, return first error message
    if Enum.any?(status_plan_list |> Enum.map(fn {s, _} -> s == :error end)) do
      # Find first error message
      {_, msg} = Enum.find(status_plan_list, fn {s, _} -> s == :error end)
      {:error, msg}

    # If no errors, just return values
    else
      {:ok, status_plan_list |> Enum.map(fn {_, p} -> p end)}
    end
  end
  defp parse_plans(:error, msg), do: {:error, msg}

  # Parses a plan
  defp parse_plan(%{
    "locations" => zones,
    "id" => machine_type,
    "monthly_cost" => monthly_cost,
    "vcpu_count" => accelerator_count,
    "gpu_type" => accelerator_type,
    "gpu_vram_gb" => accelerator_memory # Is GB
  }) do
    {
      :ok,
      %{
        machine_type: machine_type,
        zones: zones,
        monthly_cost: monthly_cost,
        accelerator_count: accelerator_count |> to_string(),
        accelerator_type: accelerator_type,
        accelerator_memory: accelerator_memory * 1024 # Turn to MB
      }
    }
  end
  # Version for demo, could not get GPU machines working so just using
  #  plans with no GPU info
  defp parse_plan(%{
    "locations" => zones,
    "id" => machine_type,
    "monthly_cost" => monthly_cost,
    "vcpu_count" => accelerator_count,
  }) do
    accelerator_type = nil
    accelerator_memory = 0
    {
      :ok,
      %{
        machine_type: machine_type,
        zones: zones,
        monthly_cost: monthly_cost,
        accelerator_count: accelerator_count |> to_string(),
        accelerator_type: accelerator_type,
        accelerator_memory: accelerator_memory * 1024 # Turn to MB
      }
    }
  end
  defp parse_plan(_), do: {:error, "Error parsing plan"}



  ######################
  # Create New Machine #
  ######################

  @doc """
  Creates a new machine.

  Endpoint: https://www.vultr.com/api/#tag/instances/operation/create-instance

  Does not make any assumptions about plans.

  Default setup:
  - Ubuntu22.04 LTS for operating system
  - IPv6 disabled
  - IPv4 enabled
  - No SSH keys
  - Hostname mirrors given name of machine

  NOTE: A created machine needs to be given an SSH key ID, managed by
  Vultr. Currently does not pass any in, though this might need to be
  changed.

  NOTE: On successful create, machine info is returned. This includes
  the default password, which is important if creating with no SSH keys.
  This response is included in the response as it's unclear what should
  be done with this information.
  """
  @ubuntu2204lts64x_id 1743 # os_id for Ubuntu 22.04 LTS x64
  def create_machine(api_key, name, region, plan_id) do
    # Make POST request to create a new machine
    {status, resp} = api_request_post(api_key,
      "/instances",
      %{
        # Name of the machine. Also used for hostname
        label: name,
        hostname: name,

        # All regions can be fetched with
        #  https://www.vultr.com/api/#tag/region/operation/list-regions
        region: region,

        # Plans can be fetched currently with `fetch_plans`
        plan: plan_id,

        # Defaults, see docstring
        os_id: @ubuntu2204lts64x_id,
        enable_ipv6: false,
        disable_public_ipv4: false,
      }
    )

    # Handle response! Based on current Paperspace vendor library
    if status == :error do
      {:error, "Machine creation failed: #{resp}"}
    else
      {
        :ok,
        %{
          message: "New machine '#{name}' was created!",
          machine_info: resp
        }
      }
    end
  end



  #########################################
  # Listing information about instance(s) #
  #########################################
  # NOTE: Currently fetches non-"Bare-Metal" machines, which is the vast
  #  majority of GPU machines available. There is a similar endpoint for
  #  fetching these, '/bare-metals' and '/bare-metals/<machine_id>'.
  #  Adding support for these should be as simple as an extra request
  #  using that endpoint and concatenating the lists if successful.
  #  Testing for these machines would have been extremely high,
  #   https://www.vultr.com/products/bare-metal/#pricing
  #  but response format should be the same.


  @doc """
  Retrieve a single machine by machine ID.

  Endpoint: https://www.vultr.com/api/#tag/instances/operation/get-instance

  GPU information is not included in the endpoint response, and requires
  fetching of plans and matching by plan ID. Plan fetching should
  probably be moved to fetching a local copy.

  Does not include:
  - billing type: Couldn't find what identifies the type
  - preemptible: Could't find what identifies this
  """
  def list_machine(api_key, machine_id) do
    {status, resp} = list_machine_priv(api_key, machine_id)
    if status == :ok do
      {status, resp}
    else
      {status, "Failed to list machine: #{resp}"}
    end
  end

  # Private version to be used within functions
  defp list_machine_priv(api_key, machine_id) do
    # First try fetch single machine
    {machine_status, resp} = api_request_get(api_key, "/instances/#{machine_id}")
    {machine_status, machine} = parse_machine_response(machine_status, resp)

    # Fetch plans
    {plans_status, plans} = fetch_plans_priv(api_key)

    cond do
      # If both requests were successful, try find the correct plan
      #  given the machine and return successful response
      machine_status == :ok and plans_status == :ok ->
        parse_machine(machine, plans)

      # Otherwise, return an error message
      machine_status != :ok ->
        {:error, "(Machine) #{machine}"}

      plans_status != :ok ->
        {:error, "(Plans) #{plans}"}
    end
  end


  @doc """
  Retrieve a list of all machines associated with user's account.

  Endpoint: https://www.vultr.com/api/#tag/instances/operation/list-instances

  GPU information is not included in the endpoint responses, and
  requires fetching of plans and matching by plan ID. Plan fetching
  should probably be moved to fetching a local copy.

  Does not include:
  - billing type: Couldn't find what identifies this
  - preemptible: Couldn't find what identifies this
  """
  def list_machines(api_key) do
    {status, resp} = list_machines_priv(api_key)
    if status == :ok do
      {status, resp}
    else
      {status, "Failed to list machines: #{resp}"}
    end
  end

  # Private version to be used within functions
  defp list_machines_priv(api_key) do
    # First try fetch all machines, flattening paginated request
    {machines_status, resp} = api_request_get_paginated(
      api_key, "/instances", [{"type", "all"}])
    {machines_status, machines} = flatten_paginated_response_by_key(
      machines_status, resp, "instances")

    # Fetch plans
    {plans_status, plans} = fetch_plans_priv(api_key)

    cond do
      # If both requests were successful, try return matched plans
      machines_status == :ok and plans_status == :ok ->
        parse_machines(machines, plans)

      # Otherwise, return an error message
      machines_status != :ok ->
        {:error, "(Machines) #{machines}"}

      plans_status != :ok ->
        {:error, "(Plans) #{plans}"}
    end
  end

  # Pull 'instance' from single machine response
  defp parse_machine_response(:ok, %{"instance" => instance}) do
    {:ok, instance}
  end
  defp parse_machine_response(:ok, _), do: {:error, "Response missing key 'instance'"}
  defp parse_machine_response(:error, msg), do: {:error, msg}

  # Parse list of multiple machines
  defp parse_machines(instances, plans) do
    # Parse each plan, getting a (status, plan) tuple for each.
    status_machines_list = instances |> Enum.map(fn m -> parse_machine(m, plans) end)

    # Check if any errors. If so, return first error message
    if Enum.any?(status_machines_list |> Enum.map(fn {s, _} -> s == :error end)) do
      # Find first error message
      {_, msg} = Enum.find(status_machines_list, fn {s, _} -> s == :error end)
      {:error, msg}

    # If no errors, just return machines!
    else
      {:ok, status_machines_list |> Enum.map(fn {_, m} -> m end)}
    end
  end

  # Parses a single machine, matching with plan
  defp parse_machine(%{
    "id" => instance_id,
    "label" => name,
    "region" => zone,
    "plan" => machine_type,
    "main_ip" => external_ip,
    "internal_ip" => internal_ip,
    "os" => os_type,
    "power_status" => status
  }, plans) do
    # Find matching plan
    plan = Enum.find(plans, fn x -> x[:machine_type] == machine_type end)
    # TODO: Check if plan exists. Error if not

    {
      :ok,
      %{
        # A unique indentifer for the instance. Usually a UUID or
        #  similar
        instance_id: instance_id,

        # The user-friendly name of the instance
        name: name,

        # The zone, region, or ohter location identifier that the
        #  instance exists in.
        zone: zone,

        # A user-friendly description of the instance.
        description: nil, # TODO, but optional

        # The cloud provider's "machine type" identifier
        machine_type: machine_type,

        # [Optional] IP addresses allocated to the machine
        external_ip: (if external_ip == "" do nil else external_ip end),
        internal_ip: (if internal_ip == "" do nil else internal_ip end),

        # [Optional] The OS type of the machine
        os_type: os_type,

        # Provisioning type of the machine - usually something like
        #  "spot" or "reserved", but cloud specific. Should be either
        #  :spot or :on_demand
        billing_type: :on_demand,
        # NOTE: Could not find any identifying information that could
        #  easily distinguish what type of plan is used.

        # Whether the machine is preemptible. Usually means that the
        #  machine is a spot instance which may be shut down without
        #  warning.
        # NOTE: Vultr does not have anything that indicates this
        preemptible: nil,

        # The number, type, and memory size of the GPUs connected to the
        #  machine.
        accelerator_count: plan[:accelerator_count],
        accelerator_type: plan[:accelerator_type],
        accelerator_memory: plan[:accelerator_memory],

        # Status of the machine. SHould be one of :Running, :Starting,
        #  :Suspending, :Suspended, :Stopping, :Stopped, :Unknown
        status:
          case status do
            "running" -> :Running
            "stopped" -> :Stopped
            _         -> :Unknown
            # TODO: Need to fill this out a lot more
          end
      }
    }
  end
  defp parse_machine(_, _), do: {:error, "(Machine) Error parsing machine"}
  


  ###########################################
  # Start / Stop / Delete specific instance #
  ###########################################

  @doc """
  Start an existing machine. Blocks until done.

  Endpoint: https://www.vultr.com/api/#tag/instances/operation/start-instance

  Vultr does not error if starting a started machine, so this will just
  give a success if done.
  """
  def start_machine(api_key, machine_id) do
    # Make request to /instances/<machine_id>/start to start machine
    # https://www.vultr.com/api/#tag/instances/operation/start-instance
    {status, resp} = api_request_post(api_key,
      "/instances/#{machine_id}/start")

    # Wait until machine is "ready"
    {status, resp} = wait_for_state_change(status, resp, api_key, machine_id, :Running)

    # Parse response from waiting and return formatted response!
    parse_start_response(status, resp)
  end

  # Response parser, actually parses response from wait_for_state_change
  defp parse_start_response(:ok, %{:instance_id => machine_id}) do
    {
      :ok,
      %{
        request_id: nil, # Vultr has no request IDs
        message: "started Vultr instance #{machine_id}"
      }
    }
  end
  defp parse_start_response(:ok, _) do
    # The machine started, just we don't know the ID as it was missing
    #  from response. Still return an ok from this
    {
      :ok,
      %{
        request_id: nil, # Vultr has no request IDs
        message: "started Vultr instance UNKNOWN ID"
      }
    }
  end
  defp parse_start_response(:error, resp), do: {:error, resp}


  @doc """
  Stop an existing machine. Blocks until done.

  Endpoint: https://www.vultr.com/api/#tag/instances/operation/halt-instance

  Vultr does not error if stopping a stopped machine, so this will just
  give a success if done.
  """
  def stop_machine(api_key, machine_id) do
    # Make request to /instances/<machine_id>/halt to stop machine
    # https://www.vultr.com/api/#tag/instances/operation/halt-instance
    {status, resp} = api_request_post(api_key,
      "/instances/#{machine_id}/halt")

    # Wait until machine is "stopped"
    {status, resp} = wait_for_state_change(status, resp, api_key, machine_id, :Stopped)

    # Parse response from waiting and return formatted response!
    parse_stop_response(status, resp)
  end

  # Response parser, actually parses response from wait_for_state_change
  defp parse_stop_response(:ok, %{:instance_id => machine_id}) do
    {
      :ok,
      %{
        request_id: nil, # Vultr has no request IDs
        message: "stopped Vultr instance #{machine_id}"
      }
    }
  end
  defp parse_stop_response(:ok, _) do
    # The machine started, just we don't know the ID as it was missing
    #  from response. Still return an ok from this
    {
      :ok,
      %{
        request_id: nil, # Vultr has no request IDs
        message: "stopped Vultr instance UNKNOWN ID"
      }
    }
  end
  defp parse_stop_response(:error, resp), do: {:error, resp}


  @doc """
  Deletes the given machine. Does not block.

  Endpoint: https://www.vultr.com/api/#tag/instances/operation/delete-instance
  """
  def delete_machine(api_key, machine_id) do
    # Make DELETE request to /instances/{machine_id} to delete machine
    # https://www.vultr.com/api/#tag/instances/operation/delete-instance
    {status, resp} = api_request_delete(api_key,
      "/instances/#{machine_id}")

    # No need to wait for pause. Just give a success if no error
    if status == :ok do
      {
        :ok,
        %{
          request_id: nil, # Vultr has no request IDs
          message: "deleted Vultr instance: #{machine_id}"
        }
      }
    else
      {
        :error,
        "Failed to delete instance #{machine_id} for vendor Vultr: #{resp}"
      }
    end
  end


  # Recursive method that waits intervals until a machine changes
  #  to desired state. Similar to Paperspace's node.js implementation
  @waitfor_interval 1_000 # ms, 1 second, we will repoll after this long
  @waitfor_timeout 300_000 # ms, 5 minutes, we will wait for up to this long
  defp wait_for_state_change(status, resp, api_key, machine_id, state, total_time \\ 0)
  defp wait_for_state_change(:ok, _resp, api_key, machine_id, state, total_time) do
    # No need for _resp argument, it is only set if POST request had an
    #  error, and can be used for passing on error.

    # There is no available endpoint for waiting until a state change
    #  for an instance. Instead, we will use a similar implementation as
    #  Paperspace.
    # Logger.debug(
    #   "Waiting for state change to #{state}, " <> 
    #   "total sleep #{total_time} ms of #{@waitfor_timeout} ms max, " <>
    #   "sleeping for #{@waitfor_interval} ms")

    # Wait for interval
    :timer.sleep(@waitfor_interval)

    # Fetch machine info
    {status, resp} = list_machine_priv(api_key, machine_id)

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
        wait_for_state_change(:ok, nil, api_key, machine_id, state, total_time + @waitfor_interval)

      # If we have timed out, return an error saying so
      true ->
        {:error, "Timed out waiting for #{machine_id} for vendor Vultr"}
    end
  end
  defp wait_for_state_change(:error, resp, _api_key, machine_id, state, _total_time) do
    # Last response had an error, construct an error message based on
    #  the state we were waiting for
    # NOTE: Should probably only return an error, and message can be
    #  moved to respective start/stop method
    case state do
      :Running -> {:error, "Failed to start instance #{machine_id} for vendor Vultr: #{resp}"}
      :Stopped -> {:error, "Failed to stop instance #{machine_id} for vendor Vultr: #{resp}"}
      _        -> {:error, "Failed to UNKNOWN instance #{machine_id} for vendor Vultr: #{resp}"}
    end
  end


  ####################################
  # Pricing information for instance #
  ####################################

  @doc """
  Fetches pricing for a given machine by machine ID.

  Uses `list_machine`

  Rate information is not included in the endpoint response for fetching
  a machine, and requires fetching of plans to match on. Plan fetching
  should probably be moved to fetching a local copy.
  """
  def fetch_pricing_info(api_key, machine_id) do
    {status, resp} = fetch_pricing_info_priv(api_key, machine_id)
    if status == :ok do
      {status, resp}
    else
      {status, "Failed to fetch pricing info: #{resp}"}
    end
  end

  # Private version to be used within functions
  defp fetch_pricing_info_priv(api_key, machine_id) do
    # First fetch the machine. We don't use the list_machine method as
    #  that also makes a request to fetch_plans, and we need the extra
    #  info anyway.
    {machine_status, resp} = api_request_get(api_key, "/instances/#{machine_id}")
    {machine_status, machine} = parse_pricing(machine_status, resp)

    # Fetch plans
    {plans_status, plans} = fetch_plans_priv(api_key)

    cond do
      # If both requests were successful, try find the correct plan
      #  given the machine and return successful response
      machine_status == :ok and plans_status == :ok -> 
        match_machine_with_plan(machine, plans)

      # Otherwise, return an error message
      machine_status != :ok ->
        {:error, "(Machine) #{machine}"}

      plans_status != :ok ->
        {:error, "(Plans) #{plans}"}
    end
  end

  # Pull 'instances' from machine response
  defp parse_pricing(:ok, %{"instance" => instance}) do
    parse_pricing_from_instance(instance)
  end
  defp parse_pricing(:ok, _), do: {:error, "Response missing key 'instance'"}
  defp parse_pricing(:error, msg), do: {:error, msg}

  # Pull id and type from machine instance
  defp parse_pricing_from_instance(%{"id" => instance_id, "plan" => machine_type}) do
    {
      :ok,
      %{
        id: instance_id,
        machine_type: machine_type
      }
    }
  end
  defp parse_pricing_from_instance(_), do: {:error, "Error parsing machine"}

  # Pairing a machine type with specific plan
  defp match_machine_with_plan(machine, plans) do
    # Find the matching plan
    plan = Enum.find(plans, fn p -> p[:machine_type] == machine[:machine_type] end)

    # If plan is nil, wasn't able to find a plan - return error.
    if plan == nil do
      {:error, "Unable to find plan '#{machine[:machine_type]}'"}

    # Otherwise, construct response!
    else
      # TODO: Identify if spot or on demand. Currently assuming on demand
      {
        :ok,
        %{
          machine[:id] => %{
            # NOTE: Cap for a month is 28 days worth of compute
            # NOTE: No need to check for :monthly_cost since this comes
            #  from fetch_plans, already checking existance
            net_cost_on_demand: plan[:monthly_cost] / (28 * 24),
            net_cost_spot: nil
          }
        }
      }
    end  
  end



  #######################################
  # Audit logging for specific instance #
  #######################################
  # Vultr does not support audit logging

end
