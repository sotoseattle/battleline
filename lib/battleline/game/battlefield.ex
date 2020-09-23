defmodule Battleline.Game.Battlefield do
  def new do
    %{
      "1" => new_forces(),
      "2" => new_forces(),
      "3" => new_forces(),
      "4" => new_forces(),
      "5" => new_forces(),
      "6" => new_forces(),
      "7" => new_forces(),
      "8" => new_forces(),
      "9" => new_forces()
    }
  end

  defp new_forces do
    %{player_1: [], player_2: [], winner: nil}
  end
end
