defmodule ElixirSnake.GameEngine do
  @pellet_score 100

  def move_snake(%{objects: %{snake: snake}} = state) do
    [head | _] = snake.body
    new_head_pos = move(state, head, snake.direction)

    new_body = Enum.take([new_head_pos | snake.body], snake.size)

    state
    |> put_in([:objects, :snake, :body], new_body)
    |> put_in([:frame_direction], snake.direction)
    |> maybe_eat_pellet(new_head_pos)
    |> maybe_die()
  end

  defp maybe_eat_pellet(%{objects: %{pellet: pellet_coords}} = state, snake_head_coords)
    when pellet_coords == snake_head_coords do
    state
    |> randomize_pellet()
    |> add_score(@pellet_score)
    |> grow_snake()
  end

  defp maybe_eat_pellet(state, _), do: state

  defp randomize_pellet(state = %{tile_width: w, tile_height: h}) do
    pellet_coords = {
      Enum.random(0..(w - 1)),
      Enum.random(0..(h - 1))
    }

    validate_pellet_coords(state, pellet_coords)
  end

  defp validate_pellet_coords(%{objects: %{snake: %{body: snake}}} = state, coords) do
    if coords in snake,
      do: randomize_pellet(state),
      else: put_in(state, [:objects, :pellet], coords)
  end

  defp maybe_die(%{objects: %{snake: %{body: snake}}} = state) do
    if length(Enum.uniq(snake)) < length(snake) do
      Map.put(state, :dead, true)
    else
      state
    end
  end

  defp add_score(state, amount) do
    update_in(state, [:score], &(&1 + amount))
  end

  defp grow_snake(state) do
    update_in(state, [:objects, :snake, :size], &(&1 + 1))
  end

  defp move(%{tile_width: w, tile_height: h}, {pos_x, pos_y}, {vec_x, vec_y}) do
    {rem(pos_x + vec_x + w, w), rem(pos_y + vec_y + h, h)}
  end
end