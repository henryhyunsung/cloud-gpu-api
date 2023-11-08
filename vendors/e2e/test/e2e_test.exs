defmodule E2E.Test do
  use ExUnit.Case
  doctest E2E.API

  @valid_id 143069 #hardcoded of test node if deleted update
  @deleted_id 142954
  @invalid_id 1

  @valid_name "test"
  @invalid_name "dummy"

  # cannot match exactly since response is customised info dump
  # DO NOT RUN WITHOUT PERMISSION - creating instances incur additional charges
  # @tag :create_success
  # test "create node - valid plan/image" do
  #   name = "demo"
  #   plan = "C-4vCPU-12RAM-100DISK-C2.12GB-CentOS-7"
  #   image = "CentOS-7-Distro"
  #   response = E2E.create_node(name, plan, image)
  #   case response do
  #     {:ok, _} -> assert true
  #     _ -> assert false
  #   end
  # end

  @tag :create_invalid_plan
  test "create node - invalid plan/image" do
    name = "dummy"
    plan = "dummy"
    image = "dummy"
    response = E2E.create_node(name, plan, image)
    expected = {:error, "[400] Bad Request: Plan does not exist"}
    assert response == expected
  end

  # @tag :delete_valid_id
  # test "delete node - valid id" do
  #   response = E2E.delete_node(@valid_id)
  #   case response do
  #     {:ok, _} -> assert true
  #     _ -> assert false
  #   end
  # end

  @tag :delete_invalid_id
  test "delete node - invalid id" do
    response = E2E.delete_node(@invalid_id)
    expected = {:error, "[404] Bad Request: Node matching query does not exist."}
    assert response == expected
  end

  @tag :start_node_invalid_id
  test "start node - invalid id" do
    response = E2E.start_node(@invalid_id)
    expected = {:error, "[404] Bad Request: Node matching query does not exist."}
    assert response == expected
  end

  @tag :start_node_deleted
  test "start node - deleted id" do
    response = E2E.start_node(@deleted_id)
    expected = {:error, "[404] Bad Request: Node matching query does not exist."}

    assert response == expected
  end

  #Inconsistant due to errors with E2E networks taking too long to update their state
  @tag :start_node
  # test "start node" do
  #   # make sure node is stopped
  #   E2E.stop_node(@valid_id)

  #   Process.sleep(5000)

  #   {status, content}= E2E.start_node(@valid_id)

  #   assert status == :ok
  #   assert content["action_type"] == "power_on"

  #   Process.sleep(5000)

  #   # Start node that is already started
  #   assert {:error, "[400] Bad Request: VM already in state of action to be performed"} == E2E.start_node(@valid_id)

  # end


  #Inconsistant due to errors with E2E networks taking too long to update their state
  # @tag :stop_node
  # test "stop node" do
  #   assert {:error, "[404] Bad Request: Node matching query does not exist."} == E2E.stop_node(@invalid_id)

  #   # make sure node is stopped
  #   E2E.start_node(@valid_id)

  #   Process.sleep(5000)

  #   {status, content}= E2E.stop_node(@valid_id)

  #   assert status == :ok
  #   assert content["action_type"] == "power_off"


  #   Process.sleep(5000)

  #   # Start node that is already started
  #   assert {:error, "[400] Bad Request: VM already in state of action to be performed"} == E2E.stop_node(@valid_id)
  # end

  @tag :list_nodes
  test "get node list" do
    {status, content} = E2E.get_node_list()
    assert status == :ok

    assert Enum.count(content) > 0

  end

  @tag :list_node
  test "get node by id" do

    # list non-existing node
    {status, content} = E2E.get_node_by_id(@invalid_id)

    assert status == :error
    #list deleted node
    {status, content} = E2E.get_node_by_id(@deleted_id)
    assert status == :error

    #list current node
    {status, content} = E2E.get_node_by_id(@valid_id)

    assert status == :ok

    assert content[:instance_id] == @valid_id
  end

  @tag :pricing_valid_id
  test "get pricing - valid id" do
    response = E2E.get_pricing(@valid_id)
    case response do
      {:ok, _} -> assert true
      _ -> assert false
    end
  end

  @tag :pricing_invalid_id
  test "get pricing - invalid id" do
    response = E2E.get_pricing(@invalid_id)
    expected = {:error, "[400] Success: %{}"}
    assert response == expected
  end

  # instance name that has never been registered to the account
  @tag :auditlog_invalid_name
  test "get audit log - invalid name" do
    response = E2E.get_audit_log(@invalid_name)
    expected = {:error, "no entries found"}
    assert response == expected
  end

  @tag :auditlog_valid_name
  test "get audit log - valid name" do
    response = E2E.get_audit_log(@valid_name)
    case response do
      {:ok, _} -> assert true
      _ -> assert false
    end
  end

  @tag :customer_details
  test "customer details" do
    {status, content} = E2E.get_customer_details
    assert status == :ok
    assert is_integer(content[:customerID])
  end

  @tag :user_details
  test "user details" do
    {status, _content} = E2E.get_user_ids
    assert status == :ok
  end

  @tag :get_groups
  test "node groups" do
    {status, _content} = E2E.get_groups
    assert status == :ok
  end

  @tag :get_tags
  test "node tages" do
    {status, _content} = E2E.get_tags
    assert status == :ok
  end

  @tag :set_user
  test "set user" do
    current_val = System.get_env("E2E_USER_IDENTIFIER")
    System.put_env("E2E_USER_IDENTIFIER", "")
    {:error, "User with that name does not exist"} = E2E.set_user("INVALID NAME")
    assert System.get_env("E2E_USER_IDENTIFIER") == ""

    {status, content} = E2E.set_user("USYD BOT")

    assert is_integer(System.get_env("E2E_USER_IDENTIFIER"))
    assert String.contains? content, "Events linked to USYD BOT"

    # Tear down
    System.put_env("E2E_USER_IDENTIFIER", current_val)
  end

end
