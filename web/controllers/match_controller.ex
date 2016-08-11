defmodule Skipbot.MatchController do
  use Skipbot.Web, :controller

  def new(conn, _) do
    id = Skipbot.Match.create(hand: 7)
    conn |> redirect(to: match_path(conn, :show, id))
  end

  def show(conn, %{"id" => id}) do
    case Skipbot.PidLookup.get(id) do
      nil -> conn |> put_status(:not_found) |> render(Skipbot.ErrorView, "404.html")
      _ -> conn |> render("show.html", id: id, player_id: conn.assigns[:player_id])
    end
  end
end