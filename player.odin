package main
import "core:fmt"
import rl "vendor:raylib"


Player :: struct {
	position:      rl.Vector2,
	sprite_sheet:  rl.Texture2D,
	direction:     Direction,
	current_state: Animation_State,
	current_frame: i32,
	frame_counter: i32,
	sprite_cols:   i32,
	sprite_rows:   i32,
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

	return animations


}


init_player :: proc(sprite_sheet: rl.Texture2D) -> Player {
	return Player {
		position = rl.Vector2{100, 100},
		sprite_sheet = sprite_sheet,
		current_state = .IDLE,
		direction = .SOUTH,
		current_frame = 0,
		frame_counter = 0,
		sprite_cols = 6,
		sprite_rows = 10,
	}
}


update_player :: proc(player: ^Player, animations: map[Animation_State]Animation) {
	current_anim := animations[player.current_state]

	// Update animation frame
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
				player.current_state = .ATTACK_NORTH
			case .SOUTH:
				player.current_state = .ATTACK_SOUTH
			case .EAST:
				player.current_state = .ATTACK_EAST
			case .WEST:
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
		width  = f32(frame_width) * 2,
		height = f32(frame_height) * 2,
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
	rl.DrawTexturePro(player.sprite_sheet, source, dest, rl.Vector2{0, 0}, 0, rl.WHITE)
}
