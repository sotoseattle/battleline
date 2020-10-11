defmodule Battleline.Game do
  alias Battleline.Game.Card
  alias Battleline.Game.Battlefield

  defstruct ~w[deck player_1 player_2 battlefield log players]a

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
    if length(Map.get(game, player)) >= 7 do
      game
    else
      game
      |> Map.put(:deck, rest)
      |> add_to_hand(player, card)
      |> Map.put(:log, "#{player} drew a card")
    end
  end

  defp add_to_hand(game, player, card) do
    game |> Map.update!(player, &([card|&1]))
  end

  defp remove_from_hand(game, player, card) do
    game |> Map.update!(player, &List.delete(&1, card))
  end

  def activate_card(game, player, color, value) do
    game
    |> Map.update!(player, &Enum.map(&1,
        fn x ->
          same?(x, color,  String.to_integer(value))
        end))
    |> Map.put(:log, "#{player} selected #{color}:#{value}")
  end

  defp same?(%{color: col, value: val, active?: false} = card, col, val) do
    Map.put(card, :active?, true)
  end
  defp same?(card, _, _), do: Map.put(card, :active?, false)

  def deploy(game, %{card: nil}), do: game
  def deploy(game, %{player: player, card: card, line: line}) do
    game
    |> remove_from_hand(player, card)
    |> update_in(
      [:battlefield, line, player] |> Enum.map(&Access.key/1),
      &([card|&1]))
  end


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
