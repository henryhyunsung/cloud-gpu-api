defmodule ListMachineMimicTest do
  use ExUnit.Case
  use Mimic

  setup_all do
    machine_id = "a5463157-703a-44a4-bf22-b282f3ae3c34"
    plan_id = "vcg-a16-2c-4g-1vram"
    gpu_details = %{
      count: 2,
      count_str: "2",
      type: "NVIDIA_A16",
      memory_gb: 1,
      memory_mb: 1024
    }

    # Two paged response to test listing machines
    machines_success_page1 = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: Jason.encode!(%{
          instances: [
            %{
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
              power_status: "running",
              tag: "",
              tags: [],
              v6_main_ip: "2401:c080:1400:5c79:0ec4:7aff:fe88:d26b",
              v6_network: "2401:c080:1400:5c79::",
              v6_network_size: 64
            }
          ],
          meta: %{total: 2, links: %{next: "page2_link", prev: ""}
          }
        })
      }
    }
    machines_success_page2 = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: Jason.encode!(%{
          instances: [
            %{
              app_id: 0,
              cpu_count: 4,
              date_created: "2024-09-21T04:02:25+00:00",
              disk: nil,
              features: ["ipv6"],
              gateway_v4: "123.43.212.34",
              id: "12345678-abcd-1234-1234-12345678abcd",
              image_id: "",
              internal_ip: "",
              label: "Other machine",
              mac_address: 14038008910444,
              main_ip: "43.212.34.32",
              netmask_v4: "255.255.254.0",
              os: "Ubuntu 22.04 LTS x64",
              os_id: 1743,
              plan: "not-a-plan",
              ram: "32768 MB",
              region: "sgp",
              power_status: "running",
              tag: "",
              tags: [],
              v6_main_ip: "2401:c080:1400:5c79:abcd:abcd:abcd:abcd",
              v6_network: "2401:c080:1400:5c79::",
              v6_network_size: 64
            }
          ],
          meta: %{total: 2, links: %{next: "", prev: "page1_link"}
          }
        })
      }
    }

    # Single response for a machine
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
            power_status: "running",
            tag: "",
            tags: [],
            v6_main_ip: "2401:c080:1400:5c79:0ec4:7aff:fe88:d26b",
            v6_network: "2401:c080:1400:5c79::",
            v6_network_size: 64
          }
        })
      }
    }

    # Respponse for plans
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
              id: "not-a-plan",
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
              gpu_type: gpu_details[:type],
              gpu_vram_gb: gpu_details[:memory_gb],
              id: plan_id,
              locations: ["ewr", "ord", "lhr", "fra", "sjc", "nrt", "blr"],
              monthly_cost: 21.5,
              ram: 4096,
              type: "vcg",
              vcpu_count: gpu_details[:count]
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
          meta: %{total: 3, links: %{next: "", prev: ""}}
        })
      }
    }

    # 429 error with message
    error_with_message = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 429,
        body: Jason.encode!(%{
          error: "uh oh rate limit!"
        })
      }
    }

    # 429 error without message
    error_without_message = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 429,
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

    # Machine response missing 'instance' attribute
    machine_missing_instance_resp = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: Jason.encode!(%{
          inskunglo: %{ # Renamed
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
            power_status: "running",
            tag: "",
            tags: [],
            v6_main_ip: "2401:c080:1400:5c79:0ec4:7aff:fe88:d26b",
            v6_network: "2401:c080:1400:5c79::",
            v6_network_size: 64
          }
        })
      }
    }

    # Machines response missing 'instances' attribute
    machines_missing_instance_resp = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: Jason.encode!(%{
          insplorgo: [ # Renamed
            %{
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
              power_status: "running",
              tag: "",
              tags: [],
              v6_main_ip: "2401:c080:1400:5c79:0ec4:7aff:fe88:d26b",
              v6_network: "2401:c080:1400:5c79::",
              v6_network_size: 64
            },
            %{
              app_id: 0,
              cpu_count: 4,
              date_created: "2024-09-21T04:02:25+00:00",
              disk: nil,
              features: ["ipv6"],
              gateway_v4: "123.43.212.34",
              id: "12345678-abcd-1234-1234-12345678abcd",
              image_id: "",
              internal_ip: "",
              label: "Other machine",
              mac_address: 14038008910444,
              main_ip: "43.212.34.32",
              netmask_v4: "255.255.254.0",
              os: "Ubuntu 22.04 LTS x64",
              os_id: 1743,
              plan: "not-a-plan",
              ram: "32768 MB",
              region: "sgp",
              power_status: "running",
              tag: "",
              tags: [],
              v6_main_ip: "2401:c080:1400:5c79:abcd:abcd:abcd:abcd",
              v6_network: "2401:c080:1400:5c79::",
              v6_network_size: 64
            }
          ],
          meta: %{total: 2, links: %{next: "", prev: ""}
          }
        })
      }
    }

    # Plans response with missing 'plans' attribute
    plans_missing_plans_resp = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: Jason.encode!(%{
          plinkos: [ # Renamed
            %{
              bandwidth: 2048,
              disk: 40,
              disk_count: 1,
              gpu_type: "NVIDIA_A40",
              gpu_vram_gb: 1,
              id: "not-a-plan",
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
              gpu_type: gpu_details[:type],
              gpu_vram_gb: gpu_details[:memory_gb],
              id: plan_id,
              locations: ["ewr", "ord", "lhr", "fra", "sjc", "nrt", "blr"],
              monthly_cost: 21.5,
              ram: 4096,
              type: "vcg",
              vcpu_count: gpu_details[:count]
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
          meta: %{total: 3, links: %{next: "", prev: ""}}
        })
      }
    }

    # Machine response with machine missing values
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
            power_status: "running",
            tag: "",
            tags: [],
            v6_main_ip: "2401:c080:1400:5c79:0ec4:7aff:fe88:d26b",
            v6_network: "2401:c080:1400:5c79::",
            v6_network_size: 64
          }
        })
      }
    }

    # Machines response with machine missing values
    machines_missing_attributes_resp = {
      :ok,
      %Tesla.Env{
        method: :get,
        status: 200,
        body: Jason.encode!(%{
          instances: [
            %{
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
              power_status: "running",
              tag: "",
              tags: [],
              v6_main_ip: "2401:c080:1400:5c79:0ec4:7aff:fe88:d26b",
              v6_network: "2401:c080:1400:5c79::",
              v6_network_size: 64
            },
            %{
              app_id: 0,
              cpu_count: 4,
              date_created: "2024-09-21T04:02:25+00:00",
              disk: nil,
              features: ["ipv6"],
              gateway_v4: "123.43.212.34",
              id: "12345678-abcd-1234-1234-12345678abcd",
              image_id: "",
              internal_ip: "",
              label: "Other machine",
              mac_address: 14038008910444,
              main_ip: "43.212.34.32",
              netmask_v4: "255.255.254.0",
              os: "Ubuntu 22.04 LTS x64",
              os_id: 1743,
              plan: "not-a-plan",
              ram: "32768 MB",
              region: "sgp",
              power_status: "running",
              tag: "",
              tags: [],
              v6_main_ip: "2401:c080:1400:5c79:abcd:abcd:abcd:abcd",
              v6_network: "2401:c080:1400:5c79::",
              v6_network_size: 64
            }
          ],
          meta: %{total: 2, links: %{next: "", prev: ""}
          }
        })
      }
    }

    # Plans response with plan missing values
    plans_missing_attributes_resp = {
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
              # Missing plan ID
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
              gpu_type: gpu_details[:type],
              gpu_vram_gb: gpu_details[:memory_gb],
              id: plan_id,
              locations: ["ewr", "ord", "lhr", "fra", "sjc", "nrt", "blr"],
              monthly_cost: 21.5,
              ram: 4096,
              type: "vcg",
              vcpu_count: gpu_details[:count]
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
          meta: %{total: 3, links: %{next: "", prev: ""}}
        })
      }
    }


    # Plans with no matching for a certain machine
    # TODO

    # Our context
    {
      :ok,
      machine_id: machine_id,
      plan_id: plan_id,
      gpu_details: gpu_details,
      machines_success_page1: machines_success_page1,
      machines_success_page2: machines_success_page2,
      machine_success: machine_success,
      plans_success: plans_success,
      error_with_message: error_with_message,
      error_without_message: error_without_message,
      tesla_error: tesla_error,
      mangled_resp: mangled_resp,
      machine_missing_instance_resp: machine_missing_instance_resp,
      machines_missing_instance_resp: machines_missing_instance_resp,
      plans_missing_plans_resp: plans_missing_plans_resp,
      machine_missing_attributes_resp: machine_missing_attributes_resp,
      machines_missing_attributes_resp: machines_missing_attributes_resp,
      plans_missing_attributes_resp: plans_missing_attributes_resp
    }
  end


  #####################################
  # List Machines: Successful Request #
  #####################################
  @tag mock: true
  @tag listing: true
  @tag list_machines: true
  test "list_machines: Successful paginated request", context do
    # Set up responses for two pages
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page1] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page2] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, machines} = Vultr.list_machines("fake API key")

    # Request should be successful, with two machines
    assert status == :ok
    assert length(machines) == 2

    # Check hardcoded machine1 has been parsed correctly
    machine = hd(machines)
    assert machine[:instance_id] == context[:machine_id]
    assert machine[:name] == "TestMachine"
    assert machine[:zone] == "sgp"
    assert machine[:description] == nil
    assert machine[:machine_type] == context[:plan_id]
    assert machine[:external_ip] == "207.148.120.182"
    assert machine[:internal_ip] == nil
    assert machine[:os_type] == "Ubuntu 22.04 LTS x64"
    # assert machine[:billing_type] == :on_demand
    assert machine[:preemptible] == nil
    assert machine[:accelerator_count] == context[:gpu_details][:count_str]
    assert machine[:accelerator_type] == context[:gpu_details][:type]
    assert machine[:accelerator_memory] == context[:gpu_details][:memory_mb]
    assert machine[:status] == :Running
  end


  ################################################
  # List Machines: Unsuccessful machine fetching #
  ################################################
  @tag mock: true
  @tag listing: true
  @tag list_machines: true
  test "list_machines: Unsuccessful machines request, error message", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_with_message] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machines("fake API key")

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machines: (Machines) uh oh rate limit!"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machines: true
  test "list_machines: Unsuccessful machines request, no error message", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_without_message] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machines("fake API key")

    # Request should fail, with default message
    assert status == :error
    assert msg == "Failed to list machines: (Machines) (429) Too Many Requests - Your request exceeded the API rate limit."
  end


  @tag mock: true
  @tag listing: true
  @tag list_machines: true
  test "list_machines: Unsuccessful machines Tesla request", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:tesla_error] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machines("fake API key")

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machines: (Machines) Tesla error message placeholder"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machines: true
  test "list_machines: Unparsable machines JSON from request", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:mangled_resp] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machines("fake API key")

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machines: (Machines) Failed to decode json in response"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machines: true
  test "list_machines: Missing 'instances' in machines response", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_missing_instance_resp] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machines("fake API key")

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machines: (Machines) Response missing key 'instances'"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machines: true
  test "list_machines: Missing 'plan_id' attribute in machines response", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_missing_attributes_resp] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machines("fake API key")

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machines: (Machine) Error parsing machine"
  end


  ##############################################
  # List Machines: Unsuccessful plans fetching #
  ##############################################
  @tag mock: true
  @tag listing: true
  @tag list_machines: true
  test "list_machines: Unsuccessful plans request, error message", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page1] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page2] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_with_message] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machines("fake API key")

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machines: (Plans) uh oh rate limit!"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machines: true
  test "list_machines: Unsuccessful plans request, no error message", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page1] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page2] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_without_message] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machines("fake API key")

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machines: (Plans) (429) Too Many Requests - Your request exceeded the API rate limit."
  end


  @tag mock: true
  @tag listing: true
  @tag list_machines: true
  test "list_machines: Unsuccessful plans Tesla request", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page1] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page2] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:tesla_error] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machines("fake API key")

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machines: (Plans) Tesla error message placeholder"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machines: true
  test "list_machines: Unparsable plans JSON from request", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page1] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page2] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:mangled_resp] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machines("fake API key")

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machines: (Plans) Failed to decode json in response"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machines: true
  test "list_machines: Missing 'plans' in plans response", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page1] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page2] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_missing_plans_resp] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machines("fake API key")

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machines: (Plans) Response missing key 'plans'"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machines: true
  test "list_machines: Missing 'plan_id' attribute in plans response", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page1] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machines_success_page2] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_missing_attributes_resp] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machines("fake API key")

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machines: (Plans) Error parsing plan"
  end


  ####################################
  # List Machine: Successful Request #
  ####################################
  @tag mock: true
  @tag listing: true
  @tag list_machine: true
  test "list_machine: Successful request", context do
    # Set up responses for single machine
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, machine} = Vultr.list_machine("fake API key", context[:machine_id])

    # Request should be successful
    assert status == :ok

    # Request should contain all the hardcoded machine details
    assert machine[:instance_id] == context[:machine_id]
    assert machine[:name] == "TestMachine"
    assert machine[:zone] == "sgp"
    assert machine[:description] == nil
    assert machine[:machine_type] == context[:plan_id]
    assert machine[:external_ip] == "207.148.120.182"
    assert machine[:internal_ip] == nil
    assert machine[:os_type] == "Ubuntu 22.04 LTS x64"
    # assert machine[:billing_type] == :on_demand
    assert machine[:preemptible] == nil
    assert machine[:accelerator_count] == context[:gpu_details][:count_str]
    assert machine[:accelerator_type] == context[:gpu_details][:type]
    assert machine[:accelerator_memory] == context[:gpu_details][:memory_mb]
    assert machine[:status] == :Running
  end


  ###############################################
  # List Machine: Unsuccessful machine fetching #
  ###############################################
  @tag mock: true
  @tag listing: true
  @tag list_machine: true
  test "list_machine: Unsuccessful machine request, error message", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_with_message] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machine("fake API key", context[:machine_id])

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machine: (Machine) uh oh rate limit!"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machine: true
  test "list_machine: Unsuccessful machine request, no error message", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_without_message] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machine("fake API key", context[:machine_id])

    # Request should fail, with default message
    assert status == :error
    assert msg == "Failed to list machine: (Machine) (429) Too Many Requests - Your request exceeded the API rate limit."
  end


  @tag mock: true
  @tag listing: true
  @tag list_machine: true
  test "list_machine: Unsuccessful machine Tesla request", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:tesla_error] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machine("fake API key", context[:machine_id])

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machine: (Machine) Tesla error message placeholder"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machine: true
  test "list_machine: Unparsable machine JSON from request", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:mangled_resp] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machine("fake API key", context[:machine_id])

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machine: (Machine) Failed to decode json in response"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machine: true
  test "list_machine: Missing 'instance' in machine response", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_missing_instance_resp] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machine("fake API key", context[:machine_id])

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machine: (Machine) Response missing key 'instance'"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machine: true
  test "list_machine: Missing 'plan_id' attribute in machine response", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_missing_attributes_resp] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_success] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machine("fake API key", context[:machine_id])

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machine: (Machine) Error parsing machine"
  end


  #############################################
  # List Machine: Unsuccessful plans fetching #
  #############################################
  @tag mock: true
  @tag listing: true
  @tag list_machine: true
  test "list_machine: Unsuccessful plans request, error message", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_with_message] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machine("fake API key", context[:machine_id])

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machine: (Plans) uh oh rate limit!"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machine: true
  test "list_machine: Unsuccessful plans request, no error message", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:error_without_message] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machine("fake API key", context[:machine_id])

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machine: (Plans) (429) Too Many Requests - Your request exceeded the API rate limit."
  end


  @tag mock: true
  @tag listing: true
  @tag list_machine: true
  test "list_machine: Unsuccessful plans Tesla request", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:tesla_error] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machine("fake API key", context[:machine_id])

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machine: (Plans) Tesla error message placeholder"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machine: true
  test "list_machine: Unparsable plans JSON from request", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:mangled_resp] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machine("fake API key", context[:machine_id])

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machine: (Plans) Failed to decode json in response"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machine: true
  test "list_machine: Missing 'plans' in plans response", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_missing_plans_resp] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machine("fake API key", context[:machine_id])

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machine: (Plans) Response missing key 'plans'"
  end


  @tag mock: true
  @tag listing: true
  @tag list_machine: true
  test "list_machine: Missing 'plan_id' attribute in plans response", context do
    # Set up error
    Vultr.TeslaWrappers
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:machine_success] end)
      |> expect(:tesla_get, 1, fn _, _, _ -> context[:plans_missing_attributes_resp] end)
      |> stub(:tesla_get, fn _, _, _ -> :stub end)

    # Make request
    {status, msg} = Vultr.list_machine("fake API key", context[:machine_id])

    # Request should fail, with message
    assert status == :error
    assert msg == "Failed to list machine: (Plans) Error parsing plan"
  end




  # TODO: Test for no match for plan/machine combo
  # TODO: Test for reading status

end
