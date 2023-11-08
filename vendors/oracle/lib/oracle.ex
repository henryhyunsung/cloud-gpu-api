defmodule Oracle do
  @moduledoc """
  This module contains all the functions for interfacing with Oracle Cloud
  Infrastructure (OCI) in accordance with the specified requirements.
  """

  import Oracle.Utils

  @doc """
  This function makes an API request to retrieve the list of instances
  currently in existence.

  @return A list of instances if successful.
  """
  def get_node_list() do
    method = "get"

    region = System.get_env("REGION")
    host = "iaas.#{region}.oraclecloud.com"

    endpoint = "/20160918/instances"
    tenancy = System.get_env("TENANCY")
    query = %{compartmentId: "#{tenancy}"}
    target = "#{endpoint}?#{URI.encode_query(query)}"

    date = get_date()
    signing_string = get_signing_string(date, method, target, host)
    IO.puts(signing_string<>"\n")
    signature = get_signature(signing_string)
    auth_header = get_auth_header(signature)
    IO.puts(auth_header<>"\n")

    url = "https://#{host}#{target}"
    headers = [
      {"date", date},
      {"Authorization", "#{auth_header}"}
    ]

    case Tesla.get(url, headers: headers) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, Jason.decode(body)}
      _ ->
        {:error, "failed to get node list"}
    end
  end
end
