defmodule BattlelineWeb.GameLive do
  use BattlelineWeb, :live_view

  alias Battleline.{Accounts, Game}

  def mount(_o_o, %{"user_token" => token}, socket) do
    player = get_email(token)
    game = Game.new(player)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Battleline.PubSub, "war")
      broadcast(game, player, :setup)
    end

    {:ok, assign(socket, yo: player, game: game)}
  end

  defp sync(registered_players_1, registered_players_2, game_1, game_2)
  defp sync([a], [b], game1, game2) when a != b do
    game1
    |> Game.sync_games(game2)
    |> broadcast(a, :setup)
  end
  defp sync([a], [a, _], _game1, game2), do: game2
  defp sync([a], [_, a], _game1, game2), do: game2
  defp sync([a, b], [a], game1, _), do: broadcast(game1, b, :setup)
  defp sync([a, b], [b], game1, _), do: broadcast(game1, a, :setup)
  defp sync(_, _, game1, _), do: game1

  defp broadcast(game, player, event) do
    Phoenix.PubSub.broadcast(
      Battleline.PubSub,
      "war",
      {event, %{caller: player, game: game}})
    game
  end

  defp get_email(token) do
    token
    |> Accounts.get_user_by_session_token()
    |> Map.get(:email)
  end

  defp draw(socket) do
    put_flash(socket, :info, "hola")
    socket.assigns.game
    |> Game.draw_card(socket.assigns.yo)
    |> (&assign(socket, game: &1)).()
  end

  defp pass(socket) do
    with yo <- socket.assigns.yo do
      socket.assigns.game
      |> Game.next_turn(yo)
      |> broadcast(yo, :pass)
      |> (&assign(socket, game: &1)).()
    end
  end

  defp select(socket, %{"color" => c, "value" => v}) do
    socket.assigns.game
    |> Game.select_card(socket.assigns.yo, %{color: c, value: v})
    |> (&assign(socket, game: &1)).()
  end

  defp deploy(socket, %{"line" => line}) do
    socket.assigns.game
    |> Game.deploy(socket.assigns.yo, line)
    |> (&assign(socket, game: &1)).()
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

  def handle_info({:setup, %{game: g}}, %{assigns: %{game: g}} = socket) do
    {:noreply, assign(socket, game: g)}
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
    {:noreply, assign(socket, game: game)}
  end
end
