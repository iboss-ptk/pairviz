defmodule PairvizWeb.Router do
  use PairvizWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PairvizWeb do
    pipe_through :browser

    get "/", PageController, :index
    post "/update", PageController, :git_pull
  end

  # Other scopes may use custom stacks.
  # scope "/api", PairvizWeb do
  #   pipe_through :api
  # end
end
