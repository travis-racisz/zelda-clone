package main
import "base:builtin"
import "core:c/libc"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

Editor_State :: struct {
	geometry:                [dynamic]rl.Rectangle,
	selected_geometry:       int,
	sidebar_width:           i32,
	geometry_preview_size:   rl.Vector2,
	geometry_placement_size: rl.Vector2,
}

Entity :: struct {
	position: rl.Vector2,
	size:     rl.Vector2,
}

Level :: struct {
	entities: [dynamic]Entity,
}

level_background: rl.Texture2D
level: Level
editor_state: Editor_State
edit_mode: bool = false

init_editor :: proc() {
	editor_state.geometry = make([dynamic]rl.Rectangle)
	editor_state.selected_geometry = -1
	editor_state.sidebar_width = 200
	editor_state.geometry_preview_size = {15, 15}
	editor_state.geometry_placement_size = {15, 15}
}

get_cursor_world_pos :: proc(camera: ^rl.Camera2D) -> rl.Vector2 {
	mouse_pos := rl.GetMousePosition()

	// Get world space position relative to camera
	world_pos := rl.GetScreenToWorld2D(mouse_pos, camera^)

	// Snap to grid
	grid_x :=
		f32(int(world_pos.x) / int(editor_state.geometry_placement_size.x)) *
		editor_state.geometry_placement_size.x
	grid_y :=
		f32(int(world_pos.y) / int(editor_state.geometry_placement_size.y)) *
		editor_state.geometry_placement_size.y

	return rl.Vector2{grid_x, grid_y}
}

draw_editor_sidebar :: proc(camera: ^rl.Camera2D) {
	posX := i32(camera.target.x) - rl.GetScreenWidth() / 2
	posY := i32(camera.target.y) - rl.GetScreenHeight() / 2
	rl.DrawRectangle(0, 0, editor_state.sidebar_width, rl.GetScreenHeight(), rl.LIGHTGRAY)

	preview_rect := rl.Rectangle {
		x      = 20,
		y      = 20,
		width  = editor_state.geometry_preview_size.x,
		height = editor_state.geometry_preview_size.y,
	}

	// increment size on wheel scroll 
	rl.DrawRectangle(
		i32(preview_rect.x),
		i32(preview_rect.y),
		i32(preview_rect.width),
		i32(preview_rect.height),
		rl.RED,
	)
}

handle_editor_input :: proc(camera: ^rl.Camera2D) {
	if !edit_mode do return

	mouse_pos := rl.GetMousePosition()
	mouse_screen_x := mouse_pos.x - f32(editor_state.sidebar_width)

	// Handle clicking in the sidebar
	if mouse_pos.x < f32(editor_state.sidebar_width) {
		if rl.IsMouseButtonPressed(.LEFT) {
			if mouse_pos.y >= f32(10) &&
			   mouse_pos.y < f32(10 + editor_state.geometry_preview_size.y) {
				editor_state.selected_geometry = 0
			}
		}
	} else {
		// Handle placing rectangles in the world
		if editor_state.selected_geometry >= 0 && rl.IsMouseButtonPressed(.LEFT) {
			world_pos := get_cursor_world_pos(camera)

			new_entity := Entity {
				position = world_pos,
				size     = editor_state.geometry_placement_size,
			}
			append(&level.entities, new_entity)
		}
	}

	// Handle deletion with right click
	if rl.IsMouseButtonPressed(.RIGHT) && mouse_screen_x > 0 {
		world_pos := get_cursor_world_pos(camera)

		for i := len(level.entities) - 1; i >= 0; i -= 1 {
			entity := level.entities[i]

			if world_pos.x >= entity.position.x &&
			   world_pos.x <= entity.position.x + entity.size.x &&
			   world_pos.y >= entity.position.y &&
			   world_pos.y <= entity.position.y + entity.size.y {
				unordered_remove(&level.entities, i)
				break
			}
		}
	}
}

draw_editor_preview :: proc(camera: ^rl.Camera2D) {

	if !edit_mode do return

	if editor_state.selected_geometry >= 0 {
		mouse_pos := rl.GetMousePosition()
		if mouse_pos.x >= f32(editor_state.sidebar_width) {
			world_pos := get_cursor_world_pos(camera)

			// Draw semi-transparent preview rectangle at cursor position
			preview_rect := rl.Rectangle {
				x      = world_pos.x,
				y      = world_pos.y,
				width  = editor_state.geometry_preview_size.x,
				height = editor_state.geometry_preview_size.y,
			}
			mouse_wheel := rl.GetMouseWheelMove()
			if (mouse_wheel > 0) {


				scale_factor := 1.0 + (0.25 * libc.fabsf(mouse_wheel))
				if (mouse_wheel < 0) do scale_factor = 1.0 / scale_factor
				editor_state.geometry_preview_size.x += 1
				editor_state.geometry_preview_size.y += 1
				editor_state.geometry_placement_size.x += 1
				editor_state.geometry_placement_size.y += 1

			} else if (mouse_wheel < 0) {

				editor_state.geometry_preview_size.x -= 1
				editor_state.geometry_preview_size.y -= 1
				editor_state.geometry_placement_size.x -= 1
				editor_state.geometry_placement_size.y -= 1

			}
			// Convert world space rectangle to screen space for drawing
			screen_rect := rl.GetWorldToScreen2D({preview_rect.x, preview_rect.y}, camera^)
			rl.DrawRectangle(
				i32(world_pos.x),
				i32(world_pos.y),
				i32(preview_rect.width),
				i32(preview_rect.height),
				rl.ColorAlpha(rl.RED, 0.5),
			)
		}
	}
}

draw_level :: proc(camera: ^rl.Camera2D) {
	// Draw the background first
	rl.DrawTexture(level_background, 0, 0, rl.WHITE)

	// Draw grid overlay
	//	grid_size := rl.Vector2 {
	//		editor_state.geometry_placement_size.x,
	//		editor_state.geometry_placement_size.y,
	//	}
	//
	//	// Calculate grid boundaries based on screen size and camera
	//	screen_min := rl.GetScreenToWorld2D(rl.Vector2{0, 0}, camera^)
	//	screen_max := rl.GetScreenToWorld2D(
	//		rl.Vector2{f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())},
	//		camera^,
	//	)
	//
	//	// Draw vertical lines
	//	for x := f32(int(screen_min.x / grid_size.x) * int(grid_size.x));
	//	    x < screen_max.x;
	//	    x += grid_size.x {
	//		start_pos := rl.Vector2{x, screen_min.y}
	//		end_pos := rl.Vector2{x, screen_max.y}
	//		rl.DrawLineV(start_pos, end_pos, rl.ColorAlpha(rl.WHITE, 0.5))
	//	}
	//
	//	// Draw horizontal lines
	//	for y := f32(int(screen_min.y / grid_size.y) * int(grid_size.y));
	//	    y < screen_max.y;
	//	    y += grid_size.y {
	//		start_pos := rl.Vector2{screen_min.x, y}
	//		end_pos := rl.Vector2{screen_max.x, y}
	//		rl.DrawLineV(start_pos, end_pos, rl.ColorAlpha(rl.WHITE, 0.5))
	//	}

	// Draw entities
	for entity in level.entities {
		rl.DrawRectangle(
			i32(entity.position.x),
			i32(entity.position.y),
			i32(entity.size.x),
			i32(entity.size.y),
			rl.BLANK,
		)
	}
}


write_level :: proc() {
	if level_data, err := json.marshal(level); err == nil {
		os.write_entire_file("level.json", level_data)
	}

	delete(level.entities)

}

load_level :: proc() {

	level_background = rl.LoadTexture("./assets/level_1.png")
	if level_data, ok := os.read_entire_file("level.json"); ok {
		if json.unmarshal(level_data, &level) != nil {
			// return if something went wrong 
			// returns nil when successfully loaded level
			rl.DrawText(
				"LEVEL FAILED TO LOAD",
				rl.GetScreenWidth() / 2,
				rl.GetScreenHeight() / 2,
				150,
				rl.RED,
			)

		}
		// draw level


	}

}


editor_mode :: proc(camera: ^rl.Camera2D) {
	if (rl.IsKeyPressed(.F3)) {
		if camera.zoom == 4.0 {
			camera.zoom = 1.0
		} else {

			camera.zoom = 4.0
		}
	}

	if rl.IsKeyPressed(.F2) {
		edit_mode = !edit_mode
	}

	if edit_mode {

		rl.DrawText("Edit Mode", 500, 100, 80, rl.RED)
		draw_editor_sidebar(&camera^)
		handle_editor_input(&camera^)
		draw_editor_preview(&camera^)
	} else {
		camera.zoom = 4.0
	}
}

check_collisions :: proc(entities: [dynamic]Entity, player: ^Player) {
	player_rect := rl.Rectangle {
		x      = player.position.x,
		y      = player.position.y,
		width  = f32(player.sprite_sheet.width / player.sprite_cols),
		height = f32(player.sprite_sheet.height / player.sprite_rows),
	}

	rl.DrawRectangle(
		i32(player_rect.x),
		i32(player_rect.y),
		i32(player_rect.width),
		i32(player_rect.height),
		rl.BLANK,
	)

	for entity in entities {
		entity_rect := rl.Rectangle {
			x      = entity.position.x,
			y      = entity.position.y,
			width  = entity.size.x,
			height = entity.size.y,
		}
		rl.DrawRectangle(
			i32(entity.position.x),
			i32(entity.position.y),
			i32(entity.size.x),
			i32(entity.size.y),
			rl.BLANK,
		)

		if rl.CheckCollisionRecs(player_rect, entity_rect) {
			// Calculate collision depths on each axis
			overlap_x := min(
				player_rect.x + player_rect.width - entity_rect.x,
				entity_rect.x + entity_rect.width - player_rect.x,
			)
			overlap_y := min(
				player_rect.y + player_rect.height - entity_rect.y,
				entity_rect.y + entity_rect.height - player_rect.y,
			)

			// Resolve collision by pushing back the player along the axis of least penetration
			if overlap_x < overlap_y {
				// Horizontal collision
				if player_rect.x < entity_rect.x {
					player.position.x = entity_rect.x - player_rect.width
				} else {
					player.position.x = entity_rect.x + entity_rect.width
				}
			} else {
				// Vertical collision
				if player_rect.y < entity_rect.y {
					player.position.y = entity_rect.y - player_rect.height
				} else {
					player.position.y = entity_rect.y + entity_rect.height
				}
			}
		}
	}
}
