defmodule Battleline.Game.Card do
  defstruct [:color, :value, :active?]

  @colors ~w[red blue green orange purple black]

  def new(color, value) do
    %__MODULE__{color: color, value: value, active?: false}
  end

  def new_deck do
    for c <- @colors, v <- (1..2), into: [] do
      new(c, v)
    end
    |> Enum.shuffle
  end

  def activate_card_in_hand(hand, color, value) do
    hand
    |> Enum.map(
        fn card ->
          same?(card, color,  String.to_integer(value))
        end)
  end

  defp same?(%{color: c, value: v, active?: false} = card, c, v) do
    Map.put(card, :active?, true)
  end
  defp same?(card, _, _), do: Map.put(card, :active?, false)

end
