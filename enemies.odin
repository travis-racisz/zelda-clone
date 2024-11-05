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
	size:          rl.Vector2,
	current_frame: i32,
	frame_counter: i32,
	sprite_cols:   i32,
	sprite_rows:   i32,
}

ENEMY_SPEED :: f32(100) // Pixels per second

init_enemy :: proc(pos: rl.Vector2) -> Enemy {
	aggro := Aggro{pos, 50.0}
	enemy_sprite_sheet := rl.LoadTexture("./assets/Enemies/Skeleton.png")
	return Enemy {
		position      = pos,
		sprite_sheet  = enemy_sprite_sheet,
		aggro         = aggro,
		target        = pos,
		speed         = ENEMY_SPEED,
		current_frame = 0,
		sprite_cols   = 6,
		sprite_rows   = 10,
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

	return animations


}


update_enemies :: proc(
	enemies: [dynamic]Enemy,
	enemy: ^Player,
	animations: map[EnemyState]Animation,
) {
	// Fuck it new plan, walk the enemy left or right until it is on the same X axis as the enemy then walk them down or up until they are on the same Y axis 
	// if they are within a certain range they attack the direction towards the enemy 
	for &enemy in enemies {
		// check if enemy is inside of enemy aggro range 
		// if so walk at them 
		// when in range attack 

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
			width  = f32(frame_width),
		}

		dest := rl.Rectangle {
			x      = enemy.position.x,
			y      = enemy.position.y,
			width  = f32(frame_width),
			height = f32(frame_height),
		}

		// Adjust the source.width based on the enemy's direction
		rl.DrawTexturePro(enemy.sprite_sheet, source, dest, rl.Vector2{0, 0}, 0, rl.WHITE)
		rl.DrawCircle(
			i32(enemy.position.x + 15),
			i32(enemy.position.y + 15),
			enemy.aggro.radius,
			rl.ColorAlpha(rl.RED, 0.3),
		)

	}
}
