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
      |> Pairviz.Pairing.make_matrix(&Pairviz.Color.to_viridis/1)

    # collect commits, group them by date
    # group all of them again by date => {date, [commits]}
    # extract person id => { date, [p1, p2] } and [p1, p2] == [p2, p1] then uniq by date
    # decay

    # note: need to think about how to test. -> prep repos
    # deal with ssh later

    render(conn, "index.html", matrix: matrix)
  end
end
