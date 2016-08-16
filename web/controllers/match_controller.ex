defmodule Skipbot.MatchController do
  use Skipbot.Web, :controller

  def new(conn, _) do
    id = Skipbot.Match.create(hand: 7)
    conn |> redirect(to: match_path(conn, :show, id))
  end

  def show(conn, %{"id" => id}) do
    case :pg2.get_members(id) do
      {:error, {:no_such_group,  _}} -> conn |> put_status(:not_found) |> render(Skipbot.ErrorView, "404.html")
      [] -> conn |> put_status(:not_found) |> render(Skipbot.ErrorView, "404.html")
      [_ | _] -> conn |> render("show.html", id: id, player_id: conn.assigns[:player_id])
    end
  end
end