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
	enemy_sprite := rl.LoadTexture("./assets/Enemies/Skeleton.png")
	player := init_player(player_sprite)
	enemies := init_enemies(enemy_sprite)

	camera := init_camera(player)

	animations := init_animations()
	enemy_animations := init_enemy_animations()
	rl.SetTargetFPS(60)
	init_editor()

	defer rl.CloseWindow()
	defer rl.UnloadTexture(player_sprite)
	defer rl.UnloadTexture(enemy_sprite)
	defer write_level()

	defer rl.EndMode2D()
	for !rl.WindowShouldClose() {
		editor_mode(&camera)
		game_update(&player, &enemies, animations, enemy_animations, &camera)
	}

}


game_update :: proc(
	player: ^Player,
	enemies: ^[]Enemy,
	animations: map[Animation_State]Animation,
	enemy_animations: map[Animation_State]Animation,
	camera: ^rl.Camera2D,
) -> bool {
	draw(camera^)
	draw_level(camera)
	update_camera(player, camera)
	draw_player(player^, animations)
	draw_enemies(enemies, enemy_animations)
	check_collisions(level.entities, player)
	update_player(player, animations)
	update_enemies(enemies^, enemy_animations)
	return !rl.WindowShouldClose()
}


draw :: proc(camera: rl.Camera2D) {
	// rl.DrawTextureRec(player_sprite, frame_rect, player_position, rl.WHITE)

	rl.ClearBackground(rl.BLACK)
	rl.BeginMode2D(camera)
	rl.EndDrawing()
}
