defmodule DeleteServerMimicTest do
  use ExUnit.Case
  use Mimic

  setup_all do
    success = %Tesla.Env{
      method: :delete,
      url: "https://api.latitude.sh/servers/18_912",
      query: [],
      headers: [
        {"cache-control", "max-age=0, private, must-revalidate"},
        {"connection", "keep-alive"},
        {"date", "Sat, 02 Sep 2023 10:47:20 GMT"},
        {"etag", "W/\"e687ef92c8b55cc7615daca748f6f7e9\""},
        {"server", "cloudflare"},
        {"vary", "Origin"},
        {"content-length", "11"},
        {"content-type", "application/vnd.api+json; charset=utf-8"},
        {"status", "200 OK"},
        {"strict-transport-security", "max-age=63072000; includeSubDomains"},
        {"referrer-policy", "strict-origin-when-cross-origin"},
        {"x-permitted-cross-domain-policies", "none"},
        {"x-xss-protection", "1; mode=block"},
        {"x-request-id", "de293104-fadc-4db5-84b5-99bad82eb398"},
        {"x-download-options", "noopen"},
        {"x-frame-options", "SAMEORIGIN"},
        {"x-runtime", "0.271202"},
        {"x-content-type-options", "nosniff"},
        {"x-powered-by", "cloud66"},
        {"x-powered-by", "cloud66"},
        {"cf-cache-status", "DYNAMIC"},
        {"report-to",
         "{\"endpoints\":[{\"url\":\"https:\\/\\/a.nel.cloudflare.com\\/report\\/v3?s=dzw51fEyUaA27lf9%2FlPkyNUgb4o4k7MC06WelQcfB6H92ScwIQdi%2FMvGJkrsBbrFlu2TJjJ4BjPl%2BPeF3U858sVRWON2L1Gp9GNCg6daalJ%2BkNrzWCU1XbsItcCZPWNywQ%3D%3D\"}],\"group\":\"cf-nel\",\"max_age\":604800}"},
        {"nel",
         "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}"},
        {"cf-ray", "80052c9b0822a889-SYD"}
      ],
      body: "{\"meta\":{}}",
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

  test "Testing successful delete_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:delete_wrapper, 1, fn _url -> {:ok, context[:success]} end)
    assert {:ok, %{message: "Deleted successfully.", request_id: nil}} == LatitudeSh.delete_server(18_912)
  end

  test "Testing 400 error for delete_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:delete_wrapper, 1, fn _url -> {:ok, context[:bad_request_error]} end)
    assert {:error, "Bad Request [400] -- General client error, possible malformed data."} == LatitudeSh.delete_server(18_912)
  end

  test "Testing 401 error for delete_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:delete_wrapper, 1, fn _url -> {:ok, context[:unauthorized_error]} end)
    assert {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."} == LatitudeSh.delete_server(18_912)
  end

  test "Testing 403 error for delete_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:delete_wrapper, 1, fn _url -> {:ok, context[:forbidden_error]} end)
    assert {:error, "Forbidden [403] -- The request is not allowed."} == LatitudeSh.delete_server(18_912)
  end

  test "Testing 404 error for delete_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:delete_wrapper, 1, fn _url -> {:ok, context[:not_found_error]} end)
    assert {:error, "Not Found [404] -- The resource was not found."} == LatitudeSh.delete_server(18_912)
  end

  test "Testing 422 error for delete_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:delete_wrapper, 1, fn _url -> {:ok, context[:unprocessable_entity_error]} end)
    assert {:error, "Unprocessable Entity [422] -- The data was well-formed but invalid."} == LatitudeSh.delete_server(18_912)
  end

  test "Testing 429 error for delete_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:delete_wrapper, 1, fn _url -> {:ok, context[:too_many_requests_error]} end)
    assert {:error, "Too Many Requests [429] -- The client has reached or exceeded a rate limit, or the server is overloaded."} == LatitudeSh.delete_server(18_912)
  end

  test "Testing 500 error for delete_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:delete_wrapper, 1, fn _url -> {:ok, context[:server_error_error]} end)
    assert {:error, "Server Error [500] - Something went wrong on our end."} == LatitudeSh.delete_server(18_912)
  end

end
