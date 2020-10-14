defmodule BattlelineWeb.GameLive do
  use BattlelineWeb, :live_view

  alias Battleline.{Accounts, Game}

  def mount(_o_o, %{"user_token" => token}, socket) do
    Phoenix.PubSub.subscribe(Battleline.PubSub, "war")

    with player <- get_email(token),
         game   <- Game.new(player)
    do
      broadcast({:setup, %{caller: player, game: game}})
      {:ok, assign(socket, yo: player, game: game)}
    end
  end

  defp sync(registered_players_1, registered_players_2, game_1, game_2)
  defp sync([a], [b], game1, game2) when a != b do
    game = Game.sync_games(game1, game2)
    broadcast({:setup, %{caller: a, game: game}})
    game
  end
  defp sync([a], [a, _], _game1, game2), do: game2
  defp sync([a], [_, a], _game1, game2), do: game2
  defp sync([a, b], [a], game1, _) do
    broadcast({:setup, %{caller: b, game: game1}})
    game1
  end
  defp sync([a, b], [b], game1, _) do
    broadcast({:setup, %{caller: a, game: game1}})
    game1
  end
  defp sync(_, _, game1, _), do: game1

  defp broadcast(msg) do
    Phoenix.PubSub.broadcast(Battleline.PubSub, "war", msg)
  end

  defp get_email(token) do
    token
    |> Accounts.get_user_by_session_token()
    |> Map.get(:email)
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

  def handle_info({:setup, %{game: other_game}}, %{assigns: %{game: game}} = socket) do
    game = sync(
      Map.keys(game.hands),
      Map.keys(other_game.hands),
      game,
      other_game)
    {:noreply, assign(socket, game: game)}
  end

  def handle_info({:pass, %{caller: yo}},  %{assigns: %{yo: yo}} = socket) do
    {:noreply, socket}
  end
  def handle_info({:pass, %{game: game}},  socket) do
    IO.puts(String.duplicate("*", 200))
    {:noreply, assign(socket, game: game)}
  end
end
