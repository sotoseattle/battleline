defmodule BattlelineWeb.GameLive do
  use BattlelineWeb, :live_view

  alias Phoenix.PubSub
  alias Battleline.{Accounts, Game}
  alias Battleline.Game.{Card, Battlefield}

  def mount(_o_o, %{"user_token" => token}, socket) do
    PubSub.subscribe(Battleline.PubSub, "war")

    player = get_email(token)
    game = Game.new(player)

    PubSub.broadcast(
      Battleline.PubSub,
      "war",
      {:setup, %{caller: player, game: game}}
    )

    {:ok, assign(socket, yo: player, game: game)}
  end

  # VIEW HELPERS

  defp get_email(token) do
    token
    |> Accounts.get_user_by_session_token()
    |> Map.get(:email)
  end

  defp sync_game(opponent_game, my_game) do
    new_hands = Map.merge(my_game.hands, opponent_game.hands)
    new_battle = Map.merge(my_game.battle, opponent_game.battle)

    my_game
    |> Map.put(:hands, new_hands)
    |> Map.put(:battle, new_battle)
    |> Map.put(:turn, hd(Map.keys(new_hands)))
  end

  defp draw(socket) do
    with yo <- socket.assigns.yo,
         g  <- socket.assigns.game,
         {deck, hand} <- Game.draw(g.deck, g.hands[yo])
    do
      g = socket.assigns.game
      |> Game.update_deck(deck)
      |> Game.update_hands(yo, hand)
      assign(socket, game: g)
    end
  end

  defp pass(socket) do
    with yo   <- socket.assigns.yo,
         next <- Game.opponent(socket.assigns.game, yo),
         game <- socket.assigns.game
    do
      game = game
      |> Game.set_player_turn(next)
      |> Game.deactivate_cards(yo)

      PubSub.broadcast(
        Battleline.PubSub,
        "war",
        {:pass, %{caller: yo, game: game}}
      )
      assign(socket, game: game)
    end
  end

  defp select(socket, %{"card" => color_val}) do
    with game     <- socket.assigns.game,
         yo       <- socket.assigns.yo,
         hand     <- Map.get(game.hands, yo),
         [c, v]   <- String.split(color_val, "_"),
         new_hand <- Card.activate_card_in_hand(hand, c, v)
    do
      assign(socket, game: Game.update_hands(game, yo, new_hand))
    end
  end

  defp deploy(socket, %{"line" => line}) do
    with yo     <- socket.assigns.yo,
         game   <- socket.assigns.game,
         hand   <- game.hands[yo],
         card   <- Enum.find(hand, &(&1.active?)),
         hand   <- Game.remove_card(card, hand),
         troops <- game.battle[yo],
         troops <- Battlefield.deploy(%{card: card, troops: troops, line: line}),
         battle <- Map.put(game.battle, yo, troops)
    do
      game = game
        |> Game.update_hands(yo, hand)
        |> Map.put(:battle, battle)
        assign(socket, game: game)
    end
  end

  defp n_players(game), do: length(Map.keys(game.hands))

  # HANDLERS

  def handle_event("draw", _o_o, socket) do
    {:noreply, draw(socket)}
  end

  def handle_event("pass", _o_o, socket) do
    {:noreply, pass(socket)}
  end

  def handle_event("select", o_o, socket) do
    {:noreply, select(socket, o_o)}
  end

  def handle_event("deploy", o_o, socket) do
    {:noreply, deploy(socket, o_o)}
  end

  def handle_info({:setup, %{caller: yo}}, %{assigns: %{yo: yo}} = socket) do
    {:noreply, socket}
  end
  def handle_info({:setup, %{game: other_game}}, socket) do
    my_game = socket.assigns.game

    if n_players(my_game) == 1 do
      my_game = sync_game(other_game, my_game)
      if n_players(other_game) == 1 do
        PubSub.broadcast(Battleline.PubSub, "war", {:setup, %{caller: socket.assigns.yo, game: my_game}})
      end
      {:noreply, assign(socket, game: my_game)}
    else
      if n_players(other_game) == 1 do
        PubSub.broadcast(Battleline.PubSub, "war", {:setup, %{caller: socket.assigns.yo, game: my_game}})
        {:noreply, assign(socket, game: my_game)}
      else
        {:noreply, socket}
      end
    end
  end

  def handle_info({:pass, %{caller: yo}},  %{assigns: %{yo: yo}} = socket) do
    {:noreply, socket}
  end
  def handle_info({:pass, %{game: game}},  socket) do
    IO.puts(String.duplicate("*", 200))
    {:noreply, assign(socket, game: game)}
  end
end
