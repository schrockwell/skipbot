defmodule Skipbot.PageController do
  use Skipbot.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
