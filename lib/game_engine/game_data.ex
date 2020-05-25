defmodule ElixirSnake.GameData do
  alias ElixirSnake.Snake

  @initial_snake_size 5
  @board_width 20
  @board_height 20
  @initial_direction {1, 0}

  @snake_start_coords {
    trunc(@board_width / 2),
    trunc(@board_height / 2)
  }

  defstruct score: 0,
            dead: false,
            board_width: @board_width,
            board_height: @board_height,
            objects: %{
              snake: %Snake{
                body: [@snake_start_coords],
                size: @initial_snake_size,
                direction: @initial_direction
              },
              pellet: {@board_width - 2, trunc(@board_height / 2)}
            }

  def score(%{score: player_score}) do
    player_score
  end

  def game_objects(%{objects: objects}) do
    objects
  end
end
