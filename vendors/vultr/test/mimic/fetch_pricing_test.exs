defmodule FetchPricingInfoMimicTest do
  use ExUnit.Case
  use Mimic

  setup_all do
    machine_id = "a5463157-703a-44a4-bf22-b282f3ae3c34"
    plan_id = "vcg-a16-2c-4g-1vram"
    expected_rate = 5.0


    # Response for a single machine
    machine_success = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: Jason.encode!(%{
          instance: %{
            app_id: 0,
            cpu_count: 4,
            date_created: "2023-09-21T04:02:25+00:00",
            disk: nil,
            features: ["ipv6"],
            gateway_v4: "207.148.120.1",
            id: machine_id,
            image_id: "",
            internal_ip: "",
            label: "TestMachine",
            mac_address: 14038008910443,
            main_ip: "207.148.120.182",
            netmask_v4: "255.255.254.0",
            os: "Ubuntu 22.04 LTS x64",
            os_id: 1743,
            plan: plan_id,
            ram: "32768 MB",
            region: "sgp",
            status: "active",
            tag: "",
            tags: [],
            v6_main_ip: "2401:c080:1400:5c79:0ec4:7aff:fe88:d26b",
            v6_network: "2401:c080:1400:5c79::",
            v6_network_size: 64
          }
        })
      }
    }


    # Response for plans
    plans_success = {
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
              id: plan_id,
              locations: ["ewr", "ord", "lhr", "fra", "sjc", "nrt", "blr"],
              monthly_cost: expected_rate * 24 * 28, # 24 hours, 28 days
              ram: 4096,
              type: "vcg",
              vcpu_count: 2
            },
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
          meta: %{total: 3, links: %{next: "", prev: ""}
          }
        })
      }
    }


    # 400 error with message
    error_with_message = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 400,
        body: Jason.encode!(%{
          error: "Somethin went wrong..."
        })
      }
    }


    # 400 error without message
    error_without_message = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 400,
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


    # machine response missing 'instance' attribute
    machine_missing_instance_resp = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: Jason.encode!(%{
          ingrinkly: %{ # Renamed
            app_id: 0,
            cpu_count: 4,
            date_created: "2023-09-21T04:02:25+00:00",
            disk: nil,
            features: ["ipv6"],
            gateway_v4: "207.148.120.1",
            id: machine_id,
            image_id: "",
            internal_ip: "",
            label: "TestMachine",
            mac_address: 14038008910443,
            main_ip: "207.148.120.182",
            netmask_v4: "255.255.254.0",
            os: "Ubuntu 22.04 LTS x64",
            os_id: 1743,
            plan: plan_id,
            ram: "32768 MB",
            region: "sgp",
            status: "active",
            tag: "",
            tags: [],
            v6_main_ip: "2401:c080:1400:5c79:0ec4:7aff:fe88:d26b",
            v6_network: "2401:c080:1400:5c79::",
            v6_network_size: 64
          }
        })
      }
    }


    # machine response with machine missing values
    machine_missing_attributes_resp = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: Jason.encode!(%{
          instance: %{
            app_id: 0,
            cpu_count: 4,
            date_created: "2023-09-21T04:02:25+00:00",
            disk: nil,
            features: ["ipv6"],
            gateway_v4: "207.148.120.1",
            id: machine_id,
            image_id: "",
            internal_ip: "",
            label: "TestMachine",
            mac_address: 14038008910443,
            main_ip: "207.148.120.182",
            netmask_v4: "255.255.254.0",
            os: "Ubuntu 22.04 LTS x64",
            os_id: 1743,
            # Missing plan_id
            ram: "32768 MB",
            region: "sgp",
            status: "active",
            tag: "",
            tags: [],
            v6_main_ip: "2401:c080:1400:5c79:0ec4:7aff:fe88:d26b",
            v6_network: "2401:c080:1400:5c79::",
            v6_network_size: 64
          }
        })
      }
    }


    # plans response missing 'plans' attribute
    plans_missing_plans_resp = {
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


    # plans response with plan missing values
    plans_missing_attributes_resp = {
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
              # Missing monthly_cost
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


    # plans list that doesn't contain the plan that should match machine
    plans_missing_correct = {
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
              id: "vcg-a16-2c-8g-2vram",
              locations: ["ewr", "ord", "lhr", "fra", "sjc", "nrt", "blr"],
              monthly_cost: 43,
              ram: 8192,
              type: "vcg",
              vcpu_count: 2
            }
          ],
          meta: %{total: 2, links: %{next: "", prev: ""}
          }
        })
      }
    }

    # Our context
    {
      :ok,
      machine_id: machine_id,
      plan_id: plan_id,
      expected_rate: expected_rate,
      machine_success: machine_success,
      plans_success: plans_success,
      error_with_message: error_with_message,
      error_without_message: error_without_message,
      tesla_error: tesla_error,
      mangled_resp: mangled_resp,
      machine_missing_instance_resp: machine_missing_instance_resp,
      machine_missing_attributes_resp: machine_missing_attributes_resp,
      plans_missing_plans_resp: plans_missing_plans_resp,
      plans_missing_attributes_resp: plans_missing_attributes_resp,
      plans_missing_correct: plans_missing_correct
    }
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: Successful request", context do
    # Set up successful machine and plans responses
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, info} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # On demand pricing should be set to expected
    assert status == :ok
    assert info[context[:machine_id]][:net_cost_on_demand] == context[:expected_rate]
    assert info[context[:machine_id]][:net_cost_spot] == nil
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: Unsuccessful machine request, error message", context do
    # Set up error in machine request
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_with_message] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # Request should be an error in this case, and error message should
    #  be carried from request
    assert status == :error
    assert msg == "Failed to fetch pricing info: (Machine) Somethin went wrong..."
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: Unsuccessful machine request, no error message", context do
    # Set up error in machine request
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_without_message] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # Request should be an error in this case, and error message should
    #  be carried from request
    assert status == :error
    assert msg == "Failed to fetch pricing info: (Machine) (400) Bad Request - Your request was malformed."
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: Unsuccessful plans request, error message", context do
    # Set up error in plans request
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_with_message] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # Request should be an error in this case, and error message should
    #  be carried from request
    assert status == :error
    assert msg == "Failed to fetch pricing info: (Plans) Somethin went wrong..."
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: Unsuccessful plans request, no error message", context do
    # Set up error in plans request
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_without_message] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # Request should be an error in this case, and error message should
    #  be carried from request
    assert status == :error
    assert msg == "Failed to fetch pricing info: (Plans) (400) Bad Request - Your request was malformed."
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: Unsuccessful machine Tesla request", context do
    # Set up error in machine request
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:tesla_error] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # Check that Tesla errors were passed down
    assert status == :error
    assert msg == "Failed to fetch pricing info: (Machine) Tesla error message placeholder"
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: Unsuccessful plans Tesla request", context do
    # Set up error in plans request
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:tesla_error] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # Check that Tesla errors were passed down
    assert status == :error
    assert msg == "Failed to fetch pricing info: (Plans) Tesla error message placeholder"
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: Unparsable JSON from machine response", context do
    # Set up error in machine request
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:mangled_resp] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # Check that the Jason error was passed down
    assert status == :error
    assert msg == "Failed to fetch pricing info: (Machine) Failed to decode json in response"
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: Unparsable JSON from plans response", context do
    # Set up error in plans request
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:mangled_resp] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # Check that the Jason error was passed down
    assert status == :error
    assert msg == "Failed to fetch pricing info: (Plans) Failed to decode json in response"
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: Missing 'instance' in machine response", context do
    # Set up error in machine request
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_missing_instance_resp] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # Check that response mentions missing attribute
    assert status == :error
    assert msg == "Failed to fetch pricing info: (Machine) Response missing key 'instance'"
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: Missing 'plan_id' attribute in machine", context do
    # Set up error in machine request
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_missing_attributes_resp] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # Check that response mentions missing attribute
    assert status == :error
    assert msg == "Failed to fetch pricing info: (Machine) Error parsing machine"
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: Missing 'plans' in plan response", context do
    # Set up error in plan request
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_missing_plans_resp] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # Check that response mentions missing attribute
    assert status == :error
    assert msg == "Failed to fetch pricing info: (Plans) Response missing key 'plans'"
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: Missing 'monthly_cost' attribute in plan", context do
    # Set up error in plan request
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_missing_attributes_resp] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # Check that response mentions missing attribute
    assert status == :error
    assert msg == "Failed to fetch pricing info: (Plans) Error parsing plan"
  end


  @tag mock: true
  @tag fetch_pricing_info: true
  test "fetch_pricing_info: No matching plan for machine", context do
    # Set up request for missing plan
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_missing_correct] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.fetch_pricing_info("fake API key", context[:machine_id])

    # Check that response mentions no matching plan
    assert status == :error
    assert msg == "Failed to fetch pricing info: Unable to find plan '#{context[:plan_id]}'"
  end
end
