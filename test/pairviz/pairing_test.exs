defmodule Pairviz.PairingTest do
  use ExUnit.Case
  alias Pairviz.Pairing, as: Pairing

  # `extract_pairs/3`

  @pipe_around_name ~r/^.*\|(?<names>.*)\|.*$/
  @bracket_around_name ~r/^.*\[(?<names>.*)\].*$/
  @pipe_or_bracket_around_name [@pipe_around_name, @bracket_around_name]

  test "extract pair can config pattern that capture names and its splitter" do
    assert Pairing.extract_pairs("#123 | Pat:Jin | Hello world", @pipe_around_name, ":") ==
             {:ok, [["Jin", "Pat"]]}

    assert Pairing.extract_pairs("#123 | Nate,Jones | Hello world", @pipe_around_name, ",") ==
             {:ok, [["Jones", "Nate"]]}

    assert Pairing.extract_pairs("[ Pat:Jin ] Hello world", @bracket_around_name, ":") ==
             {:ok, [["Jin", "Pat"]]}

    assert Pairing.extract_pairs("[ Pat :  Jin ] Hello world", @bracket_around_name, ":") ==
             {:ok, [["Jin", "Pat"]]}
  end

  test "extract self pairing" do
    assert Pairing.extract_pairs("#123 | Dan | Hello world", @pipe_around_name, ":") ==
             {:ok, [["Dan", "Dan"]]}
  end

  test "extract pair failed when no name found" do
    assert Pairing.extract_pairs("#123 Hello world", @pipe_around_name, ":") ==
             {:error, "name can't be extracted"}
  end

  test "extract pair allow multiple splitters" do
    assert Pairing.extract_pairs("#123 | Nate&Jones | Hello world", @pipe_around_name, [":", "&"]) ==
             {:ok, [["Jones", "Nate"]]}
  end

  test "extract pair normalize the name by capitalizing it" do
    assert Pairing.extract_pairs("#123 | Nate&jones | Hello world", @pipe_around_name, [":", "&"]) ==
             {:ok, [["Jones", "Nate"]]}
  end

  test "extract pair allow multiple patterns" do
    assert Pairing.extract_pairs(
             "#123 | Nate&Jones | Hello world",
             @pipe_or_bracket_around_name,
             "&"
           ) ==
             {:ok, [["Jones", "Nate"]]}

    assert Pairing.extract_pairs(
             "#123 [ Nate&Jones ] Hello world",
             @pipe_or_bracket_around_name,
             "&"
           ) ==
             {:ok, [["Jones", "Nate"]]}
  end

  test "extract multiple pairs" do
    assert Pairing.extract_pairs("#123 | Nate&Jones&Thomas | Hello world", @pipe_around_name, "&") ==
             {:ok, [["Jones", "Nate"], ["Nate", "Thomas"], ["Jones", "Thomas"]]}

    assert Pairing.extract_pairs("#123 | Nate &Jones : Thomas | Hello world", @pipe_around_name, [
             "&",
             ":"
           ]) ==
             {:ok, [["Jones", "Nate"], ["Nate", "Thomas"], ["Jones", "Thomas"]]}
  end

  test "extract only whitelisted name" do
    assert Pairing.extract_pairs("#123 | Nate&Jones&Thomas | Hello world", @pipe_around_name, "&", ["Nate", "Jones"]) ==
             {:ok, [["Jones", "Nate"]]}

    assert Pairing.extract_pairs("#123 | Nate &Jones | Hello world", @pipe_around_name, "&", ["Nate"]) ==
             {:ok, [["Nate", "Nate"]]}

    assert Pairing.extract_pairs("#123 | Nate &Jones | Hello world", @pipe_around_name, "&", ["Kim"]) ==
             {:ok, []}
  end

  # `calculate_pairing_score`

  test "calculate pairing score by only counting days that people paired with decay" do
    commits = [
      %{date: ~D[2019-10-02], message: "#123 | Jones & Nate | Hello world another day"},
      %{date: ~D[2019-10-02], message: "#123 [Kim & Ken & Jones ] Hello world from kk"},
      %{date: ~D[2019-10-01], message: "#123 | Nate: Jones | Hello world 2"},
      %{date: ~D[2019-10-01], message: "#123 | Nate&Jones | Hello world 1"},
      %{date: ~D[2019-10-01], message: "#123 | Nate&Nate | narcisist"},
      %{date: ~D[2019-10-01], message: "random commit"}
    ]

    # 2019-10-02 (coeff == 1)
    # ["Jones", "Nate"] => 1,
    # ["Jones", "Ken"] => 1,
    # ["Jones", "Kim"] => 1,
    # ["Ken", "Kim"] => 1,

    # 2019-10-01 (coeff == 0)
    # ["Jones", "Nate"] => 0,
    # ["Nate", "Nate"] => 0

    assert Pairing.calculate_pairing_score(commits, @pipe_or_bracket_around_name, [":", "&"]) ==
             %{
               ["Jones", "Nate"] => 0.25,
               ["Jones", "Ken"] => 0.25,
               ["Jones", "Kim"] => 0.25,
               ["Ken", "Kim"] => 0.25,
               ["Nate", "Nate"] => 0
             }
  end

  # `make_matrix`

  test "create empty matrix if there is no pair so far" do
    assert Pairing.make_matrix(%{}) == %{labels: [], matrix: []}
  end

  test "create 1x1 matrix if there is 1 people in the pool" do
    assert Pairing.make_matrix(%{["Jones", "Jones"] => 1}) == %{
             labels: [
               "Jones"
             ],
             matrix: [[1]]
           }
  end

  test "create 2x2 matrix if there is 2 people in the pool" do
    assert Pairing.make_matrix(%{["Jones", "Nate"] => 2}) == %{
             labels: [
               "Jones",
               "Nate"
             ],
             matrix: [
               [0, 2],
               [2, 0]
             ]
           }
  end

  test "create 3x3 matrix if there is 3 people in the pool" do
    assert Pairing.make_matrix(%{
             ["Jones", "Nate"] => 2,
             ["Ken", "Nate"] => 1
           }) == %{
             labels: [
               "Jones",
               "Ken",
               "Nate"
             ],
             matrix: [
               [0, 0, 2],
               [0, 0, 1],
               [2, 1, 0]
             ]
           }
  end

  # `decay_coeff` 

  test "if the date is at max date, the coeff is 1" do
    assert Pairing.decay_coeff(~D[2019-10-02], ~D[2019-10-02], ~D[2019-10-01]) == 1
  end

  test "if the date is at min date, the coeff is 0" do
    assert Pairing.decay_coeff(~D[2019-10-01], ~D[2019-10-02], ~D[2019-10-01]) == 0
  end

  test "if the date is in between min and max date, the coeff is (date - min_date) / (max_date - min_date)" do
    assert Pairing.decay_coeff(~D[2019-10-02], ~D[2019-10-03], ~D[2019-10-01]) == 1 / 2
    assert Pairing.decay_coeff(~D[2018-10-01], ~D[2018-10-30], ~D[2018-09-01]) == 30 / 59
  end

  test "if the date is less than min date or greater than max date, it raise `date is out of range`" do
    assert_raise RuntimeError, ~r/^date is out of range/, fn ->
      Pairing.decay_coeff(~D[2019-09-30], ~D[2019-10-02], ~D[2019-10-01])
    end

    assert_raise RuntimeError, ~r/^date is out of range/, fn ->
      Pairing.decay_coeff(~D[2019-10-03], ~D[2019-10-02], ~D[2019-10-01])
    end
  end

  test "if the max date is less than min date, it raise `max date must be greater than min date`" do
    assert_raise RuntimeError, ~r/^max date must be greater than min date/, fn ->
      Pairing.decay_coeff(~D[2019-09-30], ~D[2019-09-30], ~D[2019-10-01])
    end
  end
end
