defmodule Pairviz.PairingTest do
  use ExUnit.Case
  alias Pairviz.Pairing, as: Pairing

  test "extract pair when it's a simple pairing" do
    assert Pairing.extract_pair(
             "#123 | Pat:Jin | Hello world",
             ~r/^.*|(.*)|.*$/,
             ":"
           ) == ["Pat", "Jin"]
  end
end
