defmodule StartServerMimicTest do
  use ExUnit.Case
  use Mimic

  setup_all do

    success = %Tesla.Env{
      method: :post,
      url: "https://api.latitude.sh/servers/18_912/actions",
      query: [],
      headers: [
        {"cache-control", "max-age=0, private, must-revalidate"},
        {"connection", "keep-alive"},
        {"date", "Sat, 02 Sep 2023 10:42:13 GMT"},
        {"etag", "W/\"fecc8945bb5b20bc7cee15a80fd885e0\""},
        {"server", "cloudflare"},
        {"vary", "Origin"},
        {"content-length", "100"},
        {"content-type", "application/vnd.api+json; charset=utf-8"},
        {"status", "201 Created"},
        {"strict-transport-security", "max-age=63072000; includeSubDomains"},
        {"referrer-policy", "strict-origin-when-cross-origin"},
        {"x-permitted-cross-domain-policies", "none"},
        {"x-xss-protection", "1; mode=block"},
        {"x-request-id", "bb0f5e98-fe2c-485f-b150-89f5d163bccf"},
        {"x-download-options", "noopen"},
        {"x-frame-options", "SAMEORIGIN"},
        {"x-runtime", "4.046399"},
        {"x-content-type-options", "nosniff"},
        {"x-powered-by", "cloud66"},
        {"x-powered-by", "cloud66"},
        {"cf-cache-status", "DYNAMIC"},
        {"report-to",
         "{\"endpoints\":[{\"url\":\"https:\\/\\/a.nel.cloudflare.com\\/report\\/v3?s=UXo7UdL3RfE1DlEShMXqqdkRmmksRUW0qa9uJiSKdvlIqmKZVVGqFYI%2BOkuzhO9ez%2Fw%2BABSK0N%2FroBPUSvf5xiw7taFzqO2e1%2BV2HkrZxPl3es1TfE59le9uGQYXJiP%2FVA%3D%3D\"}],\"group\":\"cf-nel\",\"max_age\":604800}"},
        {"nel",
         "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}"},
        {"cf-ray", "80052507aa39a889-SYD"}
      ],
      body: "{\"data\":{\"id\":\"1693651333\",\"type\":\"actions\",\"attributes\":{\"status\":\"Powering device on\"}},\"meta\":{}}",
      status: 201,
      opts: [],
      __module__: LatitudeSh.ApiWrappers,
      __client__: %Tesla.Client{fun: nil, pre: [], post: [], adapter: nil}
    }

    list_started_server_success = %Tesla.Env{
      method: :get,
      url: "https://api.latitude.sh/servers/18_912",
      query: [],
      headers: [
        {"cache-control", "max-age=0, private, must-revalidate"},
        {"connection", "keep-alive"},
        {"date", "Sat, 02 Sep 2023 10:45:41 GMT"},
        {"etag", "W/\"6bf39831a212c64940bcd3e8a54fa349\""},
        {"server", "cloudflare"},
        {"vary", "Origin"},
        {"content-length", "1466"},
        {"content-type", "application/vnd.api+json; charset=utf-8"},
        {"status", "200 OK"},
        {"strict-transport-security", "max-age=63072000; includeSubDomains"},
        {"referrer-policy", "strict-origin-when-cross-origin"},
        {"x-permitted-cross-domain-policies", "none"},
        {"x-xss-protection", "1; mode=block"},
        {"x-request-id", "1cd8943a-8655-4b86-9dd5-4924f516f335"},
        {"x-download-options", "noopen"},
        {"x-frame-options", "SAMEORIGIN"},
        {"x-runtime", "0.236546"},
        {"x-content-type-options", "nosniff"},
        {"x-powered-by", "cloud66"},
        {"x-powered-by", "cloud66"},
        {"cf-cache-status", "DYNAMIC"},
        {"report-to",
         "{\"endpoints\":[{\"url\":\"https:\\/\\/a.nel.cloudflare.com\\/report\\/v3?s=D9A09BVxKUcmefX6answxZ78TAANdtq2n1ZFAeM9UqJ8Iui6wSP82SnaEqd3X35Y2yrLpBISUf43iHxK9OVkcFgPaT5MDORTE65g%2B3QY%2BOkHrMLwBmPpKrgpAaFqsZSq1w%3D%3D\"}],\"group\":\"cf-nel\",\"max_age\":604800}"},
        {"nel",
         "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}"},
        {"cf-ray", "80052a314c84a889-SYD"}
      ],
      body: "{\"data\":{\"id\":\"18912\",\"type\":\"servers\",\"attributes\":{\"hostname\":\"c2-small-x86-sao-test02092023\",\"label\":\"212S006935\",\"role\":\"Bare Metal\",\"primary_ipv4\":\"177.54.156.71\",\"status\":\"on\",\"ipmi_status\":\"Normal\",\"created_at\":\"2023-09-02T10:36:16+00:00\",\"region\":{\"city\":\"São Paulo\",\"country\":\"Brazil\",\"site\":{\"id\":1,\"name\":\"São Paulo\",\"slug\":\"SAO\",\"facility\":\"Maxihost MH1\"}},\"team\":{\"id\":\"2f18dfbb-5f3d-45c8-8bcb-6d17ee215548\",\"name\":\"Strong Compute, Research team\",\"slug\":\"strong-compute-research-team\",\"description\":\"\",\"address\":null,\"currency\":{\"id\":1,\"code\":\"USD\",\"name\":\"United States Dollar\"},\"status\":\"verified\",\"hourly_billing\":true},\"project\":{\"id\":8093,\"name\":\"USYD-06\",\"slug\":\"usyd-06\",\"description\":\"\",\"billing_type\":\"Normal\",\"billing_method\":\"Normal\",\"bandwidth_alert\":false,\"environment\":null,\"billing\":{\"subscription_id\":\"sub_1NgcorLpWuMxVFxQcvzXMXMo\",\"type\":\"Normal\",\"method\":\"Normal\"},\"stats\":{\"ip_addresses\":0,\"prefixes\":0,\"servers\":1,\"vlans\":0}},\"plan\":{\"id\":\"20\",\"name\":\"c2.small.x86\",\"slug\":\"c2-small-x86\"},\"operating_system\":{\"name\":\"Ubuntu\",\"slug\":\"ubuntu_22_04_x64_lts\",\"version\":\"22.04\",\"features\":{\"raid\":true,\"rescue\":true,\"ssh_keys\":true,\"user_data\":true},\"distro\":{\"name\":\"ubuntu\",\"slug\":\"ubuntu\",\"series\":\"jammy\"}},\"specs\":{\"cpu\":\"Xeon E-2276G CPU @ 3.80GHz (6 cores)\",\"disk\":\"500 GB SSD\",\"ram\":\"32 GB\",\"nic\":\"2 X 1 Gbit/s\",\"gpu\":null}},\"relationships\":{\"project\":{\"meta\":{\"included\":false}},\"team\":{\"meta\":{\"included\":false}}}},\"meta\":{}}",
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
      list_started_server_success: list_started_server_success,
      bad_request_error: bad_request_error,
      unauthorized_error: unauthorized_error,
      forbidden_error: forbidden_error,
      not_found_error: not_found_error,
      unprocessable_entity_error: unprocessable_entity_error,
      too_many_requests_error: too_many_requests_error,
      server_error_error: server_error_error
    }
  end

  test "Testing successful start_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:post_wrapper, 1, fn _url, _request_body -> {:ok, context[:success]} end)
      |> Mimic.expect(:get_wrapper, 1, fn _url -> {:ok, context[:list_started_server_success]} end)
    assert {:ok, %{message: "Started server 18912", request_id: "1693651333"}} == LatitudeSh.start_server(18_912)
  end

  test "Testing 400 error for start_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:post_wrapper, 1, fn _url, _request_body -> {:ok, context[:bad_request_error]} end)
    assert {:error, "Bad Request [400] -- General client error, possible malformed data."} == LatitudeSh.start_server(18_912)
  end

  test "Testing 401 error for start_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:post_wrapper, 1, fn _url, _request_body -> {:ok, context[:unauthorized_error]} end)
    assert {:error, "Unauthorized [401] -- The API Key was not authorised (or no API Key was found)."} == LatitudeSh.start_server(18_912)
  end

  test "Testing 403 error for start_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:post_wrapper, 1, fn _url, _request_body -> {:ok, context[:forbidden_error]} end)
    assert {:error, "Forbidden [403] -- The request is not allowed."} == LatitudeSh.start_server(18_912)
  end

  test "Testing 404 error for start_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:post_wrapper, 1, fn _url, _request_body -> {:ok, context[:not_found_error]} end)
    assert {:error, "Not Found [404] -- The resource was not found."} == LatitudeSh.start_server(18_912)
  end

  test "Testing 422 error for start_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:post_wrapper, 1, fn _url, _request_body -> {:ok, context[:unprocessable_entity_error]} end)
    assert {:error, "Unprocessable Entity [422] -- The data was well-formed but invalid."} == LatitudeSh.start_server(18_912)
  end

  test "Testing 429 error for start_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:post_wrapper, 1, fn _url, _request_body -> {:ok, context[:too_many_requests_error]} end)
    assert {:error, "Too Many Requests [429] -- The client has reached or exceeded a rate limit, or the server is overloaded."} == LatitudeSh.start_server(18_912)
  end

  test "Testing 500 error for start_server call to mock api", context do
    LatitudeSh.ApiWrappers
      |> Mimic.expect(:post_wrapper, 1, fn _url, _request_body -> {:ok, context[:server_error_error]} end)
    assert {:error, "Server Error [500] - Something went wrong on our end."} == LatitudeSh.start_server(18_912)
  end

end
