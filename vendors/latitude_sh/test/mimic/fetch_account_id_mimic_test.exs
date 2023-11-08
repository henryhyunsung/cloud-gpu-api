defmodule FetchAccountIdMimicTest do
  use ExUnit.Case
  use Mimic

  setup_all do
    success = %Tesla.Env{
      method: :get,
      url: "https://api.latitude.sh/user/profile",
      query: [],
      headers: [
        {"cache-control", "max-age=0, private, must-revalidate"},
        {"connection", "keep-alive"},
        {"date", "Fri, 01 Sep 2023 14:07:20 GMT"},
        {"etag", "W/\"985499a85d4101e6f7706ff9351d803f\""},
        {"server", "cloudflare"},
        {"vary", "Origin"},
        {"content-length", "746"},
        {"content-type", "application/vnd.api+json; charset=utf-8"},
        {"status", "200 OK"},
        {"strict-transport-security", "max-age=63072000; includeSubDomains"},
        {"referrer-policy", "strict-origin-when-cross-origin"},
        {"x-permitted-cross-domain-policies", "none"},
        {"x-xss-protection", "1; mode=block"},
        {"x-request-id", "61b91aa7-8c3a-4e08-8215-8cf95eb21d0f"},
        {"x-download-options", "noopen"},
        {"x-frame-options", "SAMEORIGIN"},
        {"x-runtime", "0.020920"},
        {"x-content-type-options", "nosniff"},
        {"x-powered-by", "cloud66"},
        {"x-powered-by", "cloud66"},
        {"cf-cache-status", "DYNAMIC"},
        {"report-to",
         "{\"endpoints\":[{\"url\":\"https:\\/\\/a.nel.cloudflare.com\\/report\\/v3?s=mzB3u5%2B8TpzxcLtwtOJg%2Bg%2FnyEZh%2BI7Web8SDzpsyQcBggrK%2Fr%2BFzSkhHswH9vkCbeRia6zIS%2FCu5kJx26lt69ZXsgGh4%2FS66yDHMCuI7WhHCAI1Ug3V3NVHr6ACsqzqUQ%3D%3D\"}],\"group\":\"cf-nel\",\"max_age\":604800}"},
        {"nel",
         "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}"},
        {"cf-ray", "7ffe14357d21a7f9-SYD"}
      ],
      body: "{\"data\":{\"id\":\"40558049-7011-4e4a-a01c-74d97ebb5dfd\",\"type\":\"users\",\"attributes\":{\"first_name\":\"USYD\",\"last_name\":\"06\",\"email\":\"usyd06capstone@gmail.com\",\"authentication_factor_id\":\"\",\"created_at\":\"2023-08-19T00:12:54+00:00\",\"updated_at\":\"2023-08-19T11:28:31+00:00\",\"role\":{\"id\":\"role_VyV9MYdZqdhoE1dwmxdJsM49Z9D\",\"name\":\"owner\",\"created_at\":\"2023-08-19T00:13:51.245Z\",\"updated_at\":\"2023-08-19T00:13:51.245Z\"},\"teams\":[{\"id\":\"2f18dfbb-5f3d-45c8-8bcb-6d17ee215548\",\"name\":\"Strong Compute, Research team\",\"slug\":\"strong-compute-research-team\",\"description\":\"\",\"address\":null,\"currency\":{\"id\":1,\"code\":\"USD\",\"name\":\"United States Dollar\"},\"status\":\"verified\",\"hourly_billing\":true}]},\"relationships\":{\"teams\":{\"meta\":{\"included\":false}}}},\"meta\":{}}",
      status: 200,
      opts: [],
      __module__: LatitudeSh.ApiWrappers,
      __client__: %Tesla.Client{fun: nil, pre: [], post: [], adapter: nil}
    }

    bad_request_error = %Tesla.Env{
      method: nil,
      url: "",
      query: [],
      headers: [],
      body: "",
      status: 400,
      opts: [],
      __module__: LatitudeSh.ApiWrappers,
      __client__: %Tesla.Client{fun: nil, pre: [], post: [], adapter: nil}
    }

    unauthorized_error = %Tesla.Env{
      method: nil,
      url: "",
      query: [],
      headers: [],
      body: "",
      status: 401,
      opts: [],
      __module__: LatitudeSh.ApiWrappers,
      __client__: %Tesla.Client{fun: nil, pre: [], post: [], adapter: nil}
    }

    forbidden_error = %Tesla.Env{
      method: nil,
      url: "",
      query: [],
      headers: [],
      body: "",
      status: 403,
      opts: [],
      __module__: LatitudeSh.ApiWrappers,
      __client__: %Tesla.Client{fun: nil, pre: [], post: [], adapter: nil}
    }

    not_found_error = %Tesla.Env{
      method: nil,
      url: "",
      query: [],
      headers: [],
      body: "",
      status: 404,
      opts: [],
      __module__: LatitudeSh.ApiWrappers,
      __client__: %Tesla.Client{fun: nil, pre: [], post: [], adapter: nil}
    }

    unprocessable_entity_error = %Tesla.Env{
      method: nil,
      url: "",
      query: [],
      headers: [],
      body: "",
      status: 422,
      opts: [],
      __module__: LatitudeSh.ApiWrappers,
      __client__: %Tesla.Client{fun: nil, pre: [], post: [], adapter: nil}
    }

    too_many_requests_error = %Tesla.Env{
      method: nil,
      url: "",
      query: [],
      headers: [],
      body: "",
      status: 429,
      opts: [],
      __module__: LatitudeSh.ApiWrappers,
      __client__: %Tesla.Client{fun: nil, pre: [], post: [], adapter: nil}
    }

    server_error_error = %Tesla.Env{
      method: nil,
      url: "",
      query: [],
      headers: [],
      body: "",
      status: 500,
      opts: [],
      __module__: LatitudeSh.ApiWrappers,
      __client__: %Tesla.Client{fun: nil, pre: [], post: [], adapter: nil}
    }

    {
      :ok,
      success: success,
      bad_request_error: bad_request_error,
      unauthorized_error: unauthorized_error,
      forbidden_error: forbidden_error,
      not_found_error: not_found_error,
      unprocessable_entity_error: unprocessable_entity_error,
      too_many_requests_error: too_many_requests_error,
      server_error_error: server_error_error
    }
  end

  test "Testing successful fetch_account_identifier call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:success]} end)
    assert {:ok, %{user_id: "40558049-7011-4e4a-a01c-74d97ebb5dfd"}} == LatitudeSh.fetch_account_identifier
  end

  test "Testing 400 error for fetch_account_identifier call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:bad_request_error]} end)
    assert {:error, "Bad Request [400] -- General client error, possible malformed data."} == LatitudeSh.fetch_account_identifier
  end

  test "Testing 401 error for fetch_account_identifier call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:unauthorized_error]} end)
    assert {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."} == LatitudeSh.fetch_account_identifier
  end

  test "Testing 403 error for fetch_account_identifier call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:forbidden_error]} end)
    assert {:error, "Forbidden [403] -- The request is not allowed."} == LatitudeSh.fetch_account_identifier
  end

  test "Testing 404 error for fetch_account_identifier call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:not_found_error]} end)
    assert {:error, "Not Found [404] -- The resource was not found."} == LatitudeSh.fetch_account_identifier
  end

  test "Testing 422 error for fetch_account_identifier call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:unprocessable_entity_error]} end)
    assert {:error, "Unprocessable Entity [422] -- The data was well-formed but invalid."} == LatitudeSh.fetch_account_identifier
  end

  test "Testing 429 error for fetch_account_identifier call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:too_many_requests_error]} end)
    assert {:error, "Too Many Requests [429] -- The client has reached or exceeded a rate limit, or the server is overloaded."} == LatitudeSh.fetch_account_identifier
  end

  test "Testing 500 error for fetch_account_identifier call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:server_error_error]} end)
    assert {:error, "Server Error [500] - Something went wrong on our end."} == LatitudeSh.fetch_account_identifier
  end
end
