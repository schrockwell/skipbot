defmodule Skipbot.Pile do
  def draw([], _), do: :error
  def draw(pile, count), do: Enum.split(pile, count)

  def shuffle(pile), do: Enum.shuffle(pile)

  def place(pile, cards), do: List.flatten([cards], pile)
  def place_on_bottom(pile, cards), do: pile ++ List.flatten([cards])

  def peek(pile), do: hd(pile)
end