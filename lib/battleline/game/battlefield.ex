defmodule Battleline.Game.Battlefield do
  def new(player) do
    Map.put(%{}, player, battlelines())
  end

  defp battlelines() do
    for i <- 1..9, into: %{} do
      {Integer.to_string(i) , []}
    end
  end


  def deploy(%{card: nil, troops: troops}), do: troops
  def deploy(%{card: card, troops: troops, line: line}) do
    # Map.put(troops, line, &([card | &1]))
    update_in(troops, [line], &([card|&1]))
  end
end
