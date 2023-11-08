defmodule E2E.API do
 @moduledoc """
  This wrapper is designed to decouple the HTTP requests we make via Tesla to the E2E
  API from the work we do to parse their responses. Pattern matching on the different request
  formats can be added and further specified as needed.

  Tesla Middleware is included in this file; no Tesla requests should be made from the main
  source file. This allows Mimic to stub only functions in this file for testing purposes.
  """
  use Tesla
  plug Tesla.Middleware.BaseUrl, "https://api.e2enetworks.com"
  plug Tesla.Middleware.Headers, [
    {"Authorization", "Bearer #{System.get_env("E2E_AUTHTOKEN")}"}
  ]
  plug Tesla.Middleware.JSON

  @doc """
  Perform request.

  :param method - request method.
  :param endpoint - endpoint section of url
  :param payload - request body
  """
  def perform_request(method, endpoint, payload \\ nil, addons \\ "") do

    url = "/myaccount/api/v1/#{endpoint}apikey=#{System.get_env("E2E_APIKEY")}&contact_person_id=#{System.get_env("E2E_USER_IDENTIFIER")}#{addons}"

    case method do
      "POST" -> post(url, payload)
      "GET" -> get(url)
      "DELETE" -> delete(url)
      _ ->
        {:error, "failed to perform request"}
    end
  end
end
