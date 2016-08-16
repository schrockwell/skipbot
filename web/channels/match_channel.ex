defmodule Skipbot.MatchChannel do
  use Skipbot.Web, :channel

  alias Skipbot.Match

  def join(topic = "match:" <> id, _params, socket) do
    [pid | _] = :pg2.get_members(id)

    case pid do
      nil -> {:error, %{reason: "Match does not exist"}}
      _ -> 
        resp = Match.add_player(pid, socket.assigns[:player_id])
        Skipbot.Endpoint.broadcast(topic, "game", resp)

        {:ok, resp, assign(socket, :match_id, id)}
    end
  end

  def terminate(_reason, socket) do
    [pid | _] = :pg2.get_members(socket.assigns[:match_id])
    resp = Match.remove_player(pid, socket.assigns[:player_id])
    Skipbot.Endpoint.broadcast("match:" <> socket.assigns[:match_id], "game", resp)
  end

  def handle_in(event, params, socket) do
    [pid | _] = :pg2.get_members(socket.assigns[:match_id])
    Match.extend_timeout(pid)
    handle_in(event, params, socket.assigns[:player_id], pid, socket)
  end

  def handle_in("start_game", _params, _player_id, pid, socket) do
    Match.start_game(pid)
    broadcast_game(socket, pid)
    {:reply, :ok, socket}
  end

  def handle_in("discard", %{"card_index" => card_index, "discard_index" => discard_index}, _player_id, pid, socket) do
    # TODO: Authenticate
    Match.discard(pid, card_index, discard_index)
    broadcast_game(socket, pid)
    {:reply, :ok, socket}
  end

  def handle_in("discard_and_end_turn", %{"card_index" => card_index, "discard_index" => discard_index}, _player_id, pid, socket) do
    # TODO: Authenticate
    Match.discard_and_end_turn(pid, card_index, discard_index)
    broadcast_game(socket, pid)
    {:reply, :ok, socket}
  end

  def handle_in("build_from_stock", %{"build_index" => build_index}, _player_id, pid, socket) do
    # TODO: Authenticate
    Match.build_from_stock(pid, build_index)
    broadcast_game(socket, pid)
    {:reply, :ok, socket}
  end

  def handle_in("build_from_hand", %{"card_index" => card_index, "build_index" => build_index}, _player_id, pid, socket) do
    # TODO: Authenticate
    Match.build_from_hand(pid, card_index, build_index)
    broadcast_game(socket, pid)
    {:reply, :ok, socket}
  end

  def handle_in("build_from_discard", %{"discard_index" => discard_index, "build_index" => build_index}, _player_id, pid, socket) do
    # TODO: Authenticate
    Match.build_from_discard(pid, discard_index, build_index)
    broadcast_game(socket, pid)
    {:reply, :ok, socket}
  end


  defp broadcast_game(socket, pid) do
    Skipbot.Endpoint.broadcast(socket.topic, "game", Match.get(pid))
    socket
  end
end