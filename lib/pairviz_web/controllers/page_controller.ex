defmodule PairvizWeb.PageController do
  use PairvizWeb, :controller
  alias Pairviz.Git, as: Git
  alias Date

  def index(conn, _params) do
    render(conn, "index.html", matrix: create_matrix())
  end

  def git_pull(conn, _params) do
    {ok, err} =
      Git.repos("repositories")
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
    config = Application.get_env(:pairviz, Pairviz.Pairing)

    Git.repos("repositories")
    |> Enum.flat_map(&Git.log/1)
    |> Pairviz.Pairing.calculate_pairing_score(
      config[:name_pattern],
      config[:name_splitter],
      config[:name_list]
    )
    |> Pairviz.Pairing.make_matrix(fn score ->
      {score, Pairviz.Color.to_viridis(score)}
    end)
  end
end
