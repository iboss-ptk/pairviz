defmodule PairvizWeb.PageController do
  use PairvizWeb, :controller
  alias Pairviz.Git, as: Git
  alias Date

  def index(conn, _params) do
    render(conn, "index.html", matrix: create_matrix())
  end

  def git_pull(conn, _params) do
    {ok, err} =
      Git.repos()
      |> Enum.map(&Git.pull/1)
      |> Enum.split_with(fn
        {:ok, _res} -> true
        _ -> false
      end)

    conn
    |> put_flash(:info, ok)
    |> put_flash(:error, err)
    |> redirect(to: "/", matrix: create_matrix())
  end

  defp create_matrix() do
    pipe_around_name = ~r/^.*\|(?<names>.*)\|.*$/
    bracket_around_name = ~r/^.*\[(?<names>.*)\].*$/

    Git.repos()
    |> Enum.flat_map(&Git.log/1)
    |> Pairviz.Pairing.calculate_pairing_score(
      [pipe_around_name, bracket_around_name],
      [":", "&"]
    )
    |> Pairviz.Pairing.make_matrix(fn score ->
      {score, Pairviz.Color.to_viridis(score)}
    end)
  end
end
