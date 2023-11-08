defmodule Vultr.TeslaWrappers do
  @moduledoc """
  Wrapped Telsa.get/Tesla.post/Tesla.delete methods. Mostly to enable
  testing, and log when run.
  """

  require Logger

  # All requests are made to api.vultr.com/v2.
  use Tesla, only: [:get, :post, :delete], docs: false

  # Use global timeout of 10 seconds
  plug Tesla.Middleware.BaseUrl, "https://api.vultr.com/v2"
  # plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 10_000

  # Wrappers for request methods to allow for mocking for tests
  def tesla_get(endpoint, headers, query \\ []) do
    Logger.warning("tesla_wrappers/tesla_get being called at #{endpoint}")
    get(endpoint, headers: headers, query: query)
  end
  def tesla_post(endpoint, headers, body \\ "") do
    Logger.warning("tesla_wrappers/tesla_post being called at #{endpoint}")
    post(endpoint, Jason.encode!(body), headers: headers)
  end
  def tesla_delete(endpoint, headers) do
    Logger.warning("tesla_wrappers/tesla_delete being called at #{endpoint}")
    delete(endpoint, headers: headers)
  end
end