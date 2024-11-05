package main

import "core:fmt"
import rl "vendor:raylib"

camera: rl.Camera2D

update_camera :: proc(player: ^Player, camera: ^rl.Camera2D) {
	camera.target = player.position

}


init_camera :: proc(player: Player) -> rl.Camera2D {
	return {
		{f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight()) / 2},
		{player.position.x, player.position.y},
		0.0,
		1.0,
	}
}
