defmodule PairvizWeb.PageController do
  use PairvizWeb, :controller
  alias Pairviz.Git, as: Git
  alias Date

  def index(conn, _params) do
    # put all related repos into the same dir
    repos = ["exrepa"]

    commits =
      repos
      |> Enum.flat_map(fn repo ->
        Git.pull(repo)
        Git.log(repo)
      end)
      |> Enum.map(fn %{date: date, message: message} -> "[#{date}] #{message}" end)

    # collect commits, group them by date
    # group all of them again by date => {date, [commits]}
    # extract person id => { date, [p1, p2] } and [p1, p2] == [p2, p1] then uniq by date
    # decay

    # note: need to think about how to test. -> prep repos
    # deal with ssh later

    render(conn, "index.html", commits: commits)
  end
end
