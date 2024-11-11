package main
import "core:fmt"
import rl "vendor:raylib"


Player :: struct {
	position:           rl.Vector2,
	sprite_sheet:       rl.Texture2D,
	direction:          Direction,
	current_state:      Animation_State,
	current_frame:      i32,
	frame_counter:      i32,
	sprite_cols:        i32,
	sprite_rows:        i32,
	hp:                 int,
	hit_cooldown:       f32,
	can_be_hit:         bool,
	knockback_velocity: rl.Vector2,
	is_knocked_back:    bool,
}

PlayerAttack :: struct {
	position:  rl.Vector2,
	is_active: bool,
	damage:    int,
}


init_animations :: proc() -> map[Animation_State]Animation {
	animations := make(map[Animation_State]Animation)


	// configure each animation state 

	animations[.IDLE] = Animation {
		row          = 0,
		frames       = 6,
		frame_speed  = 8,
		blocks_input = false,
	}

	animations[.WALK_NORTH] = Animation {
		row          = 5,
		frames       = 6,
		frame_speed  = 8,
		blocks_input = false,
	}
	animations[.WALK_SOUTH] = Animation {
		row          = 3,
		frames       = 6,
		frame_speed  = 8,
		blocks_input = false,
	}

	animations[.WALK_EAST] = Animation {
		row          = 4,
		frames       = 6,
		frame_speed  = 8,
		blocks_input = false,
	}

	animations[.WALK_WEST] = Animation {
		row          = 4,
		frames       = 6,
		frame_speed  = 8,
		blocks_input = false,
	}

	animations[.ATTACK_NORTH] = Animation {
		row          = 8,
		frames       = 4,
		frame_speed  = 4,
		blocks_input = true,
	}
	animations[.ATTACK_SOUTH] = Animation {
		row          = 6,
		frames       = 4,
		frame_speed  = 4,
		blocks_input = true,
	}
	animations[.ATTACK_EAST] = Animation {
		row          = 7,
		frames       = 4,
		frame_speed  = 4,
		blocks_input = true,
	}
	animations[.ATTACK_WEST] = Animation {
		row          = 7,
		frames       = 4,
		frame_speed  = 4,
		blocks_input = true,
	}

	animations[.DEAD] = Animation {
		row          = 9,
		frames       = 4,
		frame_speed  = 8,
		blocks_input = true,
	}

	return animations


}


init_player :: proc(sprite: rl.Texture2D) -> Player {

	player := Player {
		position        = {800, 800},
		sprite_sheet    = sprite,
		direction       = .SOUTH,
		current_state   = .IDLE,
		current_frame   = 0,
		frame_counter   = 0,
		sprite_cols     = 6,
		sprite_rows     = 10,
		hp              = 100,
		hit_cooldown    = 0,
		can_be_hit      = true,
		is_knocked_back = false,
	}

	return player
}


update_player :: proc(player: ^Player, animations: map[Animation_State]Animation) {

	check_if_hit(player, enemies)
	current_anim := animations[player.current_state]
	update_hit_cooldown(player)
	if player.hp <= 0 && player.current_state != .DEAD {
		player.current_state = .DEAD
		player.current_frame = 0
		player.frame_counter = 0
		return // Skip rest of update if just died
	}

	// If already dead, only update the death animation once
	if player.current_state == .DEAD {
		current_anim := animations[.DEAD]
		player.frame_counter += 1
		if player.frame_counter >= current_anim.frame_speed {
			player.frame_counter = 0
			// Only advance frame if we haven't reached the end
			if player.current_frame < current_anim.frames - 1 {
				player.current_frame += 1
			}
		}
		return // Skip rest of update if dead
	}


	if player.is_knocked_back {
		// Apply knockback velocity
		player.position = player.position + player.knockback_velocity

		// Reduce knockback velocity over time (friction)
		player.knockback_velocity = player.knockback_velocity * 0.9

		// Stop knockback when velocity is very small
		if rl.Vector2Length(player.knockback_velocity) < 0.1 {
			player.is_knocked_back = false
			player.knockback_velocity = rl.Vector2{0, 0}
		}

		// Skip normal movement input while being knocked back
		if player.is_knocked_back do return
	}
	player.frame_counter += 1
	if player.frame_counter >= current_anim.frame_speed {


		player.frame_counter = 0
		player.current_frame = (player.current_frame + 1) % current_anim.frames

		// If this animation blocks input and has completed, return to idle
		if current_anim.blocks_input && player.current_frame == 0 {
			player.current_state = .IDLE
		}
	}

	// Only process input if current animation allows it
	if !current_anim.blocks_input {
		// Handle movement
		if rl.IsKeyDown(.W) {
			player.position.y -= 2
			player.current_state = .WALK_NORTH
			player.direction = .NORTH
		} else if rl.IsKeyDown(.S) {
			player.position.y += 2
			player.current_state = .WALK_SOUTH
			player.direction = .SOUTH
		} else if rl.IsKeyDown(.D) {
			player.position.x += 2
			player.current_state = .WALK_EAST
			player.direction = .EAST
		} else if rl.IsKeyDown(.A) {
			player.position.x -= 2
			player.current_state = .WALK_WEST
			player.direction = .WEST
		} else if player.current_state != .IDLE {
			// Return to idle if no movement keys are pressed
			player.current_state = .IDLE
			player.current_frame = 0
		}

		// Handle attack input
		if rl.IsKeyPressed(.SPACE) {
			// Set attack animation based on current direction
			switch player.direction {
			case .NORTH:
				player_attack := PlayerAttack {
					{player.position.x, player.position.y - 10},
					false,
					10,
				}
				player_attack_rect := rl.Rectangle {
					player_attack.position.x,
					player_attack.position.y,
					40,
					40,
				}
				check_if_enemy_hit(player^, &enemies, player_attack_rect)
				player.current_state = .ATTACK_NORTH
			case .SOUTH:
				player_attack := PlayerAttack {
					{player.position.x, player.position.y + 10},
					false,
					10,
				}
				player_attack_rect := rl.Rectangle {
					player_attack.position.x,
					player_attack.position.y,
					40,
					40,
				}
				check_if_enemy_hit(player^, &enemies, player_attack_rect)
				player.current_state = .ATTACK_SOUTH
			case .EAST:
				player_attack := PlayerAttack {
					{player.position.x + 10, player.position.y},
					false,
					10,
				}
				player_attack_rect := rl.Rectangle {
					player_attack.position.x,
					player_attack.position.y,
					40,
					40,
				}
				check_if_enemy_hit(player^, &enemies, player_attack_rect)
				player.current_state = .ATTACK_EAST
			case .WEST:
				player_attack := PlayerAttack {
					{player.position.x - 10, player.position.y},
					false,
					10,
				}
				player_attack_rect := rl.Rectangle {
					player_attack.position.x,
					player_attack.position.y,
					40,
					40,
				}
				check_if_enemy_hit(player^, &enemies, player_attack_rect)
				player.current_state = .ATTACK_WEST
			}
			player.current_frame = 0
			player.frame_counter = 0
		}
	}

}

draw_player :: proc(player: Player, animations: map[Animation_State]Animation) {
	current_anim := animations[player.current_state]

	frame_width := player.sprite_sheet.width / player.sprite_cols
	frame_height := player.sprite_sheet.height / player.sprite_rows

	source := rl.Rectangle {
		x      = f32(player.current_frame * frame_width),
		y      = f32(current_anim.row * frame_height),
		height = f32(frame_height),
	}

	dest := rl.Rectangle {
		x      = player.position.x,
		y      = player.position.y,
		width  = f32(frame_width),
		height = f32(frame_height),
	}

	// Adjust the source.width based on the player's direction
	switch player.direction {
	case .EAST:
		source.width = f32(frame_width)
	case .WEST:
		source.width = -f32(frame_width)
	case .NORTH, .SOUTH:
		source.width = f32(frame_width)
	}
	color := player.can_be_hit ? rl.WHITE : rl.ColorAlpha(rl.RED, 0.7)
	rl.DrawTexturePro(player.sprite_sheet, source, dest, rl.Vector2{0, 0}, 0, color)
}


check_if_hit :: proc(player: ^Player, enemies: [dynamic]Enemy) {
	if !player.can_be_hit do return

	hitbox := rl.Rectangle {
		player.position.x,
		player.position.y,
		f32(player.sprite_sheet.width / player.sprite_cols),
		f32(player.sprite_sheet.height / player.sprite_rows),
	}


	KNOCKBACK_FORCE :: f32(6.0)

	for enemy in enemies {
		if rl.CheckCollisionPointRec(enemy.position, hitbox) {
			player.hp -= 1
			player.can_be_hit = false
			player.hit_cooldown = 1.0
			player.is_knocked_back = true

			if enemy.direction == .NORTH {
				direction := rl.Vector2{0, -10}

				direction = rl.Vector2Normalize(direction)
				player.knockback_velocity = direction * KNOCKBACK_FORCE
				return
			}

			if enemy.direction == .SOUTH {

				direction := rl.Vector2{0, 10}
				direction = rl.Vector2Normalize(direction)
				player.knockback_velocity = direction * KNOCKBACK_FORCE
				return
			}

			if enemy.direction == .EAST {
				direction := rl.Vector2{10, 0}

				direction = rl.Vector2Normalize(direction)
				player.knockback_velocity = direction * KNOCKBACK_FORCE
				return
			}

			if enemy.direction == .WEST {
				direction := rl.Vector2{-10, 0}

				direction = rl.Vector2Normalize(direction)
				player.knockback_velocity = direction * KNOCKBACK_FORCE
				return
			}
			// Calculate direction from enemy to player

		}
	}
}


update_hit_cooldown :: proc(player: ^Player) {
	if !player.can_be_hit {
		player.hit_cooldown -= rl.GetFrameTime()
		if player.hit_cooldown <= 0 {
			player.can_be_hit = true
			player.hit_cooldown = 0
		}
	}
}
