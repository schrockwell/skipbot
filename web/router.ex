defmodule Skipbot.Router do
  use Skipbot.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Skipbot.Session
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Skipbot do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    resources "/matches", MatchController, only: [:new, :show]
  end

  # Other scopes may use custom stacks.
  # scope "/api", Skipbot do
  #   pipe_through :api
  # end
end
