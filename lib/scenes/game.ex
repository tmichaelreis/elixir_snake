defmodule ElixirSnake.Scene.Game do
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [text: 3, rrect: 3]

  alias ElixirSnake.GameEngine
  alias ElixirSnake.GameData

  @graph Graph.build(font: :roboto, font_size: 36)

  @tile_size 32
  @tile_radius 8
  @frame_ms 192

  @game_over_scene ElixirSnake.Scene.GameOver

  def init(_args, opts) do
    viewport = opts[:viewport]

    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    {:ok, timer} = :timer.send_interval(@frame_ms, :frame)

    game_data = %GameData{}

    tile_size = min(vp_width / game_data.board_width, vp_height / game_data.board_height)

    state = %{
      viewport: viewport,
      tile_size: tile_size,
      graph: @graph,
      frame_count: 1,
      frame_timer: timer,
      game_data: game_data
    }

    state[:graph]
    |> draw_score(GameData.score(game_data), tile_size)
    |> draw_game_objects(GameData.game_objects(game_data), tile_size)

    {:ok, state, push: @graph}
  end

  def handle_info(:frame, %{game_data: %GameData{}} = state) do
    state
    |> put_in([:game_data], GameEngine.move_snake(state[:game_data]))
    |> advance_frame()
  end

  def advance_frame(%{viewport: viewport, game_data: %GameData{score: score, dead: true}} = state) do
    ViewPort.set_root(viewport, {@game_over_scene, score})
    {:noreply, state}
  end

  def advance_frame(
        %{graph: graph, tile_size: tile_size, frame_count: frame_count, game_data: game_data} =
          state
      ) do
    new_graph =
      graph
      |> draw_score(GameData.score(game_data), tile_size)
      |> draw_game_objects(GameData.game_objects(game_data), tile_size)

    {:noreply, %{state | frame_count: frame_count + 1}, push: new_graph}
  end

  def handle_input({:key, {"left", :press, _}}, _context, state) do
    {:noreply, GameEngine.update_snake_direction(state, {-1, 0})}
  end

  def handle_input({:key, {"right", :press, _}}, _context, state) do
    {:noreply, GameEngine.update_snake_direction(state, {1, 0})}
  end

  def handle_input({:key, {"up", :press, _}}, _context, state) do
    {:noreply, GameEngine.update_snake_direction(state, {0, -1})}
  end

  def handle_input({:key, {"down", :press, _}}, _context, state) do
    {:noreply, GameEngine.update_snake_direction(state, {0, 1})}
  end

  def handle_input(_input, _context, state) do
    {:noreply, state}
  end

  defp draw_score(graph, score, tile_size) do
    graph
    |> text("Score: #{score}", fill: :white, translate: {tile_size, tile_size})
  end

  defp draw_game_objects(graph, object_map, tile_size) do
    Enum.reduce(object_map, graph, fn {object_type, object_data}, graph ->
      draw_object(graph, object_type, object_data, tile_size)
    end)
  end

  defp draw_object(graph, :snake, %{body: snake}, tile_size) do
    Enum.reduce(snake, graph, fn {x, y}, graph ->
      draw_tile(graph, x, y, tile_size, fill: :lime)
    end)
  end

  defp draw_object(graph, :pellet, {pellet_x, pellet_y}, tile_size) do
    draw_tile(graph, pellet_x, pellet_y, tile_size, fill: :yellow, id: :pellet)
  end

  defp draw_tile(graph, x, y, tile_size, opts) do
    tile_opts = Keyword.merge([fill: :white, translate: {x * tile_size, y * tile_size}], opts)
    graph |> rrect({tile_size, tile_size, @tile_radius}, tile_opts)
  end
end
