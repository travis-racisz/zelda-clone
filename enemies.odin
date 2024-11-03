package main
import "core:fmt"
import rl "vendor:raylib"

// can use the animation struct from the e 
Aggro_Range :: struct {
	radius:   f32,
	position: rl.Vector2,
}

Enemy :: struct {
	position:      rl.Vector2,
	sprite_sheet:  rl.Texture2D,
	direction:     Direction,
	hp:            i32,
	current_state: Animation_State,
	current_frame: i32,
	frame_counter: i32,
	sprite_cols:   i32,
	sprite_rows:   i32,
	aggro_range:   Aggro_Range,
}

init_enemies :: proc(enemy_spritesheet: rl.Texture2D) -> []Enemy {
	// Create a slice with make() instead of using slice literal syntax
	enemies := make([]Enemy, 2)

	enemies[0] = Enemy {
		position      = rl.Vector2{300, 300},
		sprite_sheet  = enemy_spritesheet,
		direction     = .SOUTH,
		current_state = .IDLE,
		current_frame = 0,
		frame_counter = 0,
		sprite_cols   = 6,
		sprite_rows   = 10,
		hp            = 1,
		aggro_range   = {50, enemies[0].position},
	}

	enemies[1] = Enemy {
		position      = rl.Vector2{400, 300},
		sprite_sheet  = enemy_spritesheet,
		direction     = .SOUTH,
		current_state = .IDLE,
		current_frame = 0,
		frame_counter = 0,
		sprite_cols   = 6,
		sprite_rows   = 10,
		hp            = 1,
		aggro_range   = {50, enemies[1].position},
	}

	return enemies
}

init_enemy_animations :: proc() -> map[Animation_State]Animation {
	animations := make(map[Animation_State]Animation)


	// configure each animation state 

	animations[.IDLE] = Animation {
		row          = 1,
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


update_enemies :: proc(enemies: []Enemy, animations: map[Animation_State]Animation) {
	// write path finding and agro functionality 
	for &enemy in enemies {

		current_anim := animations[enemy.current_state]

		// Update animation frame
		enemy.frame_counter += 1
		if enemy.frame_counter >= current_anim.frame_speed {
			enemy.frame_counter = 0
			enemy.current_frame = (enemy.current_frame + 1) % current_anim.frames
		}
	}
}

draw_enemies :: proc(enemies: ^[]Enemy, animations: map[Animation_State]Animation) {
	for e in enemies {

		current_anim := animations[e.current_state]

		frame_width := e.sprite_sheet.width / e.sprite_cols
		frame_height := e.sprite_sheet.height / e.sprite_rows

		source := rl.Rectangle {
			x      = f32(e.current_frame * frame_width),
			y      = f32(current_anim.row * frame_height),
			height = f32(frame_height),
		}


		dest := rl.Rectangle {
			x      = e.position.x,
			y      = e.position.y,
			width  = f32(frame_width) * 2,
			height = f32(frame_height) * 2,
		}

		switch e.direction {
		case .EAST:
			source.width = f32(frame_width)
		case .WEST:
			source.width = -f32(frame_width)
		case .NORTH, .SOUTH:
			source.width = f32(frame_width)
		}
		rl.DrawCircle(
			i32(e.aggro_range.position.x),
			i32(e.aggro_range.position.y),
			e.aggro_range.radius,
			rl.RED,
		)
		rl.DrawTexturePro(e.sprite_sheet, source, dest, rl.Vector2{0, 0}, 0.0, rl.WHITE)

	}

}
