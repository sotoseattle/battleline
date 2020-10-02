defmodule BattlelineWeb.GameLive do
  use BattlelineWeb, :live_view

  alias Battleline.Game

  def mount(_o_o, _session, socket) do
    {:ok, assign(socket, game: Game.new())}
  end

  # VIEW HELPERS

  defp draw(socket, player) do
    assign(socket, game: Game.draw(socket.assigns.game, player))
  end

  defp select(socket, %{"card" => color_val}) do
    [color, value] = String.split(color_val, "_")

    socket.assigns.game
      |> Game.activate_card(:player_1, color, value)
      |> (&assign(socket, game: &1)).()
  end

  defp deploy(socket, %{"player" => player, "line" => line}) do
    player = String.to_atom(player)

    socket.assigns.game
      |> Game.deploy(%{
        player: player,
        card: get_active_card(socket, player),
        line: line})
      |> (&assign(socket, game: &1)).()
  end

  defp get_active_card(socket, player) do
    socket.assigns.game
    |> Map.get(player)
    |> Enum.find(&(&1.active?))
  end

  # HANDLERS

  def handle_event("draw", _o_o, socket) do
    {:noreply, draw(socket, :player_1)}
  end

  def handle_event("select", o_o, socket) do
    IO.inspect(o_o)
    {:noreply, select(socket, o_o)}
  end

  def handle_event("deploy", o_o, socket) do
    {:noreply, deploy(socket, o_o)}
  end
end
