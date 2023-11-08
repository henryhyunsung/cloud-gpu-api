defmodule Datacrunch.Test do
  use ExUnit.Case
  import Datacrunch
  doctest Datacrunch.ApiWrapper
  use Tesla


  @invalid_id "5f8536a3-9976-4e25-99ea-e6404a1efea0"
  @valid_id ""
  @deleted_id "22662024-ab9f-4e5a-83cf-c7353d08aa08"

  @tag :invalid_id
  test "using a bad id always fails" do
    # setup: keep a record of the real API key, replace it by a mock
    real_id = System.get_env("DATACRUNCH_ID")
    System.put_env("DATACRUNCH_ID", "Dummy")
    # requests
    assert Datacrunch.fetch_access_token ==
      {:error, "Unauthorized [401] -- Access token is missing or invalid. -> Code: unauthorized_request Message: Invalid client id or client secret"}
    # teardown: restore the real API key
    System.put_env("DATACRUNCH_ID", real_id)
  end

  @tag :invalid_secret
  test "using a bad secret always fails" do
    # setup: keep a record of the real API key, replace it by a mock
    real_secret = System.get_env("DATACRUNCH_SECRET")
    System.put_env("DATACRUNCH_SECRET", "Dummy")
    # requests
    assert Datacrunch.fetch_access_token ==
      {:error, "Unauthorized [401] -- Access token is missing or invalid. -> Code: unauthorized_request Message: Invalid client id or client secret"}
    # teardown: restore the real API key
    System.put_env("DATACRUNCH_SECRET", real_secret)
  end

  @tag :invalid_sshkey
  test "using a bad sshkey fails " do
    # setup: keep a record of the real API key, replace it by a mock
    real_ssh = System.get_env("DATACRUNCH_SSHKEY")
    System.put_env("DATACRUNCH_SSHKEY", "8da1a453-77bd-498f-819b-1095c1008d12")
    Datacrunch.fetch_access_token

    location_code = "FIN-01"
    image = "ubuntu-20.04"
    instance_type = "CPU.4V.16G"
    hostname = "testinstance"
    {status, content} = create_instance(instance_type, image, location_code, hostname)

    assert status == :error
    assert content == "Bad Request [400] -- One or more of the inputs were invalid. -> Code: invalid_request Message: Invalid SSH keys"

    # teardown: restore the real API key
    System.put_env("DATACRUNCH_SSHKEY", real_ssh)
  end

  @tag :invalid_access_token
  test "invalid access token" do
    System.put_env("DATACRUNCH_AUTHTOKEN", "dummy")

    assert Datacrunch.get_instance_list ==
      {:error, "Unauthorized [401] -- Access token is missing or invalid. -> Code: unauthorized_request Message: Access token is missing or invalid"}
    assert Datacrunch.delete_instance(@valid_id) ==
      {:error, "Unauthorized [401] -- Access token is missing or invalid. -> Code: unauthorized_request Message: Access token is missing or invalid"}
    assert Datacrunch.start_instance(@valid_id) ==
      {:error, "Unauthorized [401] -- Access token is missing or invalid. -> Code: unauthorized_request Message: Access token is missing or invalid"}
    assert Datacrunch.stop_instance(@valid_id) ==
      {:error, "Unauthorized [401] -- Access token is missing or invalid. -> Code: unauthorized_request Message: Access token is missing or invalid"}
    assert Datacrunch.get_instance_by_id(@valid_id) ==
      {:error, "Unauthorized [401] -- Access token is missing or invalid. -> Code: unauthorized_request Message: Access token is missing or invalid"}
    assert Datacrunch.get_pricing_information(@valid_id) ==
      {:error, "Unauthorized [401] -- Access token is missing or invalid. -> Code: unauthorized_request Message: Access token is missing or invalid"}
    assert Datacrunch.get_groups ==
      {:error, "Unauthorized [401] -- Access token is missing or invalid. -> Code: unauthorized_request Message: Access token is missing or invalid"}
    assert Datacrunch.get_images ==
      {:error, "Unauthorized [401] -- Access token is missing or invalid. -> Code: unauthorized_request Message: Access token is missing or invalid"}
    assert Datacrunch.check_availability ==
      {:error, "Unauthorized [401] -- Access token is missing or invalid. -> Code: unauthorized_request Message: Access token is missing or invalid"}
    assert Datacrunch.check_availability("8V100.48M") ==
      {:error, "Unauthorized [401] -- Access token is missing or invalid. -> Code: unauthorized_request Message: Access token is missing or invalid"}

    location_code = "FIN-01"
    image = "ubuntu-20.04"
    instance_type = "CPU.4V.16G"
    hostname = "testinstance"
    {status, content} = create_instance(instance_type, image, location_code, hostname)

    assert status == :error
    assert String.contains? content, "Unauthorized [401]"

    # Restore access token
    Datacrunch.fetch_access_token
  end

  #WARNING: Creating instances incur additional charges
  # @tag :create_success
  # test "create instance - valid plan/image" do
  #   Datacrunch.fetch_access_token

  #   location_code = "FIN-01"
  #   image = "ubuntu-20.04"
  #   instance_type = "CPU.4V.16G"
  #   hostname = "testinstance"
  #   {status, content} = create_instance(instance_type, image, location_code, hostname)
  #
  #   # Tear down created instance to not incur additional costs
  #   assert status == :ok
  #   instance_id = content[:instance_id]

  #   {status, content} = Datacrunch.delete_instance(instance_id)

  #   assert status == :ok
  #   String.contains? content[:message],  "Instance #{@valid_id} was successfully deleted"

  # end

  @tag :create_invalid_plan
  test "create instance - invalid plan/image" do
    location_code = "dummy"
    instance_type = "dummy"
    image = "dummy"
    {status, content} = create_instance(instance_type, image, location_code)
    assert status == :error
    assert String.contains? content, "Bad Request [400]"
  end

  # WARNING: Do not run or run last as will mess up other tests as instance is deleted
  # @tag :delete_valid_id
  # test "delete instance - valid id" do
  #   Datacrunch.fetch_access_token

  #   location_code = "FIN-01"
  #   image = "ubuntu-20.04"
  #   instance_type = "CPU.4V.16G"
  #   hostname = "testinstance"
  #   {status, content} = create_instance(instance_type, image, location_code, hostname)

  #   assert status == :ok
  #   instance_id = content[:instance_id]

  #   {status, content} = Datacrunch.delete_instance(instance_id)

  #   assert status == :ok
  #   String.contains? content[:message],  "Instance #{@valid_id} was successfully deleted"
  # end

  @tag :delete_invalid_id
  test "delete instance - invalid id" do
    Datacrunch.fetch_access_token
    {status, content} = Datacrunch.delete_instance(@invalid_id)

    assert status == :error
    assert String.contains? content, "Not Found [404]"
  end

  @tag :delete_deleted
  test "delete instance - recenently deleted id" do
    Datacrunch.fetch_access_token
    {status, content} = Datacrunch.delete_instance(@deleted_id)

    assert status == :error
    assert String.contains? content, "Forbidden [403]"

  end

  @tag :start_instance_invalid_id
  test "start instance - invalid id" do
    Datacrunch.fetch_access_token
    {status, content} = Datacrunch.delete_instance(@invalid_id)

    assert status == :error
    assert String.contains? content, "Not Found [404]"
  end

  @tag :start_instance_deleted
  test "start instance - deleted id" do
    Datacrunch.fetch_access_token
    {status, content} = Datacrunch.delete_instance(@deleted_id)

    assert status == :error
    assert String.contains? content, "Forbidden [403]"
  end

  @tag timeout: :infinity
  @tag :start_instance
  test "start instance" do
    Datacrunch.fetch_access_token
    # make sure instance is stopped
    Datacrunch.stop_instance(@valid_id)

    {status, content} = Datacrunch.start_instance(@valid_id)

    assert status == :ok
    assert content[:message] == "Started instance #{@valid_id}"

    {status, content} = Datacrunch.start_instance(@valid_id)

    # Start instance that is already started doesn't return error
    assert status == :ok
    assert content[:message] == "Started instance #{@valid_id}"
  end

  @tag :stop_instance_invalid_id
  test "stop instance - invalid id" do
    Datacrunch.fetch_access_token
    {status, content} = Datacrunch.delete_instance(@invalid_id)

    assert status == :error
    assert String.contains? content, "Not Found [404]"
  end

  @tag :stop_instance_deleted
  test "stop instance - deleted id" do
    Datacrunch.fetch_access_token
    {status, content} = Datacrunch.delete_instance(@deleted_id)

    assert status == :error
    assert String.contains? content, "Forbidden [403]"
  end

  @tag timeout: :infinity
  @tag :stop_instance
  test "stop instance" do
    Datacrunch.fetch_access_token
    # make sure instance is started
    Datacrunch.start_instance(@valid_id)

    {status, content} = Datacrunch.stop_instance(@valid_id)
    assert status == :ok
    assert content[:message] == "Stopped instance #{@valid_id}"

    {status, content} = Datacrunch.stop_instance(@valid_id)

    # stop instance that is already stoped doesn't return error
    assert status == :ok
    assert content[:message] == "Stopped instance #{@valid_id}"
  end


  @tag :list_instances
  test "get instance list" do
    Datacrunch.fetch_access_token
    {status, content} = Datacrunch.get_instance_list()
    assert status == :ok
    assert Enum.count(content) > 0
  end


  @tag :list_instance
  test "get instance by id" do
    Datacrunch.fetch_access_token
    # list non-existing instance
    {status, content} = Datacrunch.get_instance_by_id(@invalid_id)

    assert status == :error
    assert String.contains? content, "Not Found [404]"

    #list deleted instance
    {status, content} = Datacrunch.get_instance_by_id(@deleted_id)

    assert status == :ok
    assert content[:status] == "discontinued"

    #list current instance
    {status, content} = Datacrunch.get_instance_by_id(@valid_id)

    assert status == :ok
    assert content[:instance_id] == @valid_id
  end

  @tag :pricing_valid_id
    test "get pricing - valid id" do
      Datacrunch.fetch_access_token
      {status, content} = Datacrunch.get_pricing_information(@valid_id)

      assert status == :ok
      assert content > 0
    end

    @tag :pricing_invalid_id
    test "get pricing - invalid id" do
      Datacrunch.fetch_access_token
      {status, content} = Datacrunch.get_pricing_information(@invalid_id)

      assert status == :error
      assert String.contains? content, "Not Found [404]"
    end

    @tag :get_groups
    test "instance groups" do
      Datacrunch.fetch_access_token

      {status, content} = Datacrunch.get_groups
      assert status == :ok
      assert Enum.count(content[:spot_instances]) > 0 or Enum.count(content[:on_demand_instances]) > 0
    end

    @tag :get_instances_types
    test "list instance types" do
      Datacrunch.fetch_access_token

      {status, content} = Datacrunch.get_instances_types
      assert status == :ok
      assert Enum.count(content[:instances]) > 0
    end

    @tag :get_images
    test "list images" do
      Datacrunch.fetch_access_token

      {status, content} = Datacrunch.get_images
      assert status == :ok
      assert Enum.count(content[:images]) > 0
    end

    @tag :check_all_availiabilities
    test "availiabilities" do
      Datacrunch.fetch_access_token

      {status, content} = Datacrunch.check_availability
      assert status == :ok
      assert Enum.count(content[:availabilities]) > 0
    end

    @tag :check_singular_availiabilities_valid
    test "singular availiability" do
      Datacrunch.fetch_access_token

      {status, content} = Datacrunch.check_availability
      assert status == :ok

      #get currently available plan
      location = Enum.at(content[:availabilities], 0)
      plan_list = location["availabilities"]
      plan = Enum.at(plan_list, 0)

      {status, content} = Datacrunch.check_availability(plan)
      assert status == :ok
      assert content[:availabilities] == "true"
    end

    @tag :check_singular_availiabilities_invalid
    test "singular availiability - invalid" do
      Datacrunch.fetch_access_token

      {status, content} = Datacrunch.check_availability("8100.48M")
      assert status == :error
      assert String.contains? content, "Bad Request [400]"
    end

    #WARNING: DO NOT RUN UNLESS READY TO INCUR COSTS
  #   @tag timeout: :infinity
  #   @tag :end_to_end
  #   test "full proccess" do
  #     Datacrunch.fetch_access_token

  #     {status, content} = Datacrunch.get_instance_list

  #     assert status == :ok

  #     # Store num of instances
  #     num_instances = Enum.count(content)


  #     {status, content} = Datacrunch.get_groups
  #     assert status == :ok
  #     num_spot_instances = Enum.count(content[:spot_instances])
  #     num_on_demand_instances = Enum.count(content[:on_demand_instances])

  #     location_code = "FIN-01"
  #     image = "ubuntu-20.04"
  #     instance_type = "CPU.4V.16G"
  #     hostname = "testinstance"
  #     {status, content} = Datacrunch.create_instance(instance_type, image, location_code, hostname)

  #     assert status == :ok
  #     instance_id = content[:instance_id]

  #     {status, content} = Datacrunch.stop_instance(instance_id)

  #     assert status == :ok
  #     assert content[:message] == "Stopped instance #{instance_id}"

  #     {status, content} = Datacrunch.start_instance(instance_id)

  #     assert status == :ok
  #     assert content[:message] == "Started instance #{instance_id}"

  #     {status, content} = Datacrunch.get_instance_list

  #     assert status == :ok
  #     assert Enum.count(content) == num_instances + 1

  #     {status, content} = Datacrunch.get_instance_by_id(instance_id)

  #     assert status == :ok
  #     assert content[:instance_id] == instance_id
  #     assert content[:status] == "running"

  #     {status, content} = Datacrunch.get_pricing_information(instance_id)

  #     assert status == :ok
  #     assert content[:price_per_hour] == 0.1
  #     assert content[:total_price] == 0.1

  #     {status, content} = Datacrunch.get_groups
  #     assert status == :ok
  #     assert Enum.count(content[:spot_instances]) == num_spot_instances
  #     assert Enum.count(content[:on_demand_instances]) == num_on_demand_instances + 1

  #     {status, content} = Datacrunch.delete_instance(instance_id)
  #     assert status == :ok
  #     assert content[:message] ==  "Instance #{instance_id} was successfully deleted"

  #     {status, content} = Datacrunch.get_instance_by_id(instance_id)

  #     assert status == :ok
  #     assert content[:instance_id] == instance_id
  #     assert content[:status] == "discontinued"

  #     {status, content} = Datacrunch.get_instance_list

  #     assert status == :ok
  #     assert Enum.count(content) == num_instances

  #     {status, content} = Datacrunch.get_groups
  #     assert status == :ok
  #     assert Enum.count(content[:spot_instances]) == num_spot_instances
  #     assert Enum.count(content[:on_demand_instances]) == num_on_demand_instances
  # end



end
