package main

import "core:fmt"
import rl "vendor:raylib"


// TODO: add entities 
// TODO: add collision 
// TODO: build level
// TODO: Build level editor 
// add allocator checker for memory leaks


main :: proc() {
	rl.InitWindow(1920, 1080, "ZeldaClone")
	load_level()

	player_sprite := rl.LoadTexture("./assets/Player/Player.png")
	player := init_player(player_sprite)
	dt := rl.GetFrameTime()
	camera := init_camera(player)
	animations := init_animations()
	enemy_animations := init_enemy_animations()

	rl.SetTargetFPS(60)
	init_editor()
	init_game()
	path_grid := init_path_grid(
		int(level_background.width / i32(editor_state.geometry_placement_size.x)),
		int(level_background.height / i32(editor_state.geometry_placement_size.y)),
		editor_state.geometry_placement_size.x,
	)
	defer cleanup_path_grid(&path_grid)
	defer rl.CloseWindow()
	defer rl.UnloadTexture(player_sprite)
	defer write_level()

	defer rl.EndMode2D()
	for !rl.WindowShouldClose() {
		if rl.IsKeyPressed(.F4) {
			show_pathfinding = !show_pathfinding
		}
		if show_pathfinding && rl.IsMouseButtonPressed(.LEFT) {
			world_pos := get_cursor_world_pos(&camera)
			grid_pos := Grid_Position {
				x = int(world_pos.x / path_grid.cell_size),
				y = int(world_pos.y / path_grid.cell_size),
			}

			if rl.IsKeyDown(.LEFT_SHIFT) {
				path_grid.end = grid_pos
			} else {
				path_grid.start = grid_pos
			}
			find_path(&path_grid, path_grid.start, path_grid.end)
		}

		// Update pathfinding grid with current entities
		update_walkable_from_entities(&path_grid, level.entities[:])

		// Draw pathfinding visualization if enabled
		if show_pathfinding {
			draw_path_debug(&path_grid)
		}
		editor_mode(&camera)
		game_update(&player, &enemies, animations, enemy_animations, &camera, dt)
	}

}


draw :: proc(camera: rl.Camera2D) {
	// rl.DrawTextureRec(player_sprite, frame_rect, player_position, rl.WHITE)

	rl.ClearBackground(rl.BLACK)
	rl.BeginMode2D(camera)
	rl.EndDrawing()
}
