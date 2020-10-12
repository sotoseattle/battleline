defmodule BattlelineWeb.GameLive do
  use BattlelineWeb, :live_view

  alias Battleline.{Accounts, Game}
  alias Battleline.Game.{Card, Battlefield}

  def mount(_o_o, %{"user_token" => token}, socket) do
    Phoenix.PubSub.subscribe(Battleline.PubSub, "war")

    ue = get_email(token)
    g = Game.new() |> Map.put(:players, MapSet.new([ue]))

    Phoenix.PubSub.broadcast(Battleline.PubSub, "war", {:setup, %{caller: ue, game: g}})

    {:ok, assign(socket, yo: ue, game: g)}
  end

  # VIEW HELPERS

  # defp opponent(socket) do
  #   socket.assigns.players |> Enum.find(&(&1 != socket.assigns.yo))
  # end

  defp get_email(token) do
    token
    |> Accounts.get_user_by_session_token()
    |> Map.get(:email)
  end

  defp draw(socket) do
    g = socket.assigns.game

    {deck, hand} = Card.draw(g.deck, g.hands.allies)

    g = socket.assigns.game
    |> Map.put(:deck, deck)
    |> Map.put(:hands, %{g.hands | allies: hand})
    assign(socket, game: g)
  end

  defp pass(socket) do
    opponent = socket.assigns.game.players |> Enum.find(&(&1 != socket.assigns.yo))
    g = reverse_game(socket.assigns.game, opponent)

    Phoenix.PubSub.broadcast(
      Battleline.PubSub,
      "war",
      {:pass, %{caller: socket.assigns.yo, game: g}}
    )
    # assign(socket, game: g)
    socket
  end

  defp reverse_game(game, opponent) do
    game
    |> reverse_hands
    |> reverse_theater
    |> next_turn(opponent)
  end

  defp reverse_hands(game) do
    %{allies: us, enemies: them} = game.hands
    Map.put(game, :hands, %{allies: them, enemies: us})
  end

  defp reverse_theater(game) do
    th = game.theater
    |> Enum.map(fn {flag, force} ->
      us = force.allies
      them = force.enemies
      {flag, %{force | allies: them, enemies: us}}
    end)
    %{game | theater: th}
  end

  defp next_turn(game, opponent) do
    %{game | turn: opponent}
  end





  defp select(socket, %{"card" => color_val}) do
    [color, value] = String.split(color_val, "_")

    socket.assigns.hand
      |> Card.activate_card(color, value)
      |> (&assign(socket, hand: &1)).()
  end

  defp deploy(socket, %{"line" => line}) do
    with theater <- socket.assigns.theater,
         hand    <- socket.assigns.hand,
         card    <- Enum.find(hand, &(&1.active?)),
         hand    <- Card.remove_card(card, hand),
         theater <- Battlefield.deploy(%{card: card, theater: theater, line: line})
     do

      Phoenix.PubSub.broadcast(Battleline.PubSub, "war", {:deploy, %{yo: socket.assigns.yo, theater: theater}})
      assign(socket, hand: hand, theater: theater)
    end
  end

  defp sync_players(yo, msg_players, my_game) do
    new_players = MapSet.union(my_game.players, msg_players)

    if yo not in msg_players do           # MapSet.size(msg_players) == 1 and yo in new_players do
        g = my_game
        |> Map.put(:players, new_players)
        |> Map.put(:hands, my_game.hands) # <======= WRONG needs reverse (probably)
        |> Map.put(:theater, reverse_war_view(my_game.theater))
        |> Map.put(:turn, hd(MapSet.to_list(new_players)))

        Phoenix.PubSub.broadcast(Battleline.PubSub, "war", {:setup, %{game: g}})
    end
  end

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

  def handle_info({:setup, %{caller: yo}}, %{assigns: %{caller: yo}} = socket) do
    {:noreply, socket}
  end
  def handle_info({:setup, %{game: msg_game}}, socket) do
    if MapSet.size(msg_game.players) <= 2 do
      sync_players(socket.assigns.yo, msg_game.players, socket.assigns.game)
      IO.puts("""
      #{socket.assigns.yo} -> players: #{to_string(Enum.join(MapSet.to_list(msg_game.players), " - "))}
      #{msg_game.turn} == #{socket.assigns.game.turn}
      """)
      {:noreply, assign(socket, game: msg_game)}
    # else
    #   IO.puts("""
    #   [B]
    #   #{socket.assigns.yo} -> players: #{to_string(Enum.join(MapSet.to_list(socket.assigns.game.players), " - "))}
    #   #{msg_game.turn} == #{socket.assigns.game.turn}
    #   """)
    #   {:noreply, socket}
    end
  end

  def handle_info({:card, %{deck: deck}}, socket) do
    IO.puts("---------- deck update!! -----------")
    {:noreply, assign(socket, deck: deck)}
  end

  def handle_info({:pass, %{caller: caller, game: g}}, socket) do
    IO.puts(String.duplicate("*", 200))
    if caller != socket.assigns.yo do
      {:noreply, assign(socket, game: g)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:deploy, %{yo: yo, theater: theater}}, socket) do
    IO.puts("---------- battlefield update!! -----------")
    if yo == socket.assigns.yo do
      {:noreply, assign(socket, theater: theater)}
    else
      {:noreply, assign(socket, theater: reverse_war_view(theater))}
    end
  end

  defp reverse_war_view(theater) do
    theater
    |> Enum.map(fn {flag, force} ->
      us = force.allies
      them = force.enemies
      {flag, %{force | allies: them, enemies: us}}
    end)
  end
end


# if MapSet.size(new_ps) <= 2 do
# new_ps = MapSet.union(my_game.players, msg_game.players)
# {:noreply, assign(socket, game: %{msg_game | players: new_ps})}
# IO.puts("""
#   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   I am: #{socket.assigns.yo}
#   o_o_ps: #{to_string(Enum.join(MapSet.to_list(msg_game.players), " - "))}
#   old_ps: #{to_string(Enum.join(MapSet.to_list(my_game.players), " - "))} <======
#   new_ps: #{to_string(Enum.join(MapSet.to_list(new_ps), " - "))}
#   ________________________________________________
# """)
