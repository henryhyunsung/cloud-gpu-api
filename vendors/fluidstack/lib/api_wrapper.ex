defmodule Fluidstack.ApiWrapper do
  @moduledoc """
  This wrapper is designed to decouple the HTTP requests we make via Tesla to the Fluidstack
  API from the work we do to parse their responses. Pattern matching on the different request
  formats can be added and further specified as needed.

  Tesla Middleware is included in this file; no Tesla requests should be made from the main
  source file. This allows Mimic to stub only functions in this file for testing purposes.
  """

  use Tesla

  # These messages are used when the corresponding error codes are found.
  @generic_msg_401 "UNAUTHORIZED [401] -- The API key or token was invalid or expired."
  @generic_msg_404 "NOT_FOUND [404] -- The requested resource doesn't exist."

  defp process_error(status) do
    case status do
      401 -> {:error, @generic_msg_401}
      404 -> {:error, @generic_msg_404}
      _   -> {:error, "Unknown error code: #{status}."}
    end
  end

  @doc """
    Make a HTTP request based upon a method and endpoint. Optional body and headers.
    Return response is of the form: `{:ok, resp}` or `{:error, message}`.
  """
  def make_request(method, endpoint, body \\ nil, headers \\ []) do

    url = "https://api.fluidstack.io/v1/" <> endpoint

    case method do
      "GET" -> decode_response(get(url, headers: headers))
      "DELETE" -> decode_response(delete(url, headers: headers))
      "PUT" -> decode_response(put(url, body, headers: headers))
      _ -> {:error, "Unkown request method: #{method}."}
    end
  end
  
  defp decode_response({status, response}) do
    case {status, response.status} do
      {:ok, 200} -> decode_good_response(response.body)
      _ -> decode_bad_response(response.status, response.body)
    end
  end

  defp decode_good_response(response) do
    case decode_json(response) do
      {:ok, %{"message" => message, "success" => _success}} -> {:ok, message}
      {_status, json_response} -> {:ok, json_response}
    end
  end
  
  defp decode_bad_response(status, response) do
    case decode_json(response) do
      {:ok, %{"error" => error, "success" => _success}} -> {:error, error}
      {:ok, json_response} -> {:error, json_response}
        _ -> process_error(status)
    end
  end

  defp decode_json(response) do
    case Jason.decode(response) do
      {:error, _body} -> {:error, "Failed to decode response json."}
      {:ok, body} -> {:ok, body}
    end
  end

end
