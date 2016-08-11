defmodule Skipbot.Game do
  alias Skipbot.Game
  alias Skipbot.Seat
  alias Skipbot.Pile

  @derive {Poison.Encoder, only: [:id, :seats, :deck, :builds, :trash, :current, :winner, :started]}
  defstruct id: nil, seats: [], deck: [], builds: [[], [], [], []], 
    trash: [], current: 0, stock_size: 30, hand_size: 5, winner: nil,
    started: false, timeout_timer: nil

  def init(opts \\ []) do
    %Game{
      id: opts[:id] || UUID.uuid4(),
      deck: new_deck(),
      stock_size: opts[:stock] || 30,
      hand_size: opts[:hand] || 5
    }
  end

  def deal_initial(game), do: deal_initial(game, game.deck, game.seats, [])
  def deal_initial(game, deck, [], acc), do: %{game | seats: acc, deck: deck}
  def deal_initial(game, deck, [seat | seats], acc) do
    { hand, deck } = Pile.draw(deck, game.hand_size)
    { stock, deck } = Pile.draw(deck, game.stock_size)

    seat = %{ seat | hand: hand, stock: stock }
    acc = acc ++ [seat]

    deal_initial(game, deck, seats, acc)
  end

  def new_deck do
    List.duplicate([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], 12) 
      ++ List.duplicate(0, 18) 
      |> List.flatten()
      |> Pile.shuffle()
  end

  def discard_and_end_turn(game, card_index, discard_index) do
    game
      |> discard(card_index, discard_index)
      |> advance_player()
      |> fill_current_hand()
  end

  def build_value(build), do: Enum.count(build)

  def can_build?(_, 0), do: true
  def can_build?(build, card), do: card == build_value(build) + 1

  def clear_builds(game), do: clear_builds(game, game.builds, game.trash, [])
  def clear_builds(game, [], trash, acc), do: %{game | trash: trash, builds: acc}
  def clear_builds(game, [build | builds], trash, acc) do
    case build_value(build) do
      12 -> clear_builds(game, builds, trash ++ build, acc ++ [[]])
      _ -> clear_builds(game, builds, trash, acc ++ [build])
    end
  end

  def fill_current_hand(game) do
    seat = current_seat(game)
    remaining = game.hand_size - length(seat.hand)

    { deck, hand, trash } = draw(game.deck, seat.hand, game.trash, remaining)

    game
      |> update_hand(hand)
      |> update_deck(deck)
      |> update_trash(trash)
  end

  def build_from_hand(game, card_index, build_index) do
    build = Enum.at(game.builds, build_index)
    hand = current_seat(game).hand
    card = Enum.at(hand, card_index)

    {hand, build} = case can_build?(build, card) do
      true -> move(hand, card_index, build)
      false -> {hand, build}
    end

    game = game
      |> update_hand(hand)
      |> update_build(build, build_index)
      |> clear_builds()

    if Enum.empty?(hand), do: fill_current_hand(game), else: game
  end

  def build_from_stock(game, build_index) do
    build = Enum.at(game.builds, build_index)
    stock = current_seat(game).stock
    card = hd(stock)

    {stock, build} = case can_build?(build, card) do
      true -> {tl(stock), [card] ++ build}
      false -> {stock, build}
    end

    game
      |> update_stock(stock)
      |> update_build(build, build_index)
      |> update_winner()
      |> clear_builds()
  end

  def build_from_discard(game, discard_index, build_index) do
    build = Enum.at(game.builds, build_index)
    seat = current_seat(game)
    discard = Enum.at(seat.discards, discard_index)
    card = hd(discard)

    {discard, build} = case can_build?(build, card) do
      true -> {tl(discard), [card] ++ build}
      false -> {discard, build}
    end

    game
      |> update_discard(discard, discard_index)
      |> update_build(build, build_index)
      |> clear_builds()
  end

  def discard(game, card_index, discard_index) do
    seat = current_seat(game)
    discard = Enum.at(seat.discards, discard_index)

    {hand, discard} = move(seat.hand, card_index, discard)

    game
      |> update_hand(hand)
      |> update_discard(discard, discard_index)
  end

  def update_winner(game) do
    winner = Enum.find_index(game.seats, &Seat.won?(&1))
    %{ game | winner: winner }
  end

  def draw(deck, hand, trash, 0), do: { deck, hand, trash }
  def draw([], hand, [], _), do: { [], hand, [] }
  def draw([], hand, trash, remaining), do: draw(Pile.shuffle(trash), hand, [], remaining)
  def draw([card | deck], hand, trash, remaining), do: draw(deck, hand ++ [card], trash, remaining - 1)

  def move(from, card_index, to) do
    card = Enum.at(from, card_index)
    from = List.delete_at(from, card_index)
    to = [card] ++ to
    { from, to }
  end

  def advance_player(game) do
    next = rem(game.current + 1, length(game.seats))
    %{game | current: next }
  end

  def update_seat(game, seat, index) do
    seats = List.replace_at(game.seats, index, seat)
    %{game | seats: seats}
  end

  def update_hand(game, hand) do
    seat = %{current_seat(game) | hand: hand}
    game |> update_seat(seat, game.current)
  end

  def update_stock(game, stock) do
    seat = %{current_seat(game) | stock: stock}
    game |> update_seat(seat, game.current)
  end

  def update_discard(game, discard, index) do
    seat = current_seat(game)
    discards = List.replace_at(seat.discards, index, discard)
    seat = %{seat | discards: discards}

    game |> update_seat(seat, game.current)
  end

  def update_build(game, build, index) do
    builds = List.replace_at(game.builds, index, build)
    %{game | builds: builds}
  end

  def update_deck(game, deck) do
    %{game | deck: deck}
  end

  def update_trash(game, trash) do
    %{game | trash: trash}
  end

  def add_player(game = %Game{started: true}, _player), do: game
  def add_player(game, player) do
    case find_seat_index(game, player) do
      nil -> %{game | seats: game.seats ++ [Seat.init(player)]}
      _ -> game
    end
  end

  def remove_player(game = %Game{started: true}, _player), do: game
  def remove_player(game, player) do
    case find_seat_index(game, player) do
      nil -> game
      seat_index -> %{game | seats: List.delete_at(game.seats, seat_index)}
    end
  end

  def find_seat_index(game, player) do
    game.seats |> Enum.find_index(fn(seat) -> !is_nil(seat) && seat.player == player end)
  end

  def current_seat(game), do: Enum.at(game.seats, game.current)
end