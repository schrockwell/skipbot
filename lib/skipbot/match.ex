defmodule Skipbot.Match do
  use GenServer

  alias Skipbot.Game
  alias Skipbot.Match
  alias Skipbot.PidLookup

  #
  # GenServer Client API
  #

  def create(opts \\ []) do
    pid = Match.start_link(opts)
    Match.get_id(pid)
  end

  def start_link(opts \\ []) do
    {:ok, pid} = GenServer.start_link(Match, opts, [])
    pid
  end

  def start_game(pid) do
    GenServer.call(pid, :start_game)
  end

  def add_player(pid, player) do
    GenServer.call(pid, {:add_player, player})
  end

  def remove_player(pid, player) do
    GenServer.call(pid, {:remove_player, player})
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def get_id(pid) do
    GenServer.call(pid, :get_id)
  end

  def build_from_hand(pid, card_index, build_index) do
    GenServer.call(pid, {:build_from_hand, card_index, build_index})
  end

  def build_from_stock(pid, build_index) do
    GenServer.call(pid, {:build_from_stock, build_index})
  end

  def build_from_discard(pid, discard_index, build_index) do
    GenServer.call(pid, {:build_from_discard, discard_index, build_index})
  end

  def discard(pid, card_index, discard_index) do
    GenServer.call(pid, {:discard, card_index, discard_index})
  end

  def discard_and_end_turn(pid, card_index, discard_index) do
    GenServer.call(pid, {:discard_and_end_turn, card_index, discard_index})
  end

  def extend_timeout(pid) do
    GenServer.cast(pid, :extend_timeout)
  end

  # 
  # GenServer Callbacks
  #

  def init(opts) do
    game = Game.init(opts)
    PidLookup.put(game.id, self())
    IO.puts("Created game " <> game.id)
    Process.send_after(self(), :activity_timeout, 300_000_000) # 5 minutes
    {:ok, game}
  end

  def terminate(_reason, game) do
    IO.puts("Terminating " <> game.id)
    PidLookup.delete(game.id)
    # TODO: Broadcast that the game died
  end

  def handle_info(:activity_timeout, game) do
    IO.puts("Timing out " <> game.id)
    {:stop, :normal, game}
  end

  def handle_call(:get, _from, game) do
    {:reply, game, game}
  end

  def handle_call(:get_id, _from, game) do
    {:reply, game.id, game}
  end

  def handle_call(:start_game, _from, game) do
    game = game 
      |> Game.deal_initial()
      |> Map.put(:started, true)

    {:reply, game, game}
  end

  def handle_call({:discard_and_end_turn, card_index, discard_index}, _from, game) do
    game = Game.discard_and_end_turn(game, card_index, discard_index)
    {:reply, game, game}
  end

  def handle_call({:build_from_hand, card_index, build_index}, _from, game) do
    game = Game.build_from_hand(game, card_index, build_index)
    {:reply, game, game}
  end

  def handle_call({:build_from_stock, build_index}, _from, game) do
    game = Game.build_from_stock(game, build_index)
    {:reply, game, game}
  end

  def handle_call({:build_from_discard, discard_index, build_index}, _from, game) do
    game = Game.build_from_discard(game, discard_index, build_index)
    {:reply, game, game}
  end

  def handle_call({:discard, card_index, discard_index}, _from, game) do
    game = Game.discard(game, card_index, discard_index)
    {:reply, game, game}
  end

  def handle_call({:add_player, player}, _from, game) do
    game = Game.add_player(game, player)
    {:reply, game, game}
  end

  def handle_call({:remove_player, player}, _from, game) do
    game = Game.remove_player(game, player)
    {:reply, game, game}
  end

  def handle_cast(:extend_timeout, game) do
    if game.timeout_timer do
      Process.cancel_timer(game.timeout_timer)
    end

    game = game |> Map.put(:timeout_timer, Process.send_after(self(), :activity_timeout, 300_000_000))
    {:noreply, game}
  end
  def handle_cast(_, game), do: {:noreply, game}
end