defmodule BattlelineWeb.GameLive do
  use BattlelineWeb, :live_view

  alias Battleline.Game

  def mount(_params, _session, socket) do
    {:ok, assign(socket, game: Game.new())}
  end

  # VIEW HELPERS

  defp draw(socket, player) do
    assign(socket, game: Game.draw(socket.assigns.game, player))
  end

  # defp deploy(socket, params) do
  #   g = socket.assigns.game
  #   game = g |> Game.deploy(%{
  #     player: String.to_atom(params["player"]),
  #     card: identify_card(g, params),
  #     line: "4"})

  #   assign(socket, game: game)
  # end

  defp select(socket, params) do
    IO.puts('Player 1 selected #{params["card"]}')

    [color, value] = Map.get(params, "card") |> String.split("_")

    game = Game.activate_card(
      socket.assigns.game,
      :player_1,
      color,
      value
    )

    assign(socket, game: game)
  end

  # defp identify_card(game, params) do
  #   [color, value] = Map.get(params, "card") |> String.split("_")

  #   game
  #   |> Map.get(:player_1)
  #   |> Enum.find(&({&1.color, &1.value} == {color, String.to_integer(value)}))
  # end

  # HANDLERS

  def handle_event("draw", _params, socket) do
    {:noreply, draw(socket, :player_1)}
  end

  def handle_event("select", params, socket) do
    IO.inspect(params)
    {:noreply, select(socket, params)}
  end

  # def handle_event("deploy", params, socket) do
  #   {:noreply, deploy(socket, params)}
  # end
end
