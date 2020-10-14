defmodule Battleline.Game.Battlefield do
  def new(player) do
    Map.put(%{}, player, battlelines())
  end

  defp battlelines() do
    for i <- 1..9, into: %{} do
      {Integer.to_string(i) , []}
    end
  end
end
