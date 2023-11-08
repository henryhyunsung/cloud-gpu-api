defmodule Oracle.Utils do
  @moduledoc """
  This module contains all the helper functions that serve as utilities for
  the user functions in the Oracle module.
  """

  use Tesla
  plug Tesla.Middleware.JSON

  @doc """
  This function builds the API key from environment variables.

  @return A string containing the API key built from tenancy ID, user ID
  and fingerprint.
  """
  def get_apikey() do
    tenancy = System.get_env("TENANCY")
    user = System.get_env("USER")
    fingerprint = System.get_env("FINGERPRINT")
    "#{tenancy}/#{user}/#{fingerprint}"
  end

  @doc """
  This function gets the current datetime and converts it to RFC2616 format.

  @return A string containing the current datetime in RFC2616 format.
  """
  def get_date() do
    DateTime.utc_now()
    |> Calendar.strftime("%a, %d %b %Y %X GMT")
  end

  @doc """
  This function gets the signing string

  @param method [string] The request method.
  @param base [string] The base URL.
  @param target [string] The endpoint + query URL.

  @return A signing string containing the date, request-target and host.
  """
  def get_signing_string(date, method, target, host) do
    date = "date: #{date}"
    request = "(request-target): #{method} #{target}"
    host = "host: #{host}"
    "#{date}\n#{request}\n#{host}"
  end

  @doc """
  This function gets the signature.

  @param signing_string [string] The signing string to be signed.

  @return A base64-encoded digital signature string.
  """
  def get_signature(signing_string) do
    {:ok, key} = File.read("#{System.get_env("KEYPATH")}")
    [key | _] = :public_key.pem_decode(key)
    key = :public_key.pem_entry_decode(key)
    sign = :public_key.sign(signing_string, :sha256, key)
    Base.encode64(sign)
  end

  @doc """
  This function gets the authorisation header.

  @param signature [string] A base64-encoded digital signature.

  @return An authorisation header containing the signature version, headers,
  API key, algorithm type and signature.
  """
  def get_auth_header(signature) do
    version = ~s(version="1")
    key = ~s(keyId="#{get_apikey()}")
    algorithm = ~s{algorithm="rsa-sha256"}
    headers = ~s{headers="date (request-target) host"}
    sign = ~s{signature="#{signature}"}
    "Signature #{version},#{key},#{algorithm},#{headers},#{sign}"
  end
end
