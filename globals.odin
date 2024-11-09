package main
import "core:fmt"
import rl "vendor:raylib"


enemies: [dynamic]Enemy
path_grid: Path_Grid
player: Player
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
) -> bool {
	draw(camera^)
	draw_level(camera)
	update_camera(player, camera)
	draw_game(enemy_animations)
	draw_player(player^, animations)
	check_collisions(level.entities, player)
	update_player(player, animations)
	update_enemies(enemies, player, enemy_animations)
	return !rl.WindowShouldClose()
}
// In your draw function
draw_game :: proc(animatons: map[EnemyState]Animation) {

	// Draw enemies
	draw_enemies(enemies, animatons)


}
