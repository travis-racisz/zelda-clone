package main

import "core:fmt"
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

game_state: GameState

enemies: [dynamic]Enemy
path_grid: Path_Grid

game_screen_init :: proc() {
	// Only initialize if we haven't already
	if !game_state.initialized {
		fmt.println("Initializing new game state...")

		// init game resources 
		game_state.player_sprite = rl.LoadTexture("./assets/Player/Player.png")
		game_state.player = init_player(game_state.player_sprite)
		game_state.camera = init_camera(game_state.player)
		game_state.animations = init_animations()
		game_state.enemy_animations = init_enemy_animations()

		// init level and editor mode 
		init_editor()
		init_game()

		game_state.initialized = true
	} else {
		fmt.println("Resuming existing game state...")
	}
}
game_screen_update :: proc(dt: f32) {
	game_state.dt = dt

	if rl.IsKeyPressed(.P) {
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
		draw_game_ui()
		draw_level(&game_state.camera)
		draw_player(game_state.player, game_state.animations)
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

	// Draw health text
	rl.DrawText(
		strings.clone_to_cstring(fmt.tprintf("Health: %d%%", int(game_state.player.hp))),
		health_bar_x + 5,
		health_bar_y + 2,
		16,
		rl.WHITE,
	)

	// Draw debug info if enabled
}


init_game :: proc() {

	// Create some test enemies
	enemies = make([dynamic]Enemy)
	append(&enemies, init_enemy(rl.Vector2{400, 400}))
	append(&enemies, init_enemy(rl.Vector2{300, 300}))
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
