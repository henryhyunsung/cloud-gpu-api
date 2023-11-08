defmodule LatitudeSh.ApiWrappers do
  @moduledoc """
  This wrapper is designed to decouple the HTTP requests we make via Tesla to the Latitude.sh
  API from the work we do to parse their responses. Pattern matching on the different request
  formats can be added and further specified as needed.

  Tesla Middleware is included in this file; no Tesla requests should be made from the main
  source file. This allows Mimic to stub only functions in this file for testing purposes.
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.latitude.sh"
  plug Tesla.Middleware.Headers, [
    {"Authorization", "Bearer: #{System.get_env("LATITUDESH_APIKEY")}"}
  ]
  plug Tesla.Middleware.JSON

  @doc """
  HTTP GET request with no query parameters.
  """
  def get_wrapper(url) do
    get(url)
  end

  @doc """
  HTTP GET request with 1+ query parameters.
  """
  def get_wrapper(url, query_params) do
    get(url, query: query_params)
  end

  @doc """
  HTTP POST request, with request body included.
  """
  def post_wrapper(url, request_body) do
    post(url, request_body)
  end

  @doc """
  HTTP DELETE request, with no extra parameters.
  """
  def delete_wrapper(url) do
    delete(url)
  end
end
