defmodule ElixirSnake.Scene.Game do
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [text: 3, rrect: 3]

  @graph Graph.build(font: :roboto, font_size: 36)
  @tile_size 32
  @snake_starting_size 5
  @tile_radius 8
  @frame_ms 192
  @pellet_score 100

  @game_over_scene ElixirSnake.Scene.GameOver

  def init(_args, opts) do
    viewport = opts[:viewport]

    # Center snake in viewport
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    # Number of tiles a viewport can hold
    vp_tile_width = trunc(vp_width / @tile_size)
    vp_tile_height = trunc(vp_height / @tile_size)

    snake_start_coords = {
      trunc(vp_tile_width / 2),
      trunc(vp_tile_height / 2)
    }

    pellet_start_coords = {vp_tile_width - 2, trunc(vp_tile_height / 2)}
    initial_direction = {1, 0}

    {:ok, timer} = :timer.send_interval(@frame_ms, :frame)

    state = %{
      viewport: viewport,
      tile_width: vp_tile_width,
      tile_height: vp_tile_height,
      graph: @graph,
      frame_count: 1,
      frame_timer: timer,
      score: 0,
      frame_direction: initial_direction,
      objects: %{
        snake: %{
          body: [snake_start_coords],
          size: @snake_starting_size,
          direction: initial_direction
        },
        pellet: pellet_start_coords
      }
    }

    state.graph
    |> draw_score(state.score)
    |> draw_game_objects(state.objects)

    {:ok, state, push: @graph}
  end

  def handle_info(:frame, %{frame_count: frame_count} = state) do
    state = move_snake(state)

    new_graph = state.graph
                  |> draw_score(state.score)
                  |> draw_game_objects(state.objects)

    {:noreply, %{state | frame_count: frame_count + 1}, push: new_graph}
  end

  def handle_input({:key, {"left", :press, _}}, _context, state) do
    {:noreply, update_snake_direction(state, {-1, 0})}
  end

  def handle_input({:key, {"right", :press, _}}, _context, state) do
    {:noreply, update_snake_direction(state, {1, 0})}
  end

  def handle_input({:key, {"up", :press, _}}, _context, state) do
    {:noreply, update_snake_direction(state, {0, -1})}
  end

  def handle_input({:key, {"down", :press, _}}, _context, state) do
    {:noreply, update_snake_direction(state, {0, 1})}
  end

  def handle_input(_input, _context, state) do
    {:noreply, state}
  end

  defp update_snake_direction(%{frame_direction: {x, y}} = state, direction)
       when direction == {-1 * x, -1 * y} do
    state
  end

  defp update_snake_direction(state, direction) do
    {curr_x, curr_y} = get_in(state, [:objects, :snake, :direction])

    put_in(state, [:objects, :snake, :direction], direction)
  end

  defp draw_score(graph, score) do
    graph
    |> text("Score: #{score}", fill: :white, translate: {@tile_size, @tile_size})
  end

  defp draw_game_objects(graph, object_map) do
    Enum.reduce(object_map, graph, fn {object_type, object_data}, graph ->
      draw_object(graph, object_type, object_data)
    end)
  end

  defp draw_object(graph, :snake, %{body: snake}) do
    Enum.reduce(snake, graph, fn {x, y}, graph ->
      draw_tile(graph, x, y, fill: :lime)
    end)
  end

  defp draw_object(graph, :pellet, {pellet_x, pellet_y}) do
    draw_tile(graph, pellet_x, pellet_y, fill: :yellow, id: :pellet)
  end

  defp draw_tile(graph, x, y, opts) do
    tile_opts = Keyword.merge([fill: :white, translate: {x * @tile_size, y * @tile_size}], opts)
    graph |> rrect({@tile_size, @tile_size, @tile_radius}, tile_opts)
  end

  defp move_snake(%{objects: %{snake: snake}} = state) do
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

  defp maybe_die(state = %{viewport: vp, objects: %{snake: %{body: snake}}, score: score}) do
    if length(Enum.uniq(snake)) < length(snake) do
      ViewPort.set_root(vp, {@game_over_scene, score})
    end

    state
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
