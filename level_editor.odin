package main
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

Editor_State :: struct {
	textures:            [dynamic]rl.Texture2D,
	texture_names:       [dynamic]cstring, // Store names for debugging/saving
	selected_texture:    int, // Index of currently selected texture
	sidebar_width:       i32, // Width of the editor sidebar
	tile_preview_size:   i32, // Size of texture previews in sidebar
	tile_placement_size: i32, // Size of placed tiles in world
}

Entity :: struct {
	name:     cstring,
	position: rl.Vector2,
}

Level :: struct {
	entities: [dynamic]Entity,
}
level: Level
editor_state: Editor_State
edit_mode: bool = false
// Initialize the editor
init_editor :: proc() {
	// Initialize dynamic arrays
	editor_state.textures = make([dynamic]rl.Texture2D)
	editor_state.texture_names = make([dynamic]cstring)
	editor_state.selected_texture = -1
	editor_state.sidebar_width = 200
	editor_state.tile_preview_size = 64
	editor_state.tile_placement_size = 64

	texture_files := []cstring {
		"./assets/Tiles/Beach_Tile.png",
		"./assets/Tiles/Cliff_Tile.png",
		"./assets/Tiles/FarmLand_Tile.png",
		"./assets/Tiles/Grass_Middle.png",
	}

	for file in texture_files {

		texture := rl.LoadTexture(file)
		append(&editor_state.textures, texture)
		append(&editor_state.texture_names, file)
	}
}


cleanup_editor :: proc() {
	for texture in editor_state.textures {
		rl.UnloadTexture(texture)
	}
	for name in editor_state.texture_names {
		delete(name) // Clean up the cloned strings
	}
	delete(editor_state.textures)
	delete(editor_state.texture_names)
}

draw_editor_sidebar :: proc() {
	// Draw sidebar background
	rl.DrawRectangle(0, 0, editor_state.sidebar_width, rl.GetScreenHeight(), rl.LIGHTGRAY)

	// Draw texture selection menu
	for texture, i in editor_state.textures {
		pos_x := i32(10)
		pos_y := i32(10 + i * (int(editor_state.tile_preview_size) + 10))

		if i == editor_state.selected_texture {
			rl.DrawRectangle(
				pos_x - 5,
				pos_y - 5,
				editor_state.tile_preview_size + 10,
				editor_state.tile_preview_size + 10,
				rl.BLUE,
			)
		}

		rl.DrawTexturePro(
			texture,
			rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)},
			rl.Rectangle {
				f32(pos_x),
				f32(pos_y),
				f32(editor_state.tile_preview_size),
				f32(editor_state.tile_preview_size),
			},
			rl.Vector2{0, 0},
			0,
			rl.WHITE,
		)


		rl.DrawText(
			editor_state.texture_names[i],
			pos_x + editor_state.tile_preview_size + 10,
			pos_y + editor_state.tile_preview_size / 2 - 10,
			20,
			rl.BLACK,
		)
	}
}

handle_editor_input :: proc() {
	mouse_pos := rl.GetMousePosition()

	// Handle clicking in the sidebar (texture selection)
	if mouse_pos.x < f32(editor_state.sidebar_width) {
		if rl.IsMouseButtonPressed(.LEFT) {
			// Calculate which texture was clicked
			for i := 0; i < len(editor_state.textures); i += 1 {
				pos_y := i32(10 + i * (int(editor_state.tile_preview_size) + 10))

				// Check if click was within this texture's bounds
				if mouse_pos.y >= f32(pos_y) &&
				   mouse_pos.y < f32(pos_y + editor_state.tile_preview_size) {
					editor_state.selected_texture = i

					editor_state.tile_placement_size =
						rl.LoadTexture(editor_state.texture_names[editor_state.selected_texture]).width
					break
				}
			}
		}
	} else {
		// Handle placing textures in the world
		if editor_state.selected_texture >= 0 && rl.IsMouseButtonPressed(.LEFT) {
			editor_state.tile_placement_size =
				rl.LoadTexture(editor_state.texture_names[editor_state.selected_texture]).width
			// Grid snap the placement position
			grid_x :=
				i32((mouse_pos.x / f32(editor_state.tile_placement_size))) *
				editor_state.tile_placement_size
			grid_y :=
				i32((mouse_pos.y / f32(editor_state.tile_placement_size))) *
				editor_state.tile_placement_size

			// TODO: Store the placed tile in your level data structure
			// This is where you'd add the tile to your level data
			// add json to write to level file

			append(
				&level.entities,
				Entity {
					editor_state.texture_names[editor_state.selected_texture],
					{f32(grid_x), f32(grid_y)},
				},
			)
			fmt.printf(
				"Placed texture %s at grid position (%d, %d)\n",
				editor_state.texture_names[editor_state.selected_texture],
				grid_x,
				grid_y,
			)
		}
	}
}

draw_editor_preview :: proc() {
	// Draw preview of selected texture at mouse position if one is selected
	if editor_state.selected_texture > 0 {
		mouse_pos := rl.GetMousePosition()

		// Only show preview when mouse is in the game area
		if mouse_pos.x >= f32(editor_state.sidebar_width) {
			// Grid snap the preview position
			grid_x :=
				i32((mouse_pos.x / f32(editor_state.tile_placement_size))) *
				editor_state.tile_placement_size
			grid_y :=
				i32((mouse_pos.y / f32(editor_state.tile_placement_size))) *
				editor_state.tile_placement_size

			// Draw semi-transparent preview
			texture := editor_state.textures[editor_state.selected_texture]
			rl.DrawTexturePro(
				texture,
				rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)},
				rl.Rectangle {
					f32(grid_x),
					f32(grid_y),
					f32(editor_state.tile_placement_size),
					f32(editor_state.tile_placement_size),
				},
				rl.Vector2{0, 0},
				0,
				rl.ColorAlpha(rl.WHITE, 0.5),
			)
		}
	}
}

editor_mode :: proc() {
	if rl.IsKeyPressed(.F2) {
		edit_mode = !edit_mode
	}

	if edit_mode {

		rl.DrawText("Edit Mode", 500, 100, 80, rl.RED)
		draw_editor_sidebar()
		handle_editor_input()
		draw_editor_preview()
	}
}

write_level :: proc() {
	if level_data, err := json.marshal(level); err == nil {
		os.write_entire_file("level.json", level_data)
	}

	delete(level.entities)

}

load_level :: proc() {

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

draw_level :: proc() {
	for ent in level.entities {
		rl.DrawTexture(
			rl.LoadTexture(ent.name),
			i32(ent.position.x),
			i32(ent.position.y),
			rl.WHITE,
		)
	}


}

