defmodule PaperspaceTest do
  use ExUnit.Case
  doctest Paperspace

  # Helper method to get number of days in this month. Used for expected
  #  billing rates
  defp nbdays do
    current_dt = DateTime.utc_now()
    :calendar.last_day_of_the_month(current_dt.year, current_dt.month)
  end


  # Machine types for testing
  defp get_existing_machine_id, do: "ps0n56zmm"
  defp get_deleted_machine_id, do: "psfruq0ng"
  defp get_invalid_machine_id, do: "helloworld"
  defp get_cpu_machine_id, do: "psnsgidao"
  defp get_gpu_machine_id, do: "psfruq0ng"
  defp get_cpu_machine_rate, do: 0.009 + 5 / (nbdays() * 24) # hourly machine + monthly storage
  defp get_gpu_machine_rate, do: 0.45 + 7 / (nbdays() * 24) # hourly machine + monthly storage

  # Helper to fetch API key
  defp get_api_key(), do: System.get_env("PAPERSPACE_APIKEY")

  # Possible errors and their descriptions can be found in the
  #  paperspace docs: https://docs-next.paperspace.com/web-api/overview
  # Those messages commented out are currently not tested for
  # @generic_msg_400 "PARSE_ERROR [400] -- The request was unacceptable, often due to missing a required parameter or incorrect method."
  # @generic_msg_401 "UNAUTHORIZED [401] -- The API key was invalid or expired."
  # @generic_msg_403 "FORBIDDEN [403] -- The API key doesn't have permissions to perform the request."
  # @generic_msg_404 "NOT_FOUND [404] -- The requested resource doesn't exist."
  # @generic_msg_405 "METHOD_NOT_SUPPORTED [405] -- The requested method is not supported for the requested resource."
  # @generic_msg_408 "TIMEOUT [408] -- The request took too long."
  # @generic_msg_409 "CONFLICT [409] -- The request conflicts with another request."
  # @generic_msg_412 "PRECONDITION_FAILED [412] -- The client did not meet one of the request's requirements."
  # @generic_msg_413 "PAYLOAD_TOO_LARGE [413] -- The request is larger than the server is willing or able to process."
  # @generic_msg_429 "TOO_MANY_REQUESTS [429] -- Too many requests hit the API too quickly. We recommend an exponential backoff of your requests."
  # @generic_msg_499 "CLIENT_CLOSED_REQUEST [499] -- The client closed the request before the server could respond."
  # @generic_msg_500 "INTERNAL_SERVER_ERROR [500] - Something went wrong on Paperspace's end."



  # fetch_account_identifier tests
  test "fetch_account_identifier: Correct API key" do
    # [Given]
    api_key = get_api_key()

    # [When]
    {status, _content} = Paperspace.fetch_account_identifier(api_key)

    # [Then]
    assert status == :ok
    # TODO: Check content
    # IO.inspect(content)
  end

  test "fetch_account_identifier: Invalid API key" do
    # [Given]
    api_key = "abcd"

    # [When]
    {status, content} = Paperspace.fetch_account_identifier(api_key)

    # [Then]
    assert status == :error
    assert content == "Invalid API key"
  end

  # list_machines tests
  test "list_machines: All machines" do
    # [Given]
    api_key = get_api_key()

    # [When]
    {status, _content} = Paperspace.list_machines(api_key)

    # [Then]
    assert status == :ok
    # TODO: Test content
  end



  # list_machine tests
  test "list_machine: Existing machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_existing_machine_id()

    # [When]
    {status, content} = Paperspace.list_machine(api_key, machine_id)

    # [Then]
    assert status == :ok
    assert content[:instance_id] == machine_id
  end

  test "list_machine: Deleted machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_deleted_machine_id()

    # [When]
    {status, content} = Paperspace.list_machine(api_key, machine_id)

    # [Then]
    assert status == :ok
    assert content[:instance_id] == machine_id
  end

  test "list_machine: Invalid machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_invalid_machine_id()

    # [When]
    {status, content} = Paperspace.list_machine(api_key, machine_id)

    # [Then]
    assert status == :error
    assert content == "Machine not found"
  end



  # start_machine, stop_machine, delete_machine tests.
  test "start: Deleted machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_deleted_machine_id()

    # [When] Trying to start a deleted machine
    {status, content} = Paperspace.start_machine(api_key, machine_id)

    # [Then] We should see some error
    assert status == :error
    assert content == "Failed to start instance #{machine_id} for vendor Paperspace: Machine is deleted."
  end

  test "start: Invalid machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_invalid_machine_id()

    # [When] Trying to start an invalid machine
    {status, content} = Paperspace.start_machine(api_key, machine_id)

    # [Then] We should see some error
    assert status == :error
    assert content == "Failed to start instance #{machine_id} for vendor Paperspace: Not found. Please contact support@paperspace.com for help."
  end

  test "stop: Deleted machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_deleted_machine_id()

    # [When] Trying to stop a deleted machine
    {status, content} = Paperspace.stop_machine(api_key, machine_id)

    # [Then] We should see some error
    assert status == :error
    assert content == "Failed to stop instance #{machine_id} for vendor Paperspace: Machine is deleted."
  end

  test "stop: Invalid machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_invalid_machine_id()

    # [When] Trying to stop an invalid machine
    {status, content} = Paperspace.stop_machine(api_key, machine_id)

    # [Then] We should see some error
    assert status == :error
    assert content == "Failed to stop instance #{machine_id} for vendor Paperspace: Not found. Please contact support@paperspace.com for help."
  end

  test "delete: Deleted machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_deleted_machine_id()

    # [When] Trying to delete a deleted machine
    {status, content} = Paperspace.delete_machine(api_key, machine_id)

    # [Then] We should see a success, as it was a machine that existed
    assert status == :ok
    assert content[:message] == "deleted Paperspace instance: #{machine_id}"
  end

  test "delete: Invalid machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_invalid_machine_id()

    # [When] Trying to delete a deleted machine
    {status, content} = Paperspace.delete_machine(api_key, machine_id)

    # [Then] We should see a success, as it was a machine that existed
    assert status == :error
    assert content == "Failed to delete instance #{machine_id} for vendor Paperspace: No such account found"
  end

 # This test can be skipped by running `mix test --exclude disabled`
  @tag disabled: true
  @tag timeout: :infinity # Test can take a long time
  test "start/stop: Full integration test" do
    IO.puts("\nRunning start/stop full integration test")

    # [Given]
    api_key = get_api_key()
    machine_id = get_existing_machine_id()
    # And a currently off machine
    {list_status, list_content} = Paperspace.list_machine(api_key, machine_id)
    assert list_status == :ok
    assert(
      list_content[:status] == :Stopped,
      "Check machine '#{list_content[:name]}' (#{machine_id}) is stopped on Paperspace console")


    # [When] Trying to stop a stopped machine
    {stop_status, stop_content} = Paperspace.stop_machine(api_key, machine_id)
    # [Then] We should get some sort of error
    assert stop_status == :error
    assert stop_content == "Failed to stop instance #{machine_id} for vendor Paperspace: Machine is not in a power state compatible with this request."


    # [When] Trying to start a stopped machine, and listing it
    IO.puts("Starting machine #{machine_id}, may take a minute...")
    {start_status, start_content} = Paperspace.start_machine(api_key, machine_id)
    {list_status, list_content} = Paperspace.list_machine(api_key, machine_id)
    # [Then] we should get a success message, and evidence that the
    #  request blocked until started
    assert start_status == :ok
    assert start_content[:message] == "started Paperspace instance #{machine_id}"
    assert list_status == :ok
    assert list_content[:status] == :Running


    # [When] Trying to start a started machine
    {start_status, start_content} = Paperspace.start_machine(api_key, machine_id)
    # [Then] We should get some sort of error
    assert start_status == :error
    assert start_content == "Failed to start instance #{machine_id} for vendor Paperspace: Machine is not in a power state compatible with this request."


    # [When] Trying to stop a started machine
    IO.puts("Stopping machine #{machine_id}, may take a minute...")
    {stop_status, stop_content} = Paperspace.stop_machine(api_key, machine_id)
    {list_status, list_content} = Paperspace.list_machine(api_key, machine_id)
    # [Then] we should get a success message, and evidence that the
    #  request blocked until stopped
    assert stop_status == :ok
    assert stop_content[:message] == "stopped Paperspace instance #{machine_id}"
    assert list_status == :ok
    assert list_content[:status] == :Stopped
  end



  # fetch_pricing_info tests
  test "fetch_pricing_info: Existing CPU machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_cpu_machine_id()
    expected_rate = get_cpu_machine_rate()

    # [When]
    {status, content} = Paperspace.fetch_pricing_info(api_key, machine_id)

    # [Then]
    assert status == :ok
    assert content[machine_id][:net_cost_spot] == nil
    assert content[machine_id][:net_cost_on_demand] == expected_rate
  end

  test "fetch_pricing_info: Deleted GPU machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_gpu_machine_id()
    expected_rate = get_gpu_machine_rate()

    # [When]
    {status, content} = Paperspace.fetch_pricing_info(api_key, machine_id)

    # [Then]
    assert status == :ok
    assert content[machine_id][:net_cost_spot] == nil
    assert content[machine_id][:net_cost_on_demand] == expected_rate
  end

  test "fetch_pricing_info: Invalid machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_invalid_machine_id()

    # [When]
    {status, content} = Paperspace.fetch_pricing_info(api_key, machine_id)

    # [Then]
    assert status == :error
    assert content == "Machine not found"
  end



  # fetch_audit_log tests
  test "fetch_audit_log: Existing machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_existing_machine_id()

    # [When]
    {status, _content} = Paperspace.fetch_audit_log(api_key, machine_id)

    # [Then]
    assert status == :ok
    # TODO: Test content
    # IO.inspect(content)
  end

  test "fetch_audit_log: Deleted machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_deleted_machine_id()

    # [When]
    {status, _content} = Paperspace.fetch_audit_log(api_key, machine_id)

    # [Then]
    assert status == :ok
    # TODO: Test content
    # IO.inspect(content)
  end

  test "fetch_audit_log: Invalid machine" do
    # [Given]
    api_key = get_api_key()
    machine_id = get_invalid_machine_id()

    # [When]
    {status, content} = Paperspace.fetch_audit_log(api_key, machine_id)

    # [Then]
    assert status == :error
    assert content == "Machine not found"
  end
end
