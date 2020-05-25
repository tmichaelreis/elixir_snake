defmodule ElixirSnake.GameEngine do
  alias ElixirSnake.GameData

  @pellet_score 100

  @spec move_snake(ElixirSnake.GameData.t()) :: %{objects: %{snake: %{body: [any]}}}
  def move_snake(%GameData{objects: %{snake: snake}} = game_data) do
    [head | _] = snake.body

    new_head_pos = move(game_data, head, snake.direction)

    new_body = Enum.take([new_head_pos | snake.body], snake.size)

    game_data
    |> put_in([:objects, :snake, :body] |> Enum.map(&Access.key/1), new_body)
    |> put_in([:objects, :snake, :direction] |> Enum.map(&Access.key/1), snake.direction)
    |> maybe_eat_pellet(new_head_pos)
    |> maybe_die()
  end

  def update_snake_direction(
        %{game_data: %{objects: %{snake: %{direction: {x, y}}}}} = state,
        direction
      )
      when direction == {-1 * x, -1 * y} do
    state
  end

  def update_snake_direction(state, direction) do
    put_in(
      state,
      [:game_data, :objects, :snake, :direction] |> Enum.map(&Access.key/1),
      direction
    )
  end

  defp move(%{board_width: w, board_height: h}, {pos_x, pos_y}, {vec_x, vec_y}) do
    {rem(pos_x + vec_x + w, w), rem(pos_y + vec_y + h, h)}
  end

  defp maybe_eat_pellet(%{objects: %{pellet: pellet_coords}} = game_data, snake_head_coords)
       when pellet_coords == snake_head_coords do
    game_data
    |> randomize_pellet()
    |> add_score(@pellet_score)
    |> grow_snake()
  end

  defp maybe_eat_pellet(game_data, _), do: game_data

  defp randomize_pellet(game_data = %{board_width: w, board_height: h}) do
    pellet_coords = {
      Enum.random(0..(w - 1)),
      Enum.random(0..(h - 1))
    }

    validate_pellet_coords(game_data, pellet_coords)
  end

  defp validate_pellet_coords(%{objects: %{snake: %{body: snake}}} = game_data, coords) do
    if coords in snake,
      do: randomize_pellet(game_data),
      else: put_in(game_data, [:objects, :pellet] |> Enum.map(&Access.key/1), coords)
  end

  defp maybe_die(%{objects: %{snake: %{body: snake}}} = game_data) do
    if length(Enum.uniq(snake)) < length(snake) do
      put_in(game_data.dead, true)
    else
      game_data
    end
  end

  defp add_score(game_data, amount) do
    update_in(game_data.score, &(&1 + amount))
  end

  defp grow_snake(game_data) do
    update_in(game_data.objects.snake.size, &(&1 + 1))
  end
end
