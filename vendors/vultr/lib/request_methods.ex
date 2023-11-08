defmodule Vultr.RequestMethods do
  @moduledoc """
  Methods used to make GET, POST, and DELETE requests. Handles all the
  errors and parsing of responses or unsuccessful requests.

  Also has an alternative set of methods that can automatically handle
  requests that need to be paginated.
  """
  import Vultr.TeslaWrappers


  # Generic error messages if API responses don't return an error
  #  message, used in `decode_unsuccessful_response`
  # https://www.vultr.com/api/#section/Introduction/Response-Codes
  # @generic_msg_200 "(200) OK - The response contains your requested information."
  # @generic_msg_201 "(201) Created - Your request was accepted. The resource was created."
  # @generic_msg_202 "(202) Accepted - Your request was accepted. The resource was created or updated."
  # @generic_msg_204 "(204) No Content - Your request succeeded, there is no additional information returned."
  @generic_msg_400 "(400) Bad Request - Your request was malformed."
  @generic_msg_401 "(401) Unauthorized - You did not supply valid authentication credentials."
  @generic_msg_403 "(403) Forbidden - You are not allowed to perform that action."
  @generic_msg_404 "(404) Not Found - No results were found for your request."
  @generic_msg_429 "(429) Too Many Requests - Your request exceeded the API rate limit."
  @generic_msg_500 "(500) Internal Server Error - We were unable to perform the request due to server-side problems."

  # TODO: Integrate these?
  # @generic_msg_405 "METHOD_NOT_SUPPORTED [405] -- The requested method is not supported for the requested resource."
  # @generic_msg_408 "TIMEOUT [408] -- The request took too long."
  # @generic_msg_409 "CONFLICT [409] -- The request conflicts with another request."
  # @generic_msg_412 "PRECONDITION_FAILED [412] -- The client did not meet one of the request's requirements."
  # @generic_msg_413 "PAYLOAD_TOO_LARGE [413] -- The request is larger than the server is willing or able to process."
  # @generic_msg_499 "CLIENT_CLOSED_REQUEST [499] -- The client closed the request before the server could respond."



  ####################
  # General Requests #
  ####################
  # API request making methods. Pass in the endpoint including the
  #  leading '/', along with APi key and any params/data needed.

  def api_request_get(api_key, endpoint, query \\ []) do
    # Construct header for request
    headers = [{"Authorization", "Bearer #{api_key}"}]

    # Make GET request and return the parsed response
    {tesla_status, r} = tesla_get(endpoint, headers, query)
    decode_response(tesla_status, r)
  end

  def api_request_post(api_key, endpoint, body \\ []) do
    # Construct header for request
    headers = [{"Authorization", "Bearer #{api_key}"}]

    # Make POST request and return the parsed response
    {tesla_status, r} = tesla_post(endpoint, headers, body)
    decode_response(tesla_status, r)
  end

  def api_request_delete(api_key, endpoint) do
    # Construct header for request
    headers = [{"Authorization", "Bearer #{api_key}"}]

    # Make DELETE request and return the parsed response
    {tesla_status, r} = tesla_delete(endpoint, headers)
    decode_response(tesla_status, r)
  end

  def api_request_get_paginated(
    api_key, endpoint, query \\ [],
    responses \\ [], next_cursor \\ nil
  ) do
    # https://www.vultr.com/api/#section/Introduction/Meta-and-Pagination

    # Page size max is 500, might as well use that
    page_size = 100

    # Add on page size, and cursor if needed
    paginated_query = (
      if next_cursor == nil do
        query ++ [{"per_page", page_size}]
      else
        query ++ [{"per_page", page_size}, {"cursor", next_cursor}]
      end
    )

    # Make our request with pagination params
    {status, resp} = api_request_get(api_key, endpoint, paginated_query)

    # If request was successful, check if there's more pages we need to
    #  fetch. If not, can return the list of responses to be handled
    if status == :ok do
      # Update response list
      responses = responses ++ [resp]

      # Check if next page, if so, recursive call
      if pagination_next_page?(resp) do
        next_cursor = pagination_next_page(resp)
        api_request_get_paginated(api_key, endpoint, query, responses, next_cursor)
      else
        {:ok, responses}
      end

    # We had an error in the last request. Need to pass up that error
    else
      {status, resp}
    end
  end



  ######################
  # Pagination Helpers #
  ######################

  # Flatten a list of responses, each with their own (key, value) pairs
  #  into a list of just (values).
  def flatten_paginated_response_by_key(:ok, resps, key) do
    # Each response is a (status, x[key], meta) dict. Pull out the list
    #  of items by key and construct (status, items) pairs for each resp
    resps = resps |> Enum.map(fn r -> item_resp_to_items(r, key) end)

    # Check if any errors. If so, return first error message
    if Enum.any?(resps |> Enum.map(fn {s, _} -> s == :error end)) do
      # Find first error message
      {_, msg} = Enum.find(resps, fn {s, _} -> s == :error end)
      {:error, msg}

    # If no errors, flatten item lists
    else
      items = resps
        |> Enum.map(fn {_, i} -> i end)
        |> List.flatten()
      {:ok, items}
    end
  end
  def flatten_paginated_response_by_key(:error, msg, _), do: {:error, msg}

  defp item_resp_to_items(resp, key) do
    # If key doesn't exist in response, error. Otherwise, give value
    if Map.has_key?(resp, key) do
      {:ok, resp[key]}
    else
      {:error, "Response missing key '#{key}'"}
    end
  end

  defp pagination_next_page?(resp) do
    # resp["meta"]["links"]["next"] must exist for a next page
    (
      Map.has_key?(resp, "meta") and
      Map.has_key?(resp["meta"], "links") and
      Map.has_key?(resp["meta"]["links"], "next") and
      resp["meta"]["links"]["next"] != ""
    )
  end

  defp pagination_next_page(resp) do
    # Already pre-checked existance with pagination_next_page?
    resp["meta"]["links"]["next"]
  end



  ###########################
  # General Request Helpers #
  ###########################

  # Decoding a successful request
  defp decode_response(:ok, r) do
    cond do
      # If status of response was 200, attempt to decode content
      r.status == 200 ->
        decode_successful_response(r)

      # If status of response was 201, resource created, decode
      r.status == 201 ->
        decode_successful_response(r)

      # If status of response was 202, resource created/updated, decode
      r.status == 202 ->
        decode_successful_response(r)

      # If status of response was 204, was successful but no content
      r.status == 204 ->
        {:ok, nil}

      # If status was neither of these, we need to return an error of
      #  some form.
      true ->
        decode_unsuccessful_response(r)
    end
  end

  # Decoding a failed request (timed out, connection dropped, etc)
  defp decode_response(:error, r) do
    # Just pass through the error from Tesla
    {:error, r}
  end

  # Decode successful 200 coded response
  defp decode_successful_response(r) do
    # Attempt to decode r as json. If this fails, return an error
    {json_status, resp} = Jason.decode(r.body)
    if json_status != :ok do
      {:error, "Failed to decode json in response"}
    else
      {:ok, resp}
    end
  end

  # Decode an unsuccessful, non-200 coded response
  defp decode_unsuccessful_response(r) do
    # Attempt to decode r as json. If this fails, return a generic error
    #  based on status of response
    {json_status, resp} = Jason.decode(r.body)

    # If json was successful and has an error message, return that
    if json_status == :ok and json_error_message?(resp) do
      {:error, json_error_message(resp)}

    # Otherwise, return a generic error message
    else
      case r.status do
        400 -> {:error, @generic_msg_400}
        401 -> {:error, @generic_msg_401}
        403 -> {:error, @generic_msg_403}
        404 -> {:error, @generic_msg_404}
        429 -> {:error, @generic_msg_429}
        500 -> {:error, @generic_msg_500}
        _   -> {:error, "Unknown error code #{r.status}"}
      end
    end
  end

  defp json_error_message?(resp), do: Map.has_key?(resp, "error")
  defp json_error_message(resp), do: resp["error"]
end
