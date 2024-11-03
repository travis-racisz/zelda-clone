package main
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
	editor_state.geometry_preview_size = {64, 64}
	editor_state.geometry_placement_size = {64, 64}
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
	rl.DrawRectangle(posX, posY, editor_state.sidebar_width, rl.GetScreenHeight(), rl.LIGHTGRAY)

	preview_rect := rl.Rectangle {
		x      = f32(posX + 10),
		y      = f32(posY + 10),
		width  = editor_state.geometry_preview_size.x,
		height = editor_state.geometry_preview_size.y,
	}

	if len(editor_state.geometry) == 0 {
		append(&editor_state.geometry, preview_rect)
	}

	for geo, i in editor_state.geometry {
		color := i == editor_state.selected_geometry ? rl.RED : rl.DARKGRAY
		rl.DrawRectangleRec(geo, color)
	}
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
				width  = editor_state.geometry_placement_size.x,
				height = editor_state.geometry_placement_size.y,
			}

			// Convert world space rectangle to screen space for drawing
			screen_rect := rl.GetWorldToScreen2D({preview_rect.x, preview_rect.y}, camera^)
			rl.DrawRectangle(
				i32(world_pos.x),
				i32(world_pos.y),
				i32(preview_rect.width * camera.zoom),
				i32(preview_rect.height * camera.zoom),
				rl.ColorAlpha(rl.RED, 0.5),
			)
		}
	}
}

draw_level :: proc(camera: ^rl.Camera2D) {
	rl.DrawTexture(level_background, 0, 0, rl.WHITE)

	for entity in level.entities {
		// Convert world position to screen position
		screen_pos := rl.GetWorldToScreen2D(entity.position, camera^)

		rl.DrawRectangle(
			i32(entity.position.x),
			i32(entity.position.y),
			i32(entity.size.x * camera.zoom),
			i32(entity.size.y * camera.zoom),
			rl.RED,
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
	if rl.IsKeyPressed(.F2) {
		edit_mode = !edit_mode
	}

	if edit_mode {
		camera.zoom = 1.0

		rl.DrawText("Edit Mode", 500, 100, 80, rl.RED)
		draw_editor_sidebar(&camera^)
		handle_editor_input(&camera^)
		draw_editor_preview(&camera^)
	} else {
		camera.zoom = 4.0
	}
}
