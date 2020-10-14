defmodule Battleline.Game do
  alias Battleline.Game.{Card, Hand, Battlefield}

  defstruct ~w[yo deck hands battle turn]a

  def new(player) do
    %__MODULE__{
      deck: new_deck(),
      hands: %{player => []},
      battle: Battlefield.new(player),
      turn: nil
    }
  end

  def get_players(game) do
    Map.keys(game.hands)
  end

  def opponent(game, player) do
    game |> get_players |> Enum.find(&(&1 != player))
  end

  def new_deck do
    for c <- Card.colors, v <- (1..2) do
      Card.new(c, v)
    end
    |> Enum.shuffle
  end

  def draw_card(game, player) do
    {deck, hand} = draw(game.deck, game.hands[player])

    game
      |> update_deck(deck)
      |> update_hand(player, hand) # DONT LIKE IT
  end

  defp draw(deck, hand) when length(hand) >= 7, do: {deck, hand}
  defp draw([card | rest], hand), do: {rest, [card| hand]}

  def next_turn(game, player) do
    next = opponent(game, player)

    game
      |> update_player_turn(next)
      |> deactivate_cards(player)
  end

  def select_card(game, player, %{color: c, value: v}) do
    hand = game.hands[player]
      |> activate_card(c, v)

    update_hand(game, player, hand)
  end

  defp activate_card(hand, color, value) do
    Card.new(color, String.to_integer(value))
      |> Hand.activate_card(hand)
  end

  defp deactivate_cards(game, player) do
    game.hands
      |> Hand.deactivate_cards(player)
      |> (&Map.put(game, :hands, &1)).()
  end

  def deploy(game, player, line) do
    card = Enum.find(game.hands[player], &(&1.active?))

    game
      |> remove_card_from_hand(player, card)
      |> add_card_to_troops(player, card, line)
  end

  defp remove_card_from_hand(game, _player, nil), do: game
  defp remove_card_from_hand(game, player, card) do
    hand = game.hands[player]
      |> List.delete(card)

    update_hand(game, player, hand)
  end

  defp add_card_to_troops(game, _player, nil, _line), do: game
  defp add_card_to_troops(game, player, card, line) do
    troops = game.battle[player]
      |> update_in([line], &([card|&1]))

    update_battle(game, player, troops)
  end

  # UPDATE GAME

  def update_player_turn(game, player) do
    Map.put(game, :turn, player)
  end

  def update_hand(game, player, hand) do
    Map.put(game, :hands, %{game.hands | player => hand})
  end

  def update_deck(game, deck) do
    Map.put(game, :deck, deck)
  end

  def update_battle(game, player, troops) do
    Map.put(game, :battle, %{game.battle | player => troops})
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
