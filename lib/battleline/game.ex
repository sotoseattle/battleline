defmodule Battleline.Game do
  alias Battleline.Game.{Card, Hand, Battlefield}

  defstruct ~w[yo deck hands battle turn]a

  def new(player) do
    %__MODULE__{
      deck: Card.new_deck(),
      hands: %{player => []},
      battle: Battlefield.new(player),
      turn: nil
    }
  end

  def get_players(game) do
    Map.keys(game.hands)
  end

  def set_player_turn(game, player) do
    Map.put(game, :turn, player)
  end

  def opponent(game, player) do
    game
    |> get_players
    |> Enum.find(&(&1 != player))
  end

  def deactivate_cards(game, player) do
    game
    |> Map.get(:hands)
    |> Hand.deactivate_cards(player)
    |> (&Map.put(game, :hands, &1)).()
  end

  def update_hands(game, player, new_hand) do
    Map.put(game, :hands, %{game.hands | player => new_hand})
  end

  def update_deck(game, deck) do
    Map.put(game, :deck, deck)
  end

  def draw(deck, hand) when length(hand) >= 7 do
    {deck, hand}
  end

  def draw([card | rest], hand) do
    {rest, [card| hand]}
  end

  def remove_card(nil, hand), do: hand
  def remove_card(card, hand), do: List.delete(hand, card)


  # def cleanup(game) do
  #   game
  #   |> assign_flags()
  #   # check if someone has winning condition
  # end

  # defp assign_flags(game) do
  #   game
  #     |> Map.put(
  #       :battlefield,
  #       game.battlefield
  #         |> Enum.map(fn {k, v} -> {k, score(v)} end)
  #         |> Map.new)
  # end

  # def score(%{winner: :na, player_1: p1, player_2: p2} = battleline)
  #   when length(p1)==3 and length(p2)==3 do
  #     battleline |> Map.put(:winner, pick_winner(evaluate(p1), evaluate(p2)))
  # end
  # def score(battleline), do: battleline

  # defp pick_winner(%{score: score_a}, %{score: score_b}) when score_a > score_b, do: :player_1
  # defp pick_winner(%{score: score_a}, %{score: score_b}) when score_a < score_b, do: :player_2
  # defp pick_winner(%{sum: sum_a}, %{sum: sum_b}), do: resolve_tie(sum_a, sum_b)

  # defp resolve_tie(a, b) when a > b, do: :player_1
  # defp resolve_tie(a, b) when a < b, do: :player_2
  # defp resolve_tie(a, b) when a == b, do: :tie

  # def evaluate(formation) do
  #   formation = Enum.sort_by(formation, &(&1.value), :desc)
  #   sum = Enum.map(formation, &(&1.value)) |> Enum.sum

  #   score = cond do
  #     same_color?(formation) and consecutiv?(formation) -> 4 # :wedge
  #     same_value?(formation) -> 3 # :phallanx
  #     same_color?(formation) -> 2 # :battalion
  #     consecutiv?(formation) -> 1 # :skirmish
  #     true -> 0 # :host
  #   end

  #   %{score: score, sum: sum}
  # end

  # defp same_color?([a, b, c]), do: a.color == b.color and b.color == c.color
  # defp consecutiv?([a, b, c]), do: a.value == (b.value + 1) and b.value == (c.value + 1)
  # defp same_value?([a, b, c]), do: a.value == b.value and b.value == c.value

end
