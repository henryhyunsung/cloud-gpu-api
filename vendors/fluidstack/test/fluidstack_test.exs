defmodule FluidstackTest do
  use ExUnit.Case
  doctest Fluidstack
  
  # Valid credentials
  @valid_key System.get_env("FLUIDSTACK_APIKEY")
  @valid_token System.get_env("FLUIDSTACK_APITOKEN")
  @valid_id System.get_env("FLUIDSTACK_TESTID")

  # Invalid credentials
  @invalid_key "invalid_key"
  @invalid_token "invalid_token"
  @invalid_id "invalid_id"

  # Set as nil if no id to delete
  @delete_id nil
  
  # Error messages
  @error_404 "NOT_FOUND [404] -- The requested resource doesn't exist."
  @error_401 "UNAUTHORIZED [401] -- The API key or token was invalid or expired."


  @tag :endpoint_invalid
  test "Endpoint Invalid" do

    # [WHEN]
    endpoint = "bad_endpoint"
    method = "GET"

    {status, resp} = Fluidstack.ApiWrapper.make_request(method, endpoint, nil, [])

    # [THEN]
    assert {status, resp} == {:error, @error_404}
  end
  
  @tag :method_invalid
  test "Method Invalid" do

    # [WHEN]
    endpoint = "server"
    method = ""

    {status, resp} = Fluidstack.ApiWrapper.make_request(method, endpoint, nil, [])

    # [THEN]
    assert {status, resp} == {:error, "Unkown request method: #{method}."}
  end
  
  @tag :method_invalid
  test "Method Invalid for Endpoint" do
    
    # [WHEN]
    endpoint = "server"
    method = "GET"

   {status, resp} = Fluidstack.ApiWrapper.make_request(method, endpoint, nil, [])
    
    # [THEN]
    assert {status, resp} == 
      {:error, %{"message" => "The method is not allowed for the requested URL."}}
  end
  
  @tag :keys_valid
  test "Valid Credentials" do
    # [WHEN]
    {status, _resp} = Fluidstack.validate_credentials(@valid_key, @valid_token)
    
    # [THEN]
    assert status == :ok
  end
  

  @tag :keys_invalid
  test "Invalid Credentials" do
    # [WHEN]
    {status, _resp} = Fluidstack.validate_credentials(@invalid_key, @invalid_token)
    
    # [THEN]
    assert status == :error
  end

  @tag :disabled
  @tag :get_token_valid
  test "Get Token Valid" do
    # [WHEN]
    {status, resp} = Fluidstack.get_api_token(@valid_key, @valid_token)
    
    # [THEN]
    assert status == :ok
    assert Map.has_key?(resp, :token) == true

  end
 
  @tag :get_token_invalid
  test "Get Token Invalid" do
    # [WHEN]
    {status, resp} = Fluidstack.get_api_token(@invalid_key, @invalid_token)
    
    # [THEN]
    assert {status, resp} == {:error, @error_401}
  end
 
  @tag :get_id_valid
  test "Get Id Valid" do
    # [WHEN]
    {status, _resp} = Fluidstack.get_account_identifier(@valid_key, @valid_token)
    
    # [THEN]
    assert status == :ok
  end
  
  @tag :get_id_invalid
  test "Get Id Invalid" do
    # [WHEN]
    {status, resp} = Fluidstack.get_account_identifier(@invalid_key, @invalid_token)
    
    # [THEN]
    assert {status, resp} == {:error, @error_401}
  end
  
  @tag :get_info_valid
  test "Get User Info Valid" do
    # [WHEN]
    {status, _resp} = Fluidstack.get_user_info(@valid_key, @valid_token)
    
    # [THEN]
    assert status == :ok
  end
  @tag :get_info_invalid
  test "Get User Info Invalid" do
    # [WHEN]
    {status, resp} = Fluidstack.get_user_info(@invalid_key, @invalid_token)
    
    # [THEN]
    assert {status, resp} == {:error, @error_401}
  end

  # @tag :disabled
  @tag :start_stop
  test "Start and Stop Valid Machine" do

    # [WHEN]
    {status, _resp} = Fluidstack.start_instance(@valid_key, @valid_token, @valid_id)
    # [THEN]
    assert status == :ok

    Process.sleep(50_000)
    
    # [WHEN]
    {status, _resp} = Fluidstack.stop_instance(@valid_key, @valid_token, @valid_id)
    
    # [THEN]
    assert status == :ok
  end

  @tag :disabled
  @tag :start_valid
  test "Start Valid Machine" do
    # [WHEN]
    {status, _resp} = Fluidstack.start_instance(@valid_key, @valid_token, @valid_id)
    
    # [THEN]
    assert status == :ok
  end
  
  @tag :start_invalid
  test "Start Invalid Machine" do
    
    # [WHEN] key is invalid
    {status, resp} = Fluidstack.start_instance(@invalid_key, @valid_token, @valid_id)
    # [THEN]
    assert {status, resp} == {:error, @error_401}

    # [WHEN] token is invalid
    {status, resp} = Fluidstack.start_instance(@valid_key, @invalid_token, @valid_id)
    # [THEN]
    assert {status, resp} == {:error, @error_401}
    
    # [WHEN] machine id is invalid 
    {status, resp} = Fluidstack.start_instance(@valid_key, @valid_token, @invalid_id)
    # [THEN] (Since the server name is dependent on machine id)
    assert {status, resp} == {:error, "Server not found"}
    

  end
 
  @tag :disabled
  @tag :stop_valid
  test "Stop Valid Machine" do
    # [WHEN]
    {status, _resp} = Fluidstack.stop_instance(@valid_key, @valid_token, @valid_id)
    
    # [THEN]
    assert status == :ok
  end

  @tag :stop_invalid
  test "Stop Invalid Machine" do
    
    # [WHEN] key is invalid
    {status, resp} = Fluidstack.stop_instance(@invalid_key, @valid_token, @valid_id)
    # [THEN]
    assert {status, resp} == {:error, @error_401}

    # [WHEN] token is invalid
    {status, resp} = Fluidstack.stop_instance(@valid_key, @invalid_token, @valid_id)
    # [THEN]
    assert {status, resp} == {:error, @error_401}
    
    # [WHEN] machine id is invalid 
    {status, resp} = Fluidstack.stop_instance(@valid_key, @valid_token, @invalid_id)
    # [THEN] (Since the server name is dependent on machine id)
    assert {status, resp} == {:error, "Server not found"}

  end
  
  # @tag :disabled
  @tag :delete_valid
  test "Delete Valid Machine" do
    # If a machine is supplied to delete then delete
    if @delete_id do
      # [WHEN]
      {status, _resp} = Fluidstack.delete_instance(@valid_key, @valid_token, @delete_id)

      # [THEN]
      assert status == :ok
    end
  end

  @tag :delete_invalid
  test "Delete Invalid Machine" do
    
    # [WHEN] key is invalid
    {status, resp} = Fluidstack.delete_instance(@invalid_key, @valid_token, @valid_id)
    # [THEN]
    assert {status, resp} == {:error, @error_401}

    # [WHEN] token is invalid
    {status, resp} = Fluidstack.delete_instance(@valid_key, @invalid_token, @valid_id)
    # [THEN]
    assert {status, resp} == {:error, @error_401}
    
    # [WHEN] machine id is invalid 
    {status, resp} = Fluidstack.delete_instance(@valid_key, @valid_token, @invalid_id)
    # [THEN] (Since the server name is dependent on machine id)
    assert {status, resp} == {:error, "Machine not found"}

  end
 
  @tag :list_instances_valid
  test "List Instances Valid" do

    # [WHEN] 
    {status, resp} = Fluidstack.list_instances(@valid_key, @valid_token)
    
    # [THEN] At least one instance map should be returned.
    assert status == :ok
    assert Enum.count(resp) > 0

  end
  
  @tag :list_instances_invalid
  test "List Instances Invalid" do
    
    # [WHEN] 
    {status, resp} = Fluidstack.list_instances(@invalid_key, @invalid_token)
    
    # [THEN] 
    assert {status, resp} == {:error, @error_401}

  end
  
  @tag :list_instance_valid
  test "List Instance Valid" do

    # [WHEN] 
    {status, resp} = Fluidstack.list_instance(@valid_key, @valid_token, @valid_id)
    
    # [THEN] At least one instance map should be returned.
    assert status == :ok
    assert Map.get(resp, :instance_id) == @valid_id

  end
  
  @tag :list_instance_invalid
  test "List Instance Invalid" do
    
    # [WHEN] Credentials are bad
    {status, resp} = Fluidstack.list_instance(@invalid_key, @invalid_token, @invalid_id)
    # [THEN] 
    assert {status, resp} == {:error, @error_401}

    # [WHEN] Machine id is bad
    {status, resp} = Fluidstack.list_instance(@valid_key, @valid_token, @invalid_id)
    # [THEN] 
    assert {status, resp} == {:error, "Could not find instance with id: #{@invalid_id}."}
  end

  @tag :pricing_valid
  test "Instance Pricing Valid" do

    # [WHEN] 
    {status, resp} = Fluidstack.instance_pricing(@valid_key, @valid_token)
    
    # [THEN] At least the valid_id should have a price map..
    assert status == :ok
    assert Map.has_key?(resp, @valid_id) == true

  end
  
  @tag :pricing_invalid
  test "Instance Pricing Invalid" do
    
    # [WHEN] Credentials are bad
    {status, resp} = Fluidstack.instance_pricing(@invalid_key, @invalid_token)
    
    # [THEN] 
    assert {status, resp} == {:error, @error_401}

  end
  
  @tag :instance_logs_valid
  test "Instance Logs Valid" do

    # [WHEN] 
    {status, resp} = Fluidstack.instance_logs(@valid_key, @valid_token)
    
    # [THEN] At least one instance logs map should be returned.
    assert status == :ok
    assert Enum.count(resp) > 0

    # [WHEN] Individual logs
    {status, resp} = Fluidstack.instance_logs(@valid_key, @valid_token, @valid_id)
    
    # [THEN] At least one instance logs map should be returned.
    assert status == :ok
    assert Enum.count(resp) > 0
  end
  
  @tag :instance_logs_invalid
  test "Instance Logs Invalid" do
    
    # ALL LOGS
    # [WHEN] Credentials are bad
    {status, resp} = Fluidstack.instance_logs(@invalid_key, @invalid_token)
    # [THEN] 
    assert {status, resp} == {:error, @error_401}

    # INDIVIDUAL LOGS
    # [WHEN] Credentials are bad
    {status, resp} = Fluidstack.instance_logs(@invalid_key, @invalid_token, @valid_id)
    # [THEN] 
    assert {status, resp} == {:error, @error_401}
    # [WHEN] Id does not exist
    {status, resp} = Fluidstack.instance_logs(@valid_key, @valid_token, @invalid_id)
    # [THEN] 
    assert {status, resp} == {:ok, []}
  end
  
  @tag :setup
  test "Setup" do
    assert {@valid_key, @valid_token, @valid_id} == Fluidstack.setup()
  end
end
