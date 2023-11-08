defmodule LiveApiWrappersTest do
  use ExUnit.Case

  test "get_wrapper successfully gets a response" do
    case LatitudeSh.ApiWrappers.get_wrapper("/user/profile") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        assert match?(%{"data" => %{"id" => _}}, Jason.decode!(body))
      _ ->
        assert true
    end
  end

  test "get_wrapper with body successfully gets a response" do
    query_params = ['page[size]': 20, 'page[number]': 1]
    case LatitudeSh.ApiWrappers.get_wrapper("/servers/", query_params) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        case Jason.decode!(body) do
          %{"data" => []} -> assert true
          %{"data" => [%{
            "id" => _server_id,
            "attributes" => %{
              "hostname" => _name,
              "plan" => %{"id" => _plan_id, "slug" => _plan_slug, },
              "team" => %{"hourly_billing" => _is_hourly, },
              "role" => _machine_type,
              "region" => %{"country" => _country, "site" => %{"slug" => _site_slug, }},
              "status" => _status,
              "primary_ipv4" => _ip_address,
              "specs" => %{"gpu" => _gpu_specs, },
              "operating_system" => %{"distro" => %{"slug" => _os_type, }}
            }
          } | _]} -> assert true
            _ -> assert false
        end
      _ -> assert false
    end
  end

  test "post_wrapper and delete_wrapper are successful" do
    {:ok, [%{id: project_id} | _]} = LatitudeSh.fetch_projects
    {:ok, %{plan: plan, site: site}} = LatitudeSh.fetch_one_plan_by_availability(true)
    specs = %{data: %{
      type: "servers",
      attributes: %{
        operating_system: "ubuntu_22_04_x64_lts",
        hostname: "tmp",
        project: project_id,
        plan: plan,
        site: site
      }
    }}
    {:ok, %Tesla.Env{status: 201, body: body}} = LatitudeSh.ApiWrappers.post_wrapper("/servers", specs)
    %{"data" => %{"id" => server_id}} = Jason.decode!(body)
    assert match?({:ok, %Tesla.Env{status: 200}}, LatitudeSh.ApiWrappers.delete_wrapper("/servers/#{server_id}"))
  end
end
