defmodule ElixirSnake.Scene.Game do
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [text: 3, rrect: 3]

  alias ElixirSnake.GameEngine

  @graph Graph.build(font: :roboto, font_size: 36)
  @tile_size 32
  @snake_starting_size 5
  @tile_radius 8
  @frame_ms 192

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
      dead: false,
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

  def handle_info(:frame, %{dead: true, viewport: viewport, score: score} = state) do
    ViewPort.set_root(viewport, {@game_over_scene, score})
    {:noreply, state}
  end

  def handle_info(:frame, %{frame_count: frame_count} = state) do
    state = GameEngine.move_snake(state)

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
end
