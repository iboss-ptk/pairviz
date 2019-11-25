defmodule PairvizWeb.PageController do
  use PairvizWeb, :controller
  alias Pairviz.Git, as: Git
  alias Date

  def index(conn, _params) do
    pipe_around_name = ~r/^.*\|(?<names>.*)\|.*$/
    bracket_around_name = ~r/^.*\[(?<names>.*)\].*$/

    matrix =
      Git.repos()
      |> Enum.flat_map(fn repo ->
        # TODO: handle error but only give warning
        Git.pull(repo)
        Git.log(repo)
      end)
      |> Pairviz.Pairing.calculate_pairing_score(
        [pipe_around_name, bracket_around_name],
        [":", "&"]
      )
      |> Pairviz.Pairing.make_matrix(fn score ->
        {score, Pairviz.Color.to_viridis(score)}
      end)

    render(conn, "index.html", matrix: matrix)
  end
end
