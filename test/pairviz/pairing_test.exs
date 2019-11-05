defmodule Pairviz.PairingTest do
  use ExUnit.Case
  alias Pairviz.Pairing, as: Pairing

  @pipe_around_name ~r/^.*\| (?<names>.*) \|.*$/
  @bracket_around_name ~r/^.*\[ (?<names>.*) \].*$/

  test "extract pair can config pattern that capture names and its splitter" do
    assert Pairing.extract_pair("#123 | Pat:Jin | Hello world", @pipe_around_name, ":") ==
             {:ok, ["Pat", "Jin"]}

    assert Pairing.extract_pair("#123 | Nate,Jones | Hello world", @pipe_around_name, ",") ==
             {:ok, ["Nate", "Jones"]}

    assert Pairing.extract_pair("[ Pat:Jin ] Hello world", @bracket_around_name, ":") ==
             {:ok, ["Pat", "Jin"]}
  end

  test "extract pair failed when no name found" do
    assert Pairing.extract_pair("#123 Hello world", @pipe_around_name, ":") ==
             {:error, "name can't be found"}
  end

  test "extract pair allow multiple splitters" do
    assert Pairing.extract_pair("#123 | Nate&Jones | Hello world", @pipe_around_name, [":", "&"]) ==
             {:ok, ["Nate", "Jones"]}
  end
end
