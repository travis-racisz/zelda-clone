package main

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import rl "vendor:raylib"


Levels :: enum {
	HOMETOWN,
	CAVE,
}

GameState :: struct {
	player:           Player,
	camera:           rl.Camera2D,
	animations:       map[Animation_State]Animation,
	enemy_animations: map[EnemyState]Animation,
	player_sprite:    rl.Texture2D,
	dt:               f32,
	initialized:      bool,
	current_level:    Levels,
}

SaveData :: struct {
	// Game state data
	player_position: rl.Vector2,
	player_health:   int,
	current_level:   Levels,

	// Enemy data
	enemy_positions: []rl.Vector2,
}


game_state: GameState

enemies: [dynamic]Enemy
path_grid: Path_Grid

game_screen_init :: proc() {
	if !game_state.initialized {
		// Initialize common resources regardless of new/load game
		game_state.player_sprite = rl.LoadTexture("./assets/Player/Player.png")
		game_state.animations = init_animations()
		game_state.enemy_animations = init_enemy_animations()
		init_editor()
		if title_screen_state.selected_option == .NewGame {
			game_state.player = init_player(game_state.player_sprite)
			game_state.camera = init_camera(game_state.player)
			game_state.current_level = .HOMETOWN

			init_game()
			load_level(game_state.current_level)

			os.remove("./save_game.json")
			create_save_file()
			fmt.print(title_screen_state.selected_option)
			fmt.print("creating new save file ")
		} else if title_screen_state.selected_option == .LoadGame {
			fmt.print("loading game")
			// Initialize base player and camera
			if check_save_exists() {

				game_state.player = init_player(game_state.player_sprite)
				game_state.camera = init_camera(game_state.player)

				load_level(game_state.current_level)
				// load_save_file()
				if !load_save_file() {
					// Handle load failure - could revert to new game or show error
					fmt.println("Failed to load save file, starting new game")
					init_game()
					load_level(game_state.current_level)
				}

			}
		}

		game_state.initialized = true
	} else {
		fmt.println("Resuming existing game state...")
	}
}

create_save_file :: proc() -> bool {
	// Create save data structure
	save_data := SaveData {
		player_position = game_state.player.position,
		player_health   = game_state.player.hp,
		current_level   = game_state.current_level,
		enemy_positions = make([]rl.Vector2, len(enemies)),
	}

	// Populate enemy data
	for enemy, i in enemies {
		save_data.enemy_positions[i] = enemy.position
	}

	// Serialize to JSON
	data, err := json.marshal(save_data)
	if err != nil {
		fmt.eprintln("Error marshaling save data:", err)
		return false
	}

	// Write to file
	if os.write_entire_file("save_game.json", data) {
		fmt.println("Game saved successfully")
		return true
	} else {
		fmt.eprintln("Error writing save file")
		return false
	}
}

load_save_file :: proc() -> bool {
	data, ok := os.read_entire_file("save_game.json")
	if !ok {
		fmt.eprintln("Could not read save file")
		return false
	}

	save_data: SaveData
	if err := json.unmarshal(data, &save_data); err != nil {
		fmt.eprintln("Error unmarshaling save data:", err)
		return false
	}

	// Restore game state
	game_state.player.position = save_data.player_position
	game_state.player.hp = save_data.player_health
	game_state.current_level = save_data.current_level

	// Restore enemies
	clear(&enemies)
	for pos, i in save_data.enemy_positions {
		enemy := init_enemy(pos)
		append(&enemies, enemy)
	}

	return true
}

check_save_exists :: proc() -> bool {
	when ODIN_OS == .Windows {
		file_handle := os.open("save_game.json")
		if file_handle == os.INVALID_HANDLE {
			return false
		}
		os.close(file_handle)
		return true
	} else {
		return os.exists("save_game.json")
	}
}


game_screen_update :: proc(dt: f32) {
	game_state.dt = dt

	if rl.IsKeyPressed(.ESCAPE) {
		change_screen(.Pause)
		return

	}

	// editor_mode(&game_state.camera)
	game_update(
		&game_state.player,
		&enemies,
		game_state.animations,
		game_state.enemy_animations,
		&game_state.camera,
		game_state.dt,
	)


}

game_screen_draw :: proc() {

	rl.ClearBackground(rl.BLACK)

	rl.BeginMode2D(game_state.camera)
	{
		draw_level(&game_state.camera)
		draw_player(game_state.player, game_state.animations)
		draw_game_ui()
		draw_game(game_state.enemy_animations)

	}

	rl.EndMode2D()

}


game_screen_unload :: proc() {
	// Only perform cleanup when we're actually quitting or restarting
	if screen_manager.current_screen != .Pause {
		fmt.println("Fully unloading game state...")

		// Clean up animations

		delete(game_state.animations)

		// Clean up enemy animations

		delete(game_state.enemy_animations)

		// Unload textures
		rl.UnloadTexture(game_state.player_sprite)

		// Clean up enemies
		cleanup_game()

		// Reset game state
		game_state = GameState{}
	} else {
		fmt.println("Preserving game state while paused...")
	}
}


// UI drawing procedure
draw_game_ui :: proc() {
	// Draw any HUD elements, health bars, etc.
	health_bar_width := i32(200)
	health_bar_height := i32(20)
	health_bar_x := i32(20)
	health_bar_y := i32(20)

	// Draw health background
	rl.DrawRectangle(health_bar_x, health_bar_y, health_bar_width, health_bar_height, rl.DARKGRAY)

	// Draw current health
	current_health_width := int(health_bar_width) * (game_state.player.hp / 100.0)
	rl.DrawRectangle(
		health_bar_x,
		health_bar_y,
		i32(current_health_width),
		health_bar_height,
		rl.RED,
	)
	cstr := strings.clone_to_cstring(fmt.tprintf("Health: %d%%", int(game_state.player.hp)))

	// Draw health text
	rl.DrawText(cstr, health_bar_x + 5, health_bar_y + 2, 16, rl.WHITE)

	// Draw debug info if enabled
	defer delete(cstr)
}


init_game :: proc() {

	// Create some test enemies
	enemies = make([dynamic]Enemy)
	append(&enemies, init_enemy(rl.Vector2{400, 400}))
	append(&enemies, init_enemy(rl.Vector2{300, 300}))

	//create exit square 
}

cleanup_game :: proc() {

	delete(enemies)
}


game_update :: proc(
	player: ^Player,
	enemies: ^[dynamic]Enemy,
	animations: map[Animation_State]Animation,
	enemy_animations: map[EnemyState]Animation,
	camera: ^rl.Camera2D,
	dt: f32,
) {
	// draw(camera^)
	// draw_level(camera)
	editor_mode(&game_state.camera)
	check_collisions(level.entities, player)
	update_camera(player^, camera)
	update_player(player, animations)
	update_enemies(enemies, player, enemy_animations)
}
// In your draw function
draw_game :: proc(animatons: map[EnemyState]Animation) {

	// Draw enemies
	draw_enemies(enemies, animatons)


}
