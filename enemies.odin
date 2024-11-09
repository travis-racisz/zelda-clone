package main
import "core:fmt"
import "core:math"
import "core:slice"
import rl "vendor:raylib"


EnemyState :: enum {
	IDLE,
	WALKING_NORTH,
	WALKING_SOUTH,
	WALKING_EAST,
	WALKING_WEST,
	ATTACKING,
	COOLDOWN,
	DEAD,
}

Aggro :: struct {
	position: rl.Vector2,
	radius:   f32,
}


Enemy :: struct {
	position:      rl.Vector2,
	aggro:         Aggro,
	sprite_sheet:  rl.Texture2D,
	state:         EnemyState,
	target:        rl.Vector2,
	speed:         f32,
	direction:     Direction,
	size:          rl.Vector2,
	current_frame: i32,
	frame_counter: i32,
	sprite_cols:   i32,
	sprite_rows:   i32,
	hp:            i32,
	is_dying:      bool, // Add this to track death animation
	flash_timer:   f32, // Add this for the red flash effect
}

ENEMY_SPEED :: f32(100) // Pixels per second

init_enemy :: proc(pos: rl.Vector2) -> Enemy {
	aggro := Aggro{pos, 50.0}
	enemy_sprite_sheet := rl.LoadTexture("./assets/Enemies/Skeleton.png")
	return Enemy {
		position      = pos,
		sprite_sheet  = enemy_sprite_sheet,
		aggro         = aggro,
		direction     = .SOUTH,
		target        = pos,
		speed         = ENEMY_SPEED,
		current_frame = 0,
		sprite_cols   = 6,
		sprite_rows   = 10,
		hp            = 1,
		size          = {32, 32}, // Adjust size as needed
	}
}

init_enemy_animations :: proc() -> map[EnemyState]Animation {
	animations := make(map[EnemyState]Animation)


	// configure each animation state 

	animations[.IDLE] = Animation {
		row          = 0,
		frames       = 6,
		frame_speed  = 8,
		blocks_input = false,
	}

	animations[.WALKING_NORTH] = Animation {
		row          = 5,
		frames       = 6,
		frame_speed  = 8,
		blocks_input = false,
	}
	animations[.WALKING_SOUTH] = Animation {
		row          = 3,
		frames       = 6,
		frame_speed  = 8,
		blocks_input = false,
	}

	animations[.WALKING_EAST] = Animation {
		row          = 4,
		frames       = 6,
		frame_speed  = 8,
		blocks_input = false,
	}

	animations[.WALKING_WEST] = Animation {
		row          = 4,
		frames       = 6,
		frame_speed  = 8,
		blocks_input = false,
	}

	animations[.DEAD] = Animation {
		row          = 6,
		frames       = 4,
		frame_speed  = 8,
		blocks_input = true,
	}

	return animations


}


update_enemies :: proc(
	enemies: ^[dynamic]Enemy,
	player: ^Player,
	animations: map[EnemyState]Animation,
) {

	for &enemy, idx in enemies {
		// check if enemy is inside of enemy aggro range 
		// if so walk at them 
		// when in range attack 
		if enemy.flash_timer > 0 {
			enemy.flash_timer -= rl.GetFrameTime()
		}

		if player.current_state == .DEAD {
			enemy.state = .IDLE
			return

		}

		// If enemy is dying, only update death animation
		if enemy.is_dying {
			current_anim := animations[.DEAD]
			enemy.frame_counter += 1
			if enemy.frame_counter >= current_anim.frame_speed {
				enemy.frame_counter = 0
				if enemy.current_frame < current_anim.frames - 1 {
					enemy.current_frame += 1
				} else {
					// Death animation complete, remove enemy
					ordered_remove(&enemies^, idx)
				}
			}
			continue // Skip normal update for dying enemies
		}

		if rl.CheckCollisionPointCircle(
			player.position,
			rl.Vector2{enemy.position.x + 15, enemy.position.y + 15},
			200.0,
		) {
			current_anim := animations[enemy.state]
			enemy.frame_counter += 1
			if enemy.frame_counter >= current_anim.frame_speed {
				enemy.frame_counter = 0
				enemy.current_frame = (enemy.current_frame + 1) % current_anim.frames

				// If this animation blocks input and has completed, return to idle
				if current_anim.blocks_input && enemy.current_frame == 0 {
					enemy.state = .IDLE
				}
			}


			// player is in aggro range
			if rl.CheckCollisionPointCircle(
				player.position,
				rl.Vector2{enemy.position.x + 15, enemy.position.y + 15},
				200.0,
			) {
				if int(enemy.position.x) != int(player.position.x) {
					// check if player is more to the right or left 
					if (enemy.position.x < player.position.x) {
						// move to the right 
						enemy.position.x += 1
						enemy.state = .WALKING_EAST
						enemy.direction = .EAST

					} else if (enemy.position.x > player.position.x) {
						// move to the left 

						enemy.position.x -= 1
						enemy.state = .WALKING_WEST
						enemy.direction = .WEST
					}

				} else if (enemy.position.y != player.position.y) {
					// move up or down 
					if enemy.position.y < player.position.y {
						// move down 
						enemy.position.y += 1
						enemy.state = .WALKING_SOUTH
						enemy.direction = .SOUTH
					} else if enemy.position.y > player.position.y {
						enemy.position.y -= 1
						enemy.state = .WALKING_NORTH
						enemy.direction = .NORTH
					}

				}

			} else {
				enemy.state = .IDLE

			}

		}

	}
}

draw_enemies :: proc(enemies: [dynamic]Enemy, animations: map[EnemyState]Animation) {
	for enemy in enemies {
		current_anim := animations[enemy.state]

		frame_width := enemy.sprite_sheet.width / enemy.sprite_cols
		frame_height := enemy.sprite_sheet.height / enemy.sprite_rows

		source := rl.Rectangle {
			x      = f32(enemy.current_frame * frame_width),
			y      = f32(current_anim.row * frame_height),
			height = f32(frame_height),
		}

		dest := rl.Rectangle {
			x      = enemy.position.x,
			y      = enemy.position.y,
			width  = f32(frame_width),
			height = f32(frame_height),
		}

		switch enemy.direction {
		case .EAST:
			source.width = f32(frame_width)
		case .WEST:
			source.width = -f32(frame_width)
		case .NORTH, .SOUTH:
			source.width = f32(frame_width)
		}

		// Choose color based on flash timer
		color := rl.WHITE
		if enemy.flash_timer > 0 {
			color = rl.RED
		}

		rl.DrawTexturePro(enemy.sprite_sheet, source, dest, rl.Vector2{0, 0}, 0, color)
	}
}

check_if_enemy_hit :: proc(player: Player, enemies: ^[dynamic]Enemy, player_attack: rl.Rectangle) {
	for &enemy in enemies {

		hitbox := rl.Rectangle {
			enemy.position.x,
			enemy.position.y,
			f32(enemy.sprite_sheet.width / enemy.sprite_cols),
			f32(enemy.sprite_sheet.height / enemy.sprite_rows),
		}

		if rl.CheckCollisionRecs(hitbox, player_attack) {
			enemy.hp -= 1
			enemy.flash_timer = 0.2 // Start flash effect

			if enemy.hp <= 0 && !enemy.is_dying {
				enemy.is_dying = true
				enemy.state = .DEAD
				enemy.current_frame = 0
				enemy.frame_counter = 0
			}

		}

	}
}
