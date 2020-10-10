defmodule Battleline.Game.Card do
  defstruct [:color, :value, :active?]

  @colors ~w[red blue green orange purple black]

  def new(color, value) do
    %__MODULE__{color: color, value: value, active?: false}
  end

  def new_deck do
    for c <- @colors, v <- (1..10), into: [] do
      new(c, v)
    end
    |> Enum.shuffle
  end


end
