defmodule Pairviz.PairingTest do
  use ExUnit.Case
  alias Pairviz.Pairing, as: Pairing

  # `extract_pairs/3`

  @pipe_around_name ~r/^.*\| (?<names>.*) \|.*$/
  @bracket_around_name ~r/^.*\[ (?<names>.*) \].*$/

  test "extract pair can config pattern that capture names and its splitter" do
    assert Pairing.extract_pairs("#123 | Pat:Jin | Hello world", @pipe_around_name, ":") ==
             {:ok, [["Pat", "Jin"]]}

    assert Pairing.extract_pairs("#123 | Nate,Jones | Hello world", @pipe_around_name, ",") ==
             {:ok, [["Nate", "Jones"]]}

    assert Pairing.extract_pairs("[ Pat:Jin ] Hello world", @bracket_around_name, ":") ==
             {:ok, [["Pat", "Jin"]]}

    assert Pairing.extract_pairs("[ Pat :  Jin ] Hello world", @bracket_around_name, ":") ==
             {:ok, [["Pat", "Jin"]]}
  end

  test "extract self pairing" do
    assert Pairing.extract_pairs("#123 | Dan | Hello world", @pipe_around_name, ":") ==
             {:ok, [["Dan", "Dan"]]}
  end

  test "extract pair failed when no name found" do
    assert Pairing.extract_pairs("#123 Hello world", @pipe_around_name, ":") ==
             {:error, "name can't be found"}
  end

  test "extract pair allow multiple splitters" do
    assert Pairing.extract_pairs("#123 | Nate&Jones | Hello world", @pipe_around_name, [":", "&"]) ==
             {:ok, [["Nate", "Jones"]]}
  end

  test "extract multiple pairs" do
    assert Pairing.extract_pairs("#123 | Nate&Jones&Thomas | Hello world", @pipe_around_name, "&") ==
             {:ok, [["Nate", "Jones"], ["Nate", "Thomas"], ["Jones", "Thomas"]]}

    assert Pairing.extract_pairs("#123 | Nate &Jones : Thomas | Hello world", @pipe_around_name, [
             "&",
             ":"
           ]) ==
             {:ok, [["Nate", "Jones"], ["Nate", "Thomas"], ["Jones", "Thomas"]]}
  end

  # `calculate_pairing_score`

  test "calculate pairing score by only counting days that people paired" do
    commits = [
      %{date: ~D[2019-10-02], message: "#123 | Nate & Jones | Hello world another day"},
      %{date: ~D[2019-10-02], message: "#123 | Kim & Ken | Hello world from kk"},
      %{date: ~D[2019-10-01], message: "#123 | Nate&Jones | Hello world 2"},
      %{date: ~D[2019-10-01], message: "#123 | Nate&Jones | Hello world 1"}
    ]

    Pairing.calculate_pairing_score(commits) == %{
      ["Nate", "Jones"] => 2,
      ["Kim", "Ken"] => 2
    }
  end
end
