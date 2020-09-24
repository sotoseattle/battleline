defmodule Battleline.GameTest do
  use ExUnit.Case
  alias Battleline.Game
  alias Battleline.Game.Card

  test "draw cards from deck to players hands" do
    g = Game.new()
    [c1, c2, c3, c4, c5, c6, c7, c8, c9 | _rest] = g.deck

    g = g
    |> Game.draw(:player_2) |> Game.draw(:player_1) |> Game.draw(:player_2)
    |> Game.draw(:player_1) |> Game.draw(:player_2) |> Game.draw(:player_2)
    |> Game.draw(:player_1) |> Game.draw(:player_2) |> Game.draw(:player_1)

    assert length(g.deck) == 51
    refute [c1, c2, c3, c4, c5, c6, c7, c8, c9] |> Enum.any?(&(&1 in g.deck))
    assert g.player_2 == Enum.reverse([c1, c3, c5, c6, c8])
    assert g.player_1 == Enum.reverse([c2, c4, c7, c9])
  end

  test "deploy from player's hand to battlefield lines" do
    g = Game.new()
    [c1, c2, c3, c4 | _rest] = g.deck

    g = g
      |> Game.draw(:player_2) |> Game.draw(:player_1)
      |> Game.draw(:player_1) |> Game.draw(:player_2)

    g = Game.deploy(g, %{ player: :player_2, card: hd(g.player_2), line: "1"})
    g = Game.deploy(g, %{ player: :player_1, card: hd(g.player_1), line: "3"})
    g = Game.deploy(g, %{ player: :player_2, card: hd(g.player_2), line: "1"})

    assert c1 in g.battlefield["1"].player_2
    assert c4 in g.battlefield["1"].player_2
    assert g.player_2 == []

    assert c3 in g.battlefield["3"].player_1
    assert g.player_1 == [c2]
  end

  describe "evaluation of formations" do
    test "a wedge" do
      formation = [
        %Card{color: :red, value: 4},
        %Card{color: :red, value: 5},
        %Card{color: :red, value: 3}
      ]
      assert Game.evaluate(formation) == %{score: 4, sum: 12}
    end

    test "a phallanx" do
      formation = [
        %Card{color: :gold, value: 8},
        %Card{color: :red, value: 8},
        %Card{color: :green, value: 8}
      ]
      assert Game.evaluate(formation) == %{score: 3, sum: 8*3}
    end

    test "a battalion" do
      formation = [
        %Card{color: :blue, value: 2},
        %Card{color: :blue, value: 7},
        %Card{color: :blue, value: 4}
      ]
      assert Game.evaluate(formation) == %{score: 2, sum: 13}
    end

    test "a skirmish" do
      formation = [
        %Card{color: :gold, value: 4},
        %Card{color: :red, value: 6},
        %Card{color: :green, value: 5}
      ]
      assert Game.evaluate(formation) == %{score: 1, sum: 15}
    end

    test "a host" do
      formation = [
        %Card{color: :gold, value: 7},
        %Card{color: :blue, value: 2},
        %Card{color: :green, value: 1}
      ]
      assert Game.evaluate(formation) == %{score: 0, sum: 10}
    end
  end

  describe "determine winner in a battleline" do
    test "clear winner of wedge v host" do
      wedg = [%Card{color: :red, value: 4}, %Card{color: :red, value: 5}, %Card{color: :red, value: 3}]
      host = [%Card{color: :gold, value: 7}, %Card{color: :blue, value: 2}, %Card{color: :green, value: 1}]

      bline = Game.score(%{winner: :na, player_1: wedg, player_2: host})
      assert bline.winner == :player_1
    end
    test "no winner if empty" do
      bline = Game.Battlefield.new() |> Map.get("1")
      assert Game.score(bline).winner == :na
    end
    test "no winner if one has less than 3 cards" do
      wedg = [%Card{color: :red, value: 4}, %Card{color: :red, value: 5}, %Card{color: :red, value: 3}]
      wtfk = [%Card{color: :blue, value: 2}, %Card{color: :green, value: 1}]

      bline = Game.score(%{winner: :na, player_1: wedg, player_2: wtfk})
      assert bline.winner == :na
    end

    test "tie with different sums of values" do
      big = [%Card{color: :gold, value: 1}, %Card{color: :blue, value: 3}, %Card{color: :green, value: 5}]
      sml = [%Card{color: :gold, value: 7}, %Card{color: :blue, value: 2}, %Card{color: :green, value: 1}]

      bline = Game.score(%{winner: :na, player_1: big, player_2: sml})
      assert bline.winner == :player_2
    end

    test "tie with different sums of values II" do
      big = [%Card{color: :gold, value: 1}, %Card{color: :blue, value: 3}, %Card{color: :green, value: 5}]
      sml = [%Card{color: :gold, value: 7}, %Card{color: :blue, value: 2}, %Card{color: :green, value: 1}]

      bline = Game.score(%{winner: :na, player_1: sml, player_2: big})
      assert bline.winner == :player_1
    end

    test "tie with same sums of values" do
      big = [%Card{color: :gold, value: 2}, %Card{color: :blue, value: 3}, %Card{color: :green, value: 5}]
      sml = [%Card{color: :gold, value: 7}, %Card{color: :blue, value: 2}, %Card{color: :green, value: 1}]

      bline = Game.score(%{winner: :na, player_1: big, player_2: sml})
      assert bline.winner == :tie
    end

  end

  describe "assess whole battlefield" do
    test "where 3 field flags are assigned" do
      wedg = [%Card{color: :red, value: 4}, %Card{color: :red, value: 5}, %Card{color: :red, value: 3}]
      host = [%Card{color: :gold, value: 7}, %Card{color: :blue, value: 2}, %Card{color: :green, value: 1}]
      big = [%Card{color: :gold, value: 1}, %Card{color: :blue, value: 3}, %Card{color: :green, value: 5}]
      sml = [%Card{color: :gold, value: 7}, %Card{color: :blue, value: 2}, %Card{color: :green, value: 1}]
      skir = [%Card{color: :gold, value: 4}, %Card{color: :red, value: 6}, %Card{color: :green, value: 5}]
      tie_1 = [%Card{color: :gold, value: 2}, %Card{color: :blue, value: 3}, %Card{color: :green, value: 5}]
      tie_2 = [%Card{color: :gold, value: 7}, %Card{color: :blue, value: 2}, %Card{color: :green, value: 1}]

      bt = %{
          "1" => %{winner: :na, player_1: wedg, player_2: host},
          "2" => %{winner: :na, player_1: [], player_2: wedg},
          "3" => %{winner: :na, player_1: [], player_2: []},
          "4" => %{winner: :na, player_1: [%Card{color: :gold, value: 7}], player_2: []},
          "5" => %{winner: :na, player_1: tie_1, player_2: tie_2},
          "6" => %{winner: :na, player_1: skir, player_2: []},
          "7" => %{winner: :na, player_1: [], player_2: [%Card{color: :gold, value: 7}]},
          "8" => %{winner: :na, player_1: big, player_2: sml},
          "9" => %{winner: :na, player_1: [%Card{color: :gold, value: 7}], player_2: [%Card{color: :gold, value: 7}]}
        } |> Map.new

      g = Game.new() |> Map.put(:battlefield, bt) |> Game.cleanup()

      assert g.battlefield["1"].winner == :player_1
      assert g.battlefield["5"].winner == :tie
      assert g.battlefield["8"].winner == :player_2
    end
  end
end
