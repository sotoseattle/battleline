defmodule BattlelineWeb.GameLive do
  use BattlelineWeb, :live_view

  alias Battleline.Accounts
  alias Battleline.Game

  def mount(_o_o, %{"user_token" => token}, socket) do
    Phoenix.PubSub.subscribe(Battleline.PubSub, "setup")

    ue = token
    |> Accounts.get_user_by_session_token()
    |> Map.get(:email)
    gm = Game.new()

    ps = MapSet.new([ue])
    Phoenix.PubSub.broadcast(Battleline.PubSub, "setup", {:setup, %{players: ps}})


    {:ok, assign(socket, game: gm, players: MapSet.new(), yo: ue)}
  end


  # VIEW HELPERS

  defp draw(socket, player) do
    g = Game.draw(socket.assigns.game, player)
    # Phoenix.PubSub.broadcast(Battleline.PubSub, "fighting", {:g, g})
    assign(socket, game: g)
  end

  defp select(socket, %{"card" => color_val}) do
    [color, value] = String.split(color_val, "_")

    socket.assigns.game
      |> Game.activate_card(:player_1, color, value)
      |> (&assign(socket, game: &1)).()
  end

  defp deploy(socket, %{"player" => player, "line" => line}) do
    player = String.to_atom(player)
    g = socket.assigns.game
        |> Game.deploy(%{
          player: player,
          card: get_active_card(socket, player),
          line: line})

    # Phoenix.PubSub.broadcast(Battleline.PubSub, "fighting", {:g, g})
    assign(socket, game: g)
  end

  defp get_active_card(socket, player) do
    socket.assigns.game
    |> Map.get(player)
    |> Enum.find(&(&1.active?))
  end

  defp sync_players(yo, msg_players, my_players) do
    if MapSet.size(msg_players) == 1 and
       yo not in msg_players and
       yo in my_players do
      Phoenix.PubSub.broadcast(Battleline.PubSub, "setup", {:setup, %{players: my_players}})
    end
  end

  # HANDLERS

  def handle_event("draw", _o_o, socket) do
    {:noreply, draw(socket, :player_1)}
  end

  def handle_event("select", o_o, socket) do
    {:noreply, select(socket, o_o)}
  end

  def handle_event("deploy", o_o, socket) do
    {:noreply, deploy(socket, o_o)}
  end

  def handle_info({:setup, %{players: ps}}, socket) do
    new_ps = MapSet.union(socket.assigns.players, ps)

    sync_players(socket.assigns.yo, ps, new_ps)

    if MapSet.size(new_ps) <= 2 do
      IO.puts("""
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        I am: #{socket.assigns.yo}
        o_o_ps: #{to_string(Enum.join(MapSet.to_list(ps), " - "))}
        old_ps: #{to_string(Enum.join(MapSet.to_list(socket.assigns.players), " - "))}
        new_ps: #{to_string(Enum.join(MapSet.to_list(new_ps), " - "))} <=======
        ________________________________________________
      """)
      {:noreply, assign(socket, players: new_ps)}
    else
      IO.puts("""
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        I am: #{socket.assigns.yo}
        o_o_ps: #{to_string(Enum.join(MapSet.to_list(ps), " - "))}
        old_ps: #{to_string(Enum.join(MapSet.to_list(socket.assigns.players), " - "))} <======
        new_ps: #{to_string(Enum.join(MapSet.to_list(new_ps), " - "))}
        ________________________________________________
      """)
      {:noreply, socket}
    end
  end

  # def handle_info({:g, g}, socket) do
  #   IO.puts("---------- update!! -----------")
  #   IO.inspect(g.player_1)
  #   {:noreply, assign(socket, game: g)}
  # end
end
