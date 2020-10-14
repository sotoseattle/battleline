defmodule BattlelineWeb.GameLive do
  use BattlelineWeb, :live_view

  alias Battleline.{Accounts, Game}
  alias Battleline.Game.{Battlefield}

  def mount(_o_o, %{"user_token" => token}, socket) do
    Phoenix.PubSub.subscribe(Battleline.PubSub, "war")

    with player <- get_email(token),
         game   <- Game.new(player)
    do
      broadcast({:setup, %{caller: player, game: game}})
      {:ok, assign(socket, yo: player, game: game)}
    end
  end

  # VIEW HELPERS

  defp broadcast(msg) do
    Phoenix.PubSub.broadcast(Battleline.PubSub, "war", msg)
  end

  defp get_email(token) do
    token
    |> Accounts.get_user_by_session_token()
    |> Map.get(:email)
  end

  # Seems redundant or at least belongs to Game
  defp sync_game(opponent_game, my_game) do
    new_hands = Map.merge(my_game.hands, opponent_game.hands)
    new_battle = Map.merge(my_game.battle, opponent_game.battle)

    my_game
    |> Map.put(:hands, new_hands)
    |> Map.put(:battle, new_battle)
    |> Map.put(:turn, hd(Map.keys(new_hands)))
  end

  defp draw(socket) do
    game = Game.draw_card(socket.assigns.game, socket.assigns.yo)
    assign(socket, game: game)
  end

  defp pass(socket) do
    game = Game.next_turn(socket.assigns.game, socket.assigns.yo)
    broadcast({:pass, %{caller: socket.assigns.yo, game: game}})
    assign(socket, game: game)
  end

  defp select(socket, %{"color" => c, "value" => v}) do
    game = Game.select_card(
      socket.assigns.game,
      socket.assigns.yo,
      %{color: c, value: v})

    assign(socket, game: game)
  end

  defp deploy(socket, %{"line" => line}) do
    game = Game.deploy(socket.assigns.game, socket.assigns.yo, line)
    assign(socket, game: game)
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
        broadcast({:setup, %{caller: socket.assigns.yo, game: my_game}})
      end
      {:noreply, assign(socket, game: my_game)}
    else
      if n_players(other_game) == 1 do
        broadcast({:setup, %{caller: socket.assigns.yo, game: my_game}})
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
