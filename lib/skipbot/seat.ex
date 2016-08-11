defmodule Skipbot.Seat do
  defstruct player: nil, hand: [], discards: [[], [], [], []], stock: []

  def init(player) do
    %Skipbot.Seat{
      player: player
    }
  end

  def won?(seat), do: (seat.stock == [])
end