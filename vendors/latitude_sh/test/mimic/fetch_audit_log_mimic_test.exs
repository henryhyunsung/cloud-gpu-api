defmodule FetchAuditLogMimicTest do
  use ExUnit.Case
  use Mimic

  setup_all do
    success = %Tesla.Env{
      method: :get,
      url: "https://api.latitude.sh/events",
      query: ["page[size]": 10, "page[number]": 1],
      headers: [
        {"cache-control", "max-age=0, private, must-revalidate"},
        {"connection", "keep-alive"},
        {"date", "Sat, 09 Sep 2023 15:12:49 GMT"},
        {"etag", "W/\"f3a1fb2484deaca318e50487835f960b\""},
        {"server", "cloudflare"},
        {"vary", "Origin"},
        {"content-length", "4092"},
        {"content-type", "application/vnd.api+json; charset=utf-8"},
        {"status", "200 OK"},
        {"strict-transport-security", "max-age=63072000; includeSubDomains"},
        {"referrer-policy", "strict-origin-when-cross-origin"},
        {"x-permitted-cross-domain-policies", "none"},
        {"x-xss-protection", "1; mode=block"},
        {"x-request-id", "9f71a60c-71a1-459e-abe6-b309abb1f673"},
        {"x-download-options", "noopen"},
        {"x-frame-options", "SAMEORIGIN"},
        {"x-runtime", "0.111135"},
        {"x-content-type-options", "nosniff"},
        {"x-powered-by", "cloud66"},
        {"x-powered-by", "cloud66"},
        {"cf-cache-status", "DYNAMIC"},
        {"report-to",
         "{\"endpoints\":[{\"url\":\"https:\\/\\/a.nel.cloudflare.com\\/report\\/v3?s=x6YRzoZ110UyK61Rjfz%2FzfHLPars5FkwVeLReyE108quRMw%2Fzcd7jSmnfnAf69QG5Sb8kRHHLiqpZoyM%2F10dHEfF%2FkhAEVfxoUqKmq4%2BeR%2F5iOWIVolwRbuo9%2BMV84x7Kw%3D%3D\"}],\"group\":\"cf-nel\",\"max_age\":604800}"},
        {"nel",
         "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}"},
        {"cf-ray", "80405f226f27a943-SYD"}
      ],
      body: "{\"data\":[{\"id\":\"662280\",\"type\":\"events\",\"attributes\":{\"created_at\":\"2023-08-28T07:42:56+00:00\",\"action\":\"create.servers\",\"target\":{\"id\":null,\"name\":\"servers\"},\"project\":{\"id\":null,\"name\":null,\"slug\":null},\"team\":{\"id\":\"2f18dfbb-5f3d-45c8-8bcb-6d17ee215548\",\"name\":\"Strong Compute, Research team\"},\"author\":{\"id\":\"40558049-7011-4e4a-a01c-74d97ebb5dfd\",\"name\":\"USYD 06\",\"email\":\"usyd06capstone@gmail.com\"}}},{\"id\":\"662283\",\"type\":\"events\",\"attributes\":{\"created_at\":\"2023-08-28T07:42:57+00:00\",\"action\":\"create.servers\",\"target\":{\"id\":19558,\"name\":\"servers\"},\"project\":{\"id\":8093,\"name\":\"USYD-06\",\"slug\":\"usyd-06\"},\"team\":{\"id\":\"2f18dfbb-5f3d-45c8-8bcb-6d17ee215548\",\"name\":\"Strong Compute, Research team\"},\"author\":{\"id\":\"40558049-7011-4e4a-a01c-74d97ebb5dfd\",\"name\":\"USYD 06\",\"email\":\"usyd06capstone@gmail.com\"}}},{\"id\":\"662285\",\"type\":\"events\",\"attributes\":{\"created_at\":\"2023-08-28T07:42:58+00:00\",\"action\":\"destroy.servers\",\"target\":{\"id\":19558,\"name\":\"servers\"},\"project\":{\"id\":8093,\"name\":\"USYD-06\",\"slug\":\"usyd-06\"},\"team\":{\"id\":\"2f18dfbb-5f3d-45c8-8bcb-6d17ee215548\",\"name\":\"Strong Compute, Research team\"},\"author\":{\"id\":\"40558049-7011-4e4a-a01c-74d97ebb5dfd\",\"name\":\"USYD 06\",\"email\":\"usyd06capstone@gmail.com\"}}},{\"id\":\"693164\",\"type\":\"events\",\"attributes\":{\"created_at\":\"2023-08-31T02:07:52+00:00\",\"action\":\"create.servers\",\"target\":{\"id\":21602,\"name\":\"servers\"},\"project\":{\"id\":8093,\"name\":\"USYD-06\",\"slug\":\"usyd-06\"},\"team\":{\"id\":\"2f18dfbb-5f3d-45c8-8bcb-6d17ee215548\",\"name\":\"Strong Compute, Research team\"},\"author\":{\"id\":\"40558049-7011-4e4a-a01c-74d97ebb5dfd\",\"name\":\"USYD 06\",\"email\":\"usyd06capstone@gmail.com\"}}},{\"id\":\"693167\",\"type\":\"events\",\"attributes\":{\"created_at\":\"2023-08-31T02:08:09+00:00\",\"action\":\"destroy.servers\",\"target\":{\"id\":21602,\"name\":\"servers\"},\"project\":{\"id\":8093,\"name\":\"USYD-06\",\"slug\":\"usyd-06\"},\"team\":{\"id\":\"2f18dfbb-5f3d-45c8-8bcb-6d17ee215548\",\"name\":\"Strong Compute, Research team\"},\"author\":{\"id\":\"40558049-7011-4e4a-a01c-74d97ebb5dfd\",\"name\":\"USYD 06\",\"email\":\"usyd06capstone@gmail.com\"}}},{\"id\":\"694288\",\"type\":\"events\",\"attributes\":{\"created_at\":\"2023-08-31T04:17:51+00:00\",\"action\":\"create.actions\",\"target\":{\"id\":21085,\"name\":\"actions\"},\"project\":{\"id\":8093,\"name\":\"USYD-06\",\"slug\":\"usyd-06\"},\"team\":{\"id\":\"2f18dfbb-5f3d-45c8-8bcb-6d17ee215548\",\"name\":\"Strong Compute, Research team\"},\"author\":{\"id\":\"40558049-7011-4e4a-a01c-74d97ebb5dfd\",\"name\":\"USYD 06\",\"email\":\"usyd06capstone@gmail.com\"}}},{\"id\":\"694257\",\"type\":\"events\",\"attributes\":{\"created_at\":\"2023-08-31T04:11:08+00:00\",\"action\":\"create.servers\",\"target\":{\"id\":21087,\"name\":\"servers\"},\"project\":{\"id\":8093,\"name\":\"USYD-06\",\"slug\":\"usyd-06\"},\"team\":{\"id\":\"2f18dfbb-5f3d-45c8-8bcb-6d17ee215548\",\"name\":\"Strong Compute, Research team\"},\"author\":{\"id\":\"40558049-7011-4e4a-a01c-74d97ebb5dfd\",\"name\":\"USYD 06\",\"email\":\"usyd06capstone@gmail.com\"}}},{\"id\":\"694264\",\"type\":\"events\",\"attributes\":{\"created_at\":\"2023-08-31T04:11:58+00:00\",\"action\":\"create.servers\",\"target\":{\"id\":18985,\"name\":\"servers\"},\"project\":{\"id\":8093,\"name\":\"USYD-06\",\"slug\":\"usyd-06\"},\"team\":{\"id\":\"2f18dfbb-5f3d-45c8-8bcb-6d17ee215548\",\"name\":\"Strong Compute, Research team\"},\"author\":{\"id\":\"40558049-7011-4e4a-a01c-74d97ebb5dfd\",\"name\":\"USYD 06\",\"email\":\"usyd06capstone@gmail.com\"}}},{\"id\":\"694266\",\"type\":\"events\",\"attributes\":{\"created_at\":\"2023-08-31T04:12:20+00:00\",\"action\":\"create.actions\",\"target\":{\"id\":18985,\"name\":\"actions\"},\"project\":{\"id\":8093,\"name\":\"USYD-06\",\"slug\":\"usyd-06\"},\"team\":{\"id\":\"2f18dfbb-5f3d-45c8-8bcb-6d17ee215548\",\"name\":\"Strong Compute, Research team\"},\"author\":{\"id\":\"40558049-7011-4e4a-a01c-74d97ebb5dfd\",\"name\":\"USYD 06\",\"email\":\"usyd06capstone@gmail.com\"}}},{\"id\":\"694271\",\"type\":\"events\",\"attributes\":{\"created_at\":\"2023-08-31T04:13:06+00:00\",\"action\":\"destroy.servers\",\"target\":{\"id\":18985,\"name\":\"servers\"},\"project\":{\"id\":8093,\"name\":\"USYD-06\",\"slug\":\"usyd-06\"},\"team\":{\"id\":\"2f18dfbb-5f3d-45c8-8bcb-6d17ee215548\",\"name\":\"Strong Compute, Research team\"},\"author\":{\"id\":\"40558049-7011-4e4a-a01c-74d97ebb5dfd\",\"name\":\"USYD 06\",\"email\":\"usyd06capstone@gmail.com\"}}}],\"meta\":{}}",
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

    # Include all of the variables setup in the context. Context can then be passed to the test functions in order to access these variables
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

  test "Testing successful fetch_audit_log call to mock api", context do
    expected_response = {:ok,
    [
      %{
        error_msg: nil,
        location: nil,
        request_id: nil,
        target_id: 18_985,
        event_id: "694264",
        event_time: "2023-08-31T04:11:58+00:00",
        event_severity: nil,
        user_id: "40558049-7011-4e4a-a01c-74d97ebb5dfd",
        event_type: "create.servers"
      },
      %{
        error_msg: nil,
        location: nil,
        request_id: nil,
        target_id: 18_985,
        event_id: "694266",
        event_time: "2023-08-31T04:12:20+00:00",
        event_severity: nil,
        user_id: "40558049-7011-4e4a-a01c-74d97ebb5dfd",
        event_type: "create.actions"
      },
      %{
        error_msg: nil,
        location: nil,
        request_id: nil,
        target_id: 18_985,
        event_id: "694271",
        event_time: "2023-08-31T04:13:06+00:00",
        event_severity: nil,
        user_id: "40558049-7011-4e4a-a01c-74d97ebb5dfd",
        event_type: "destroy.servers"
      }
    ]}
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url, _query_params -> {:ok, context[:success]} end)
    assert expected_response == LatitudeSh.fetch_audit_log(18_985)
  end

  test "Testing 400 error for fetch_audit_log call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url, _query_params -> {:ok, context[:bad_request_error]} end)
    assert {:error, "Bad Request [400] -- General client error, possible malformed data."} == LatitudeSh.fetch_audit_log(18_985)
  end

  test "Testing 401 error for fetch_audit_log call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url, _query_params -> {:ok, context[:unauthorized_error]} end)
    assert {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."} == LatitudeSh.fetch_audit_log(18_985)
  end

  test "Testing 403 error for fetch_audit_log call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url, _query_params -> {:ok, context[:forbidden_error]} end)
    assert {:error, "Forbidden [403] -- The request is not allowed."} == LatitudeSh.fetch_audit_log(18_985)
  end

  test "Testing 404 error for fetch_audit_log call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url, _query_params -> {:ok, context[:not_found_error]} end)
    assert {:error, "Not Found [404] -- The resource was not found."} == LatitudeSh.fetch_audit_log(18_985)
  end

  test "Testing 422 error for fetch_audit_log call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url, _query_params -> {:ok, context[:unprocessable_entity_error]} end)
    assert {:error, "Unprocessable Entity [422] -- The data was well-formed but invalid."} == LatitudeSh.fetch_audit_log(18_985)
  end

  test "Testing 429 error for fetch_audit_log call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url, _query_params -> {:ok, context[:too_many_requests_error]} end)
    assert {:error, "Too Many Requests [429] -- The client has reached or exceeded a rate limit, or the server is overloaded."} == LatitudeSh.fetch_audit_log(18_985)
  end

  test "Testing 500 error for fetch_audit_log call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:get_wrapper, 1, fn _url, _query_params -> {:ok, context[:server_error_error]} end)
    assert {:error, "Server Error [500] - Something went wrong on our end."} == LatitudeSh.fetch_audit_log(18_985)
  end

end
