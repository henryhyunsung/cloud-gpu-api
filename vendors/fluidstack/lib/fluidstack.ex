defmodule Fluidstack do
  @moduledoc """

  The fluidstack API has very recently been redesigned. 
   
  - The previous API used conventions established in the documentation here:
    https://fluidstack.notion.site/API-Documentation-1627d4a8fc3a406ab8b054fc63a56fcc
  
  The current API still requires the same credential system but has updated
  return models, http request requirements, and available information. 

  - The new API documentation can be retreived from: 
    https://api.fluidstack.io/

  A users api key and token can be retrieved (and generated) from the dashboard.

  - This can be retrieved here: https://console2.fluidstack.io/
  
  Deliverables:
    - COMPLETE: Retrieve access token
 
      An API key and token should be provided by the user. Alternatively, the username and password
      of a user can be used to create a temporary token.
  
    - COMPLETE: User/Account id

      User account information can be retrieved. This displays information such
      as email, username, api key, ssh keys and other user properties.

    - COMPLETE: List information about all virtual machine instances
      
      Information related to each current existing instance associated with 
      a key-token pair will be returned.

    - COMPLETE: Get information about a specific virtual machine instance

      Uses the previous deliverable to filer out instance information.

    - COMPLETE: Start, stop and delete a specific virtual machine instance
      
      Each action has a different endpoint. Fluidstack will return a 
      message indicating success or failure. 

    - COMPLETE: Retrieve pricing information about a virtual machine instance
      
      Returns the price/hour of the current instance. 

    - COMPLETE: Retrieve audit logging about a specific virtual machine instance

      Logging information can be returned about all instances. The creation, start/stop times,
      and deletion times of all machines are included.

    - UNAVAILABLE: Retrieve a list of projects
      
      Fluidstack does not have a notion of grouping resources. It does however allow the 
      use of sub-accounts.

  Fluidstack Capabilities:
    - DOES support the 'create' operation
    - DOES have a concept of 'instance logs'
    - DOES have a concept of instances
    - DOES NOT: have a concept of projects
    - DOES: support 'start' operations
    - UNSURE? support syncing

  """

  import Fluidstack.ApiWrapper

  def setup do 
    {System.get_env("FLUIDSTACK_APIKEY"),
     System.get_env("FLUIDSTACK_APITOKEN"),
     System.get_env("FLUIDSTACK_TESTID")}
  end 
  
  @doc """ 
    [DELIVERABLE: Get api token]

    Attempt to generate a new api token for a user account when provided a key and token.
    NOTE: This renders the old token invalid.
    NOTE: Generating tokens with email and password appears to still be in development by Fluidstack.

    Response is of the form:
    `{:ok, %{token: user_token}}`
    or
    `{:error, message}`.
  """
  def get_api_token(api_key, api_token) do
    # Request headers.
    headers = [
      {"Authorization", "Basic #{Base.encode64("#{api_key}:#{api_token}")}"},
      {"Accept", "application/json"}
    ]

    # Server endpoint.
    endpoint = "auth/generate_api_token"

    # Request method.
    method = "GET"
    
    # Make request.
    {status, r} = make_request(method, endpoint, nil, headers)

    case status do
      :ok -> parse_token_response(r)
      :error -> {:error, r}
    end

  end
  
  defp parse_token_response(%{"api_token" => token, "message" => "success"}) do
    {:ok, %{token: token}}
  end
  defp parse_token_response(%{"api_token" => token, "message" => msg}) do
    {:error, "Fluidstack message: #{msg}. Returned token: #{token}."}
  end

  def validate_credentials(api_key, api_token) do
    case get_user_info(api_key, api_token) do
      {:ok, _info} -> {:ok, "Valid api_key and api_token."}
      {:error, error} -> {:error, error}
    end
  end

  @doc """ 
    [DELIVERABLE: User/Account identifier]

    Attempt to information about a user account when provided a key and token.
    
    Response is of the form:
    `{:ok, user_id}`
    or
    `{:error, message}`.
  """
  def get_account_identifier(api_key, api_token) do
    
    {status, r} = get_user_info(api_key, api_token)

    case status do
      :ok -> {:ok, Map.get(r, "name", "<name> field missing")}
      :error -> {:error, r}
    end
  end

  @doc """
    Return user info given an api key and api token.

    Fluidstack returns information in the form:

     %{
        "address" => string,
        "api_token" => string,
        "balance" => string,
        "email" => string,
        "email_verified" => bollean,
        "id" => string,
        "name" => string,
        "organization" => string,
        "pending_sub_account_invites" => list,
        "phone" => string
    }}

    The id field is the users api key. The name field is their username.

    Response is of the form:
    `{:ok, map in the form as above}`
    or
    `{:error, message}`.
  """
  def get_user_info(api_key, api_token) do
    # Request headers.
    headers = [
      {"Authorization", "Basic #{Base.encode64("#{api_key}:#{api_token}")}"},
      {"Accept", "application/json"}
    ]

    # Server endpoint.
    endpoint = "user"

    # Request method.
    method = "GET"
    
    # Make request.
    make_request(method, endpoint, nil, headers)
  end

  @doc """ 
    [DELIVERABLE: List instances]

    Attempt to return information on all instances.
    
    Response is of the form:
    `{:ok, [instance_map]}`
    or
    `{:error, message}`.
    
    Successful responses have the fields as prescribed in the deliverables.
  """
  def list_instances(api_key, api_token) do 
    # Request headers.
    headers = [
      {"Authorization", "Basic #{Base.encode64("#{api_key}:#{api_token}")}"},
      {"Accept", "application/json"}
    ]

    # Server endpoint.
    endpoint = "servers"

    # Request method.
    method = "GET"
    
    # Make request.
    {status, r} = make_request(method, endpoint, nil, headers)
    
    case {status, r} do
      {:ok, r} ->  {status, Enum.map(r, fn map -> parse_instance(map) end)}
      {:error, r} -> {status, r}
    end
  end
  
  @doc """ 
    [DELIVERABLE: List instance]

    Attempt to return information on a single instance..
    
    Response is of the form:
    `{:ok, instance_map}`
    or
    `{:error, message}`.
    
    Successful responses have the fields as prescribed in the deliverables.
  """
  def list_instance(api_key, api_token, id) do 
    
    # Get a list of of all instances.
    {status, r} = list_instances(api_key, api_token)

    # If found lists, search for instance with id
    case  {status, r} do
      {:ok, r} -> find_instance(r, id)
      {status, r} -> {status, r}
    end
  end

  defp find_instance(r, id) do
    case Enum.find(r, fn map -> Map.get(map, :instance_id) == id end) do
      nil -> {:error, "Could not find instance with id: #{id}."}
      instance -> {:ok, instance}
    end
  end

  defp parse_instance(
    %{
      "config" => 
        %{
          "cpu_count" => cpu_count,
          "cpu_model" => cpu_type,
          "gpu_count" => gpu_count,
          "gpu_model" => gpu_type,
          "ram" => ram
        },
      "current_rate" => current_rate,
      "hostname" => hostname,
      "id" => id,
      "ip_address" => ip_address,
      "os" => os,
      "region" => region,
      "status" => status,
    }) do 
    %{
      instance_id: id,
      name: hostname,
      zone: region,
      description: "#{cpu_count} CPU(s) and #{gpu_count} GPU(s)",
      machine_type: "CPU: #{cpu_type}, GPU: #{gpu_type}",
      external_ip: ip_address,
      internal_ip: ip_address,
      os_type: os,
      # Commitments are: hourly, monthly, six_monthly, yearly.
      # Documentation (https://www.fluidstack.io/faq) states on demand machines.
      billing_type: :on_demand,
      preemptible: false,
      accelerator_count: "#{gpu_count}",
      accelerator_type: gpu_type,
      accelerator_memory: ram, # Memory is in GB
      status: 
        case status do
          "running"   -> :Running
          "starting"  -> :Starting
          "suspended" -> :Suspended
          "stopping"  -> :Stopping
          "stopped"   -> :Stopped
          _           -> :Unknown
        end,
      rate: current_rate
    }
  end
  defp parse_instance(_instance) do
    {:error, "One or more fields missing."}
  end
  
  @doc """ 
    [DELIVERABLE: STOP instance]

    Attempt to stop a machine given an instance id and credentials.
    
    Response is of the form:
    `{:ok, success message}`
    or
    `{:error, error message}`. 
  """
  def stop_instance(api_key, api_token, instance_id) do 
    # Request headers.
    headers = [
      {"Authorization", "Basic #{Base.encode64("#{api_key}:#{api_token}")}"},
      {"Accept", "application/json"}
    ]

    # Server endpoint.
    endpoint = "server/#{instance_id}/stop"

    # Request method.
    method = "PUT"

    # Attempt get request.
    make_request(method, endpoint, nil, headers)
  end
  
  @doc """ 
    [DELIVERABLE: START instance]

    Attempt to start a machine given an instance id and credentials.
   
     Response is of the form:
    `{:ok, success message}`
    or
    `{:error, error message}`. 
  """
  def start_instance(api_key, api_token, instance_id) do 
    # Request headers.
    headers = [
      {"Authorization", "Basic #{Base.encode64("#{api_key}:#{api_token}")}"},
      {"Accept", "application/json"}
    ]

    # Server endpoint.
    endpoint = "server/#{instance_id}/start"

    # Request method.
    method = "PUT"

    # Attempt get request.
    make_request(method, endpoint, nil, headers)
  end

  @doc """ 
    [DELIVERABLE: DELETE instance]

    Attempt to delete a machine given an instance id and credentials.
    
    Response is of the form:
    `{:ok, success message}`
    or
    `{:error, error message}`. 
  """
  def delete_instance(api_key, api_token, instance_id) do 
    # Request headers.
    headers = [
      {"Authorization", "Basic #{Base.encode64("#{api_key}:#{api_token}")}"},
      {"Accept", "application/json"}
    ]

    # Server endpoint.
    endpoint = "server/#{instance_id}"

    # Request method.
    method = "DELETE"

    # Attempt get request.
    make_request(method, endpoint, nil, headers)
  end

  @doc """ 
    [DELIVERABLE: instance pricing]

    Attempt to return a map of id => price values.
    
    Response is of the form:
    `{:ok, %{instance_id => {net_cost_on_demand => c1, net_cost_spot => c2}}}`
    or
    `{:error, error message}`. 
  """
  def instance_pricing(api_key, api_token) do
    # Request headers.
    headers = [
      {"Authorization", "Basic #{Base.encode64("#{api_key}:#{api_token}")}"},
      {"Accept", "application/json"}
    ]

    # Server endpoint.
    endpoint = "servers"

    # Request method.
    method = "GET"
    
    # Make request.
    {status, r} = make_request(method, endpoint, nil, headers)
    
    case {status, r} do
      {:ok, r} -> 
        {
          status,
          Enum.reduce(r, %{}, fn map, acc ->
            key = Map.get(map, "id", "missing_id")
            value = %{net_cost_on_demand: parse_rates(map), net_cost_spot: nil}
            Map.put(acc, key, value) end)
        }
     {:error, r} -> {status, r}
    end
  end
  
  defp parse_rates(%{"running_rate" => running_rate, "stopped_rate" => stopped_rate}) do
    with {n1, _} <- Float.parse(running_rate),
         {n2, _} <- Float.parse(stopped_rate) 
    do
      n1 + n2
    else
      _ -> "Invalid running_rate or stopped_rate"
    end
  end
  defp parse_rates(_map) do
    "Instance info does not contain running_rate or stopped_rate"
  end

  @doc """ 
    [DELIVERABLE: Audit logs]

    Attempt to return information about instance events.

    Fluidstack returns information about every successful transaction.
    
    Response is of the form:
    `{:ok, [audit_log_map]}`
    or
    `{:error, message}`.
    
    Successful responses have maps with fields as prescribed in the deliverables.
  """
  def instance_logs(api_key, api_token) do 
    # Request headers.
    headers = [
      {"Authorization", "Basic #{Base.encode64("#{api_key}:#{api_token}")}"},
      {"Accept", "application/json"}
    ]

    # Server endpoint.
    endpoint = "payment/billing"

    # Request method.
    method = "GET"

    # Attempt get request.
    {status, r} = make_request(method, endpoint, nil, headers)

    case {status, r} do
      {:ok, r} -> {:ok, r} # {status, Enum.map(r, fn map -> parse_logs(map) end)}
      {status, r} -> {status, r}
    end
  end
  
  # Filter instance logs by machine id
  def instance_logs(api_key, api_token, id) do
  
    {status, r} = instance_logs(api_key, api_token)

    case status do
      :ok -> {:ok, Enum.filter(r, fn m -> String.contains?( Map.get(m, "name", ""), id) end)}
      _ -> {status, r}
    end
  end
end
