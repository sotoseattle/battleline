defmodule Battleline.Game do
  alias Battleline.Game.Card
  alias Battleline.Game.Battlefield

  defstruct ~w[deck player_1 player_2 battlefield log]a

  def new do
    %__MODULE__{
      deck: Card.new_deck(),
      player_1: [],
      player_2: [],
      battlefield: Battlefield.new(),
      log: ["...game initialized"]
    }
  end

  def draw(%{deck: [card | rest]} = game, player) do
    game
    |> Map.put(:deck, rest)
    |> add_to_hand(player, card)
    |> Map.put(:log, "#{player} drew a card")
  end

  defp add_to_hand(game, player, card) do
    game |> Map.update!(player, &([card|&1]))
  end

  defp remove_from_hand(game, player, card) do
    game |> Map.update!(player, &List.delete(&1, card))
  end

  def deploy(game, %{player: player, card: card, line: line}) do
    game
    |> remove_from_hand(player, card)
    |> update_in(
      [:battlefield, line, player] |> Enum.map(&Access.key/1),
      &([card|&1]))
  end

  # def cleanup(game, %{player: player, line: line}) do
  #   # check all formations to assign flags
  #   # check if someone has winning condition
  # end

  def xxx do
    g = new()
    |> draw(:player_2)
    |> draw(:player_2)
    |> draw(:player_2)
    |> draw(:player_2)
    |> draw(:player_2)

    g = g
    |> deploy(%{
      player: :player_2,
      card: hd(g.player_2),
      line: "3"})
    g = g
    |> deploy(%{
      player: :player_2,
      card: hd(g.player_2),
      line: "3"})

    g
      |> deploy(%{
      player: :player_2,
      card: hd(g.player_2),
      line: "3"})


  end

end
