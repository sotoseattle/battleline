defmodule Battleline.Game.Card do
  defstruct [:color, :value]

  @colors [:red, :blue, :green, :gold, :purple, :black]

  def new(color, value) do
    %__MODULE__{color: color, value: value}
  end

  def new_deck do
    for color <- @colors do
      for n <- (1..10) do
        new(color, n)
      end
    end
    |> List.flatten
    |> Enum.shuffle
  end


end
