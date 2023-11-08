defmodule OracleTest do
  use ExUnit.Case
  doctest Oracle

  @tag :get_node_list
  test "get node list - valid" do
    response = Oracle.get_node_list()
    IO.inspect(response)
  end
end
