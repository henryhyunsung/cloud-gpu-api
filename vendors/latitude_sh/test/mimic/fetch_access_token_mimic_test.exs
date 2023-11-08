defmodule FetchAccessTokenMimicTest do
  use ExUnit.Case
  use Mimic

  setup_all do
    success = %Tesla.Env{
      method: :get,
      url: "https://api.latitude.sh/auth/current_version",
      query: [],
      headers: [
        {"cache-control", "max-age=0, private, must-revalidate"},
        {"connection", "keep-alive"},
        {"date", "Fri, 01 Sep 2023 14:20:09 GMT"},
        {"etag", "W/\"4c4bee674cc696156c170e4b7abac174\""},
        {"server", "cloudflare"},
        {"vary", "Origin"},
        {"content-length", "56"},
        {"content-type", "application/vnd.api+json; charset=utf-8"},
        {"status", "200 OK"},
        {"strict-transport-security", "max-age=63072000; includeSubDomains"},
        {"referrer-policy", "strict-origin-when-cross-origin"},
        {"x-permitted-cross-domain-policies", "none"},
        {"x-xss-protection", "1; mode=block"},
        {"x-request-id", "57005344-3f2f-49bc-99fb-d1446fbaacd7"},
        {"x-download-options", "noopen"},
        {"x-frame-options", "SAMEORIGIN"},
        {"x-runtime", "0.027719"},
        {"x-content-type-options", "nosniff"},
        {"x-powered-by", "cloud66"},
        {"x-powered-by", "cloud66"},
        {"cf-cache-status", "DYNAMIC"},
        {"report-to",
         "{\"endpoints\":[{\"url\":\"https:\\/\\/a.nel.cloudflare.com\\/report\\/v3?s=3MOM898mONeouGUkvSXWwNsuV9bGcxaLYugiTicrPhuA3OvsVK15elFtyrEFB2gbm%2Fj4f7ELEiPj%2FkjdkoZJ66S1eXyYb%2BqEz3PYsGdZjKTkTE1rZU3sCcAP04hKHUVUqg%3D%3D\"}],\"group\":\"cf-nel\",\"max_age\":604800}"},
        {"nel",
         "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}"},
        {"cf-ray", "7ffe26f9ebc9a7f0-SYD"}
      ],
      body: "{\"data\":{\"attributes\":{\"current_version\":\"2022-07-18\"}}}",
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

  test "Testing successful fetch_access_token call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:success]} end)
    assert {:ok, %{token: "2022-07-18"}} == LatitudeSh.fetch_access_token
  end

  test "Testing 400 error for fetch_access_token call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:bad_request_error]} end)
    assert {:error, "Bad Request [400] -- General client error, possible malformed data."} == LatitudeSh.fetch_access_token
  end

  test "Testing 401 error for fetch_access_token call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:unauthorized_error]} end)
    assert {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."} == LatitudeSh.fetch_access_token
  end

  test "Testing 403 error for fetch_access_token call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:forbidden_error]} end)
    assert {:error, "Forbidden [403] -- The request is not allowed."} == LatitudeSh.fetch_access_token
  end

  test "Testing 404 error for fetch_access_token call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:not_found_error]} end)
    assert {:error, "Not Found [404] -- The resource was not found."} == LatitudeSh.fetch_access_token
  end

  test "Testing 422 error for fetch_access_token call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:unprocessable_entity_error]} end)
    assert {:error, "Unprocessable Entity [422] -- The data was well-formed but invalid."} == LatitudeSh.fetch_access_token
  end

  test "Testing 429 error for fetch_access_token call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:too_many_requests_error]} end)
    assert {:error, "Too Many Requests [429] -- The client has reached or exceeded a rate limit, or the server is overloaded."} == LatitudeSh.fetch_access_token
  end

  test "Testing 500 error for fetch_access_token call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:server_error_error]} end)
    assert {:error, "Server Error [500] - Something went wrong on our end."} == LatitudeSh.fetch_access_token
  end
end
