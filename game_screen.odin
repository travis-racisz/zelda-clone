package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

GameState :: struct {
	player:           Player,
	camera:           rl.Camera2D,
	animations:       map[Animation_State]Animation,
	enemy_animations: map[EnemyState]Animation,
	player_sprite:    rl.Texture2D,
	dt:               f32,
}

game_state: GameState


game_screen_init :: proc() {
	// init game resources 
	game_state.player_sprite = rl.LoadTexture("./assets/Player/Player.png")
	game_state.player = init_player(game_state.player_sprite)
	game_state.camera = init_camera(game_state.player)
	game_state.animations = init_animations()
	game_state.enemy_animations = init_enemy_animations()


	// init level and editor mode 
	load_level()
	init_editor()
	init_game()

}

game_screen_update :: proc(dt: f32) {
	game_state.dt = dt

	if rl.IsKeyPressed(.ESCAPE) {
		change_screen(.Pause)
		return

	}

	editor_mode(&game_state.camera)
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

	rl.ClearBackground(rl.GREEN)
	rl.BeginMode2D(game_state.camera)


	// draw the level 
	draw_level(&game_state.camera)

	draw_game(game_state.enemy_animations)

	rl.EndMode2D()

	draw_game_ui()

}


game_screen_unload :: proc() {
	rl.UnloadTexture(game_state.player_sprite)


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
