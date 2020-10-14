defmodule Battleline.Game.Hand do
  def deactivate_cards(hands_map, player) do
    hands_map
    |> Map.get(player)
    |> Enum.map(fn c -> Map.put(c, :active?, false) end)
    |> (&Map.put(hands_map, player, &1)).()
  end

  def activate_card(card, hand) do
    hand |> Enum.map(&same?(&1, card))
  end

  defp same?(card_in_hand, card_in_hand) do
    Map.put(card_in_hand, :active?, true)
  end

  defp same?(card_in_hand, _) do
    Map.put(card_in_hand, :active?, false)
  end

end
