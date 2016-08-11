defmodule Skipbot.Session do
  import Plug.Conn
  
  def init(opts), do: opts

  def call(conn, _opts) do
    player_id = get_session(conn, :player_id) || UUID.uuid4()
    token = Phoenix.Token.sign(conn, "user socket", player_id)

    conn
      |> put_session(:player_id, player_id)
      |> assign(:player_id, player_id)
      |> assign(:user_token, token)
  end
end