defmodule Battleline.Game.Hand do
  def deactivate_cards(hands_map, player) do
    hands_map
    |> Map.get(player)
    |> Enum.map(fn c -> Map.put(c, :active?, false) end)
    |> (&Map.put(hands_map, player, &1)).()
  end
end
