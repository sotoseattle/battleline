defmodule Battleline.Game.Card do
  defstruct [:color, :value, :active?]

  def new(color, value) do
    %__MODULE__{color: color, value: value, active?: false}
  end

  def colors do
    ~w[red blue green orange purple black]
  end

end
