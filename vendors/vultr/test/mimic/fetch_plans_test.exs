defmodule FetchPlansMimicTest do
  use ExUnit.Case
  use Mimic

  setup_all do
    # Two paged response to test pagination
    success_page1 = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: Jason.encode!(%{
          plans: [
            %{
              bandwidth: 2048,
              disk: 40,
              disk_count: 1,
              gpu_type: "NVIDIA_A40",
              gpu_vram_gb: 1,
              id: "vcg-a40-1c-3g-1vram",
              locations: ["ewr", "syd", "blr"],
              monthly_cost: 30,
              ram: 3072,
              type: "vcg",
              vcpu_count: 1
            },
            %{
              bandwidth: 1024,
              disk: 50,
              disk_count: 1,
              gpu_type: "NVIDIA_A16",
              gpu_vram_gb: 1,
              id: "vcg-a16-2c-4g-1vram",
              locations: ["ewr", "ord", "lhr", "fra", "sjc", "nrt", "blr"],
              monthly_cost: 21.5,
              ram: 4096,
              type: "vcg",
              vcpu_count: 2
            }
          ],
          meta: %{total: 3, links: %{next: "page2_id", prev: ""}
          }
        })
      }
    }
    success_page2 = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: Jason.encode!(%{
          plans: [
            %{
              bandwidth: 1024,
              disk: 50,
              disk_count: 1,
              gpu_type: "NVIDIA_A16",
              gpu_vram_gb: 1,
              id: "vcg-a16-2c-8g-2vram",
              locations: ["ewr", "ord", "lhr", "fra", "sjc", "nrt", "blr"],
              monthly_cost: 43,
              ram: 8192,
              type: "vcg",
              vcpu_count: 2
            }
          ],
          meta: %{total: 3, links: %{next: "", prev: "page1_id"}
          }
        })
      }
    }


    # 500 error with message
    error_with_message = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 500,
        body: Jason.encode!(%{
          error: "server went oopsie"
        })
      }
    }


    # 500 error without message
    error_without_message = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 500,
        body: ""
      }
    }


    # Unsuccessful Tesla fetch
    tesla_error = {
      :error,
      "Tesla error message placeholder"
    }


    # Mangled JSON response
    mangled_resp = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: "{hello world!"
      }
    }


    # Plans response missing the 'plans' attribute
    missing_plans_resp = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: Jason.encode!(%{
          plonks: [ # Renamed
            %{
              bandwidth: 1024,
              disk: 50,
              disk_count: 1,
              gpu_type: "NVIDIA_A16",
              gpu_vram_gb: 1,
              id: "vcg-a16-2c-8g-2vram",
              locations: ["ewr", "ord", "lhr", "fra", "sjc", "nrt", "blr"],
              monthly_cost: 43,
              ram: 8192,
              type: "vcg",
              vcpu_count: 2
            }
          ],
          meta: %{total: 1, links: %{next: "", prev: ""}
          }
        })
      }
    }


    # Plans response with plans missing values
    missing_attributes_resp = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: Jason.encode!(%{
          plans: [
            %{
              bandwidth: 1024,
              disk: 50,
              disk_count: 1,
              gpu_type: "NVIDIA_A16",
              gpu_vram_gb: 1,
              # Missing id attribute
              locations: ["ewr", "ord", "lhr", "fra", "sjc", "nrt", "blr"],
              monthly_cost: 43,
              ram: 8192,
              type: "vcg",
              vcpu_count: 2
            }
          ],
          meta: %{total: 1, links: %{next: "", prev: ""}
          }
        })
      }
    }


    # Our context
    {
      :ok,
      success_page1: success_page1,
      success_page2: success_page2,
      error_with_message: error_with_message,
      error_without_message: error_without_message,
      tesla_error: tesla_error,
      mangled_resp: mangled_resp,
      missing_plans_resp: missing_plans_resp,
      missing_attributes_resp: missing_attributes_resp
    }
  end


  @tag mock: true
  @tag fetch_plans: true
  test "fetch_plans: Successful paginated request", context do
    # Set up responses for two pages
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:success_page1] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:success_page2] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, plans} = Vultr.fetch_plans("fake API key")

    # Request should be successful, with three plans
    assert status == :ok
    assert length(plans) == 3

    # Check if the first plan has all its contents
    plan1 = hd(plans)
    assert plan1[:accelerator_count] == "1"
    assert plan1[:accelerator_memory] == 1024
    assert plan1[:accelerator_type] == "NVIDIA_A40"
    assert plan1[:machine_type] == "vcg-a40-1c-3g-1vram"
    assert plan1[:monthly_cost] == 30
    assert plan1[:zones] == ["ewr", "syd", "blr"]
  end


  @tag mock: true
  @tag fetch_plans: true
  test "fetch_plans: Unsuccessful request, error message", context do
    # Set up response for error with message
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_with_message] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_plans("fake API key")

    # Request should be an error in this case, and error message should
    #  be carried from request
    assert status == :error
    assert msg == "Failed to fetch plans: server went oopsie"
  end


  @tag mock: true
  @tag fetch_plans: true
  test "fetch_plans: Unsuccessful request, no error message", context do
    # Set up response for error with message
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_without_message] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_plans("fake API key")

    # Request should be an error in this case, and error should be a
    #  default 500 error
    assert status == :error
    assert msg == "Failed to fetch plans: (500) Internal Server Error - We were unable to perform the request due to server-side problems."
  end


  @tag mock: true
  @tag fetch_plans: true
  test "fetch_plans: Unsuccessful Tesla request", context do
    # Set up responses for an error in request
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:tesla_error] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_plans("fake API key")

    # Check that Tesla errors were passed down
    assert status == :error
    assert msg == "Failed to fetch plans: Tesla error message placeholder"
  end


  @tag mock: true
  @tag fetch_plans: true
  test "fetch_plans: Unparsable JSON from request", context do
    # Set up response for mangled json
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:mangled_resp] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_plans("fake API key")

    # Check that the Jason error was passed down
    assert status == :error
    assert msg == "Failed to fetch plans: Failed to decode json in response"
  end


  @tag mock: true
  @tag fetch_plans: true
  test "fetch_plans: Missing 'plans' attribute in response", context do
    # Set up response missing the 'plans' attribute
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:missing_plans_resp] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_plans("fake API key")

    # Check that response mentions missing attribute
    assert status == :error
    assert msg == "Failed to fetch plans: Response missing key 'plans'"
  end


  @tag mock: true
  @tag fetch_plans: true
  test "fetch_plans: Missing 'gpu_type' attribute in plans", context do
    # Set up response with plans missing 'id'
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:missing_attributes_resp] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_plans("fake API key")

    # Check that response mentions missing attribute
    assert status == :error
    assert msg == "Failed to fetch plans: Error parsing plan"
  end
end
