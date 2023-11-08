defmodule LiveTest do
  use ExUnit.Case

  doctest LatitudeSh

  @unavailable_server_msg "Validation Error [422] -- This plan-site combination is unavailable."
  @deleted_server_msg "Deleted successfully."

  setup_all do
    num_servers = LatitudeSh.list_servers |> elem(1) |> length
    valid_project_id = (LatitudeSh.fetch_projects |> elem(1) |> hd)[:id]
    {:ok, num_servers: num_servers, valid_project_id: valid_project_id}
  end

  test "using a bad token always fails" do
    # setup: keep a record of the real API key, replace it by a mock
    real_api_key = System.get_env("LATITUDESH_APIKEY")
    System.put_env("LATITUDESH_APIKEY", "bad API key")
    # requests
    assert LatitudeSh.fetch_access_token ==
      {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."}
    assert LatitudeSh.fetch_account_identifier ==
      {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."}
    assert LatitudeSh.list_servers ==
      {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."}
    assert LatitudeSh.list_server("1") ==
      {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."}
    assert LatitudeSh.fetch_projects ==
      {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."}
    assert LatitudeSh.create_server("1", "stub", "c2-small-x86", "SYD") ==
      {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."}
    assert LatitudeSh.start_server("1")
      {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."}
    assert LatitudeSh.stop_server("1")
      {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."}
    assert LatitudeSh.delete_server("1") ==
      {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."}
    assert LatitudeSh.fetch_pricing_info("1") ==
      {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."}
    assert LatitudeSh.fetch_audit_log("1") ==
      {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."}
    # teardown: restore the real API key
    System.put_env("LATITUDESH_APIKEY", real_api_key)
  end

  test "creating an unavailable server fails", context do
    case LatitudeSh.fetch_one_plan_by_availability(false) do
      {:ok, %{plan: plan, site: site, pricing: _prices}} ->
        assert LatitudeSh.create_server(context[:valid_project_id], "not_created", plan, site) == {:error, @unavailable_server_msg}
        :timer.sleep(1000)
        assert LatitudeSh.list_servers |> elem(1) |> length == context[:num_servers]
      %{error: _} -> assert true
    end
  end

  test "creating and deleting an available server succeeds", context do
    case LatitudeSh.fetch_one_plan_by_availability(true) do
      {:ok, %{plan: plan, site: site, pricing: _prices}} ->
        {:ok, created} = LatitudeSh.create_server(context[:valid_project_id], "created", plan, site)
        :timer.sleep(1000)
        assert LatitudeSh.list_servers |> elem(1) |> length == context[:num_servers] + 1
        :timer.sleep(1000)
        assert LatitudeSh.delete_server(created[:request_id]) == {:ok, %{request_id: nil, message: @deleted_server_msg}}
        :timer.sleep(1000)
        assert LatitudeSh.list_servers |> elem(1) |> length == context[:num_servers]
      {:error, _} -> assert true
    end
  end

end
