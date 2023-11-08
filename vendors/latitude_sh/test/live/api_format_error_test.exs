defmodule ApiFormatErrorTest do
  use ExUnit.Case
  use Mimic

  setup_all do
    bad_200_format = %Tesla.Env{status: 200, body: Jason.encode!(%{"bad" => "format"})}
    bad_201_format = %Tesla.Env{status: 201, body: Jason.encode!(%{"bad" => "format"})}
    bad_list_hd = %Tesla.Env{status: 200, body: Jason.encode!(%{"data" => [%{"bad" => "format"}]})}
    bad_fetch_plans_hd = %Tesla.Env{status: 200, body: Jason.encode!(%{"data" => [%{"attributes" => %{"bad" => "format"}}]})}

    {
      :ok,
      bad_200_format: bad_200_format,
      bad_201_format: bad_201_format,
      bad_list_hd: bad_list_hd,
      bad_fetch_plans_hd: bad_fetch_plans_hd
    }
  end

  test "Testing fetch_access_token format error", context do
    LatitudeSh.ApiWrappers
    |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:bad_200_format]} end)
    assert match?({:error, "/auth/current_version response format has changed; see the full body in logs."}, LatitudeSh.fetch_access_token)
  end

  test "Testing fetch_account_identifier format error", context do
    LatitudeSh.ApiWrappers
    |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:bad_200_format]} end)
    assert match?({:error, "/user/profile response format has changed; see the full body in logs."}, LatitudeSh.fetch_account_identifier)
  end

  test "Testing list_servers format error - high level", context do
    LatitudeSh.ApiWrappers
    |> Mimic.expect(:get_wrapper, 1, fn _url, _params -> {:ok, context[:bad_200_format]} end)
    assert match?({:error, "/servers response format has changed; see the full body in logs."}, LatitudeSh.list_servers)
  end

  test "Testing list_servers format error - individual server", context do
    LatitudeSh.ApiWrappers
    |> Mimic.expect(:get_wrapper, 1, fn _url, _params -> {:ok, context[:bad_list_hd]} end)
    assert match?({:error, "/servers response format has changed; see the full body in logs."}, LatitudeSh.list_servers)
  end

  test "Testing list_server format error - high level", context do
    LatitudeSh.ApiWrappers
    |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:bad_200_format]} end)
    assert match?({:error, "/servers/{server_id} response format has changed; see the full body in logs."}, LatitudeSh.list_server(18_912))
  end

  test "Testing fetch_plans format error - high level", context do
    LatitudeSh.ApiWrappers
    |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:bad_200_format]} end)
    assert match?({:error, "/plans response format has changed; see the full body in logs."}, LatitudeSh.fetch_plans_by_availability(true))
  end

  test "Testing fetch_plans format error - individual plans", context do
    LatitudeSh.ApiWrappers
    |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:bad_list_hd]} end)
    assert match?({:error, "/plans (individual) response format has changed; see the full body in logs."}, LatitudeSh.fetch_plans_by_availability(true))
  end

  test "Testing fetch_plans format error - details", context do
    LatitudeSh.ApiWrappers
    |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:bad_fetch_plans_hd]} end)
    assert match?({:error, "/plans response format has changed; see the full body in logs."}, LatitudeSh.fetch_plans_by_availability(true))
  end

end
