defmodule Datacrunch.ApiWrapper do
  @moduledoc """
  This wrapper is designed to decouple the HTTP requests we make via Tesla to the Datacrunch
  API from the work we do to parse their responses. Pattern matching on the different request
  formats can be added and further specified as needed.

  Tesla Middleware is included in this file; no Tesla requests should be made from the main
  source file. This allows Mimic to stub only functions in this file for testing purposes.
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.datacrunch.io"
  plug Tesla.Middleware.Headers, [
    {"Authorization", "Bearer #{System.get_env("DATACRUNCH_AUTHTOKEN")}"}
  ]
  plug Tesla.Middleware.JSON

  @doc """
    Creates the HTTP request: POST,GET,DELETE,PUT depending on the inputted method type
    Takes an endpoint to querey the specific address and has an optional additional payload to add
    onto the message
  """
  def perform_request(method, endpoint, payload \\ nil) do

    url = "/v1/#{endpoint}"

    case method do
      "POST" -> post(url, payload)
      "GET" -> get(url)
      "DELETE" -> delete(url)
      "PUT" -> put(url, payload)
      _ ->
        {:error, "failed to perform request"}
    end
  end
end
