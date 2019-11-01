defmodule PairvizWeb.PageController do
  use PairvizWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
