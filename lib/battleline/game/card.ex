defmodule Battleline.Game.Card do
  defstruct [:color, :value, :active?]

  @colors ~w[red blue green orange purple black]

  def new(color, value) do
    %__MODULE__{color: color, value: value, active?: false}
  end

  def new_deck do
    for color <- @colors do
      for value <- (1..10) do
        new(color, value)
      end
    end
    |> List.flatten
    |> Enum.shuffle
  end


end
