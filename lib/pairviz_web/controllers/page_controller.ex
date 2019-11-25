defmodule PairvizWeb.PageController do
  use PairvizWeb, :controller
  alias Pairviz.Git, as: Git
  alias Date

  def index(conn, _params) do
    pipe_around_name = ~r/^.*\|(?<names>.*)\|.*$/
    bracket_around_name = ~r/^.*\[(?<names>.*)\].*$/

    matrix =
      Git.repos()
      |> Enum.flat_map(&Git.log/1)
      |> Pairviz.Pairing.calculate_pairing_score(
        [pipe_around_name, bracket_around_name],
        [":", "&"]
      )
      |> Pairviz.Pairing.make_matrix(fn score ->
        {score, Pairviz.Color.to_viridis(score)}
      end)

    render(conn, "index.html", matrix: matrix)
  end

  def git_pull(conn, params) do
    Git.repos()
    |> Enum.map(fn repo ->
      # TODO: handle error but only give warning
      Git.pull(repo)
    end)
    index(conn, params)
  end
end
