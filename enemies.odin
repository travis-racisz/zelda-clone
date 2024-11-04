package main
import "core:fmt"
import "core:math/rand"
import "core:slice"
import rl "vendor:raylib"

// can use the animation struct from the e 
Aggro_Range :: struct {
	radius:   f32,
	position: rl.Vector2,
}

Node :: struct {
	position: rl.Vector2,
	parent:   ^Node,
	h_const:  f32,
	g_const:  f32,
	f_const:  f32,
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
			i32(i32(e.position.x) + i32(frame_height)),
			i32(i32(e.position.y) + i32(frame_width)),
			e.aggro_range.radius,
			rl.ColorAlpha(rl.RED, 0.3),
		)
		rl.DrawTexturePro(e.sprite_sheet, source, dest, rl.Vector2{0, 0}, 0.0, rl.WHITE)

	}

}


state_machine :: proc(enemies: [dynamic]^Enemy) {
	// if idle, wander around from original position to random position within a range 
	for e in enemies {

		starting_pos := e.position
		wander_range := rl.Vector2 {
			e.position.x + (rand.float32() * 100.0),
			e.position.y + (rand.float32() * 100.0),
		}

	}

}


// ----------------------------------------------------
// Path Finding 
// ----------------------------------------------------


// compares nodes and returns true if second nodes f value is greater than a 
// we want to follow the lowest f value 
compare_nodes :: proc(a, b: ^Node) -> bool {
	return a.f_const < b.f_const
}


find_path :: proc(start: rl.Vector2, end: rl.Vector2, level_data: Level) -> [dynamic]rl.Vector2 {

	// allocate memory for the the open_set of nodes 
	open_set := make([dynamic]^Node, 0, context.allocator)
	// a list of already explored locations, to avoid revisiting the same locations 
	closed_set := make(map[rl.Vector2]^Node, 0, context.allocator)


	//create the start node 
	start_node := &Node {
		position = start,
		g_const = 0,
		h_const = rl.Vector2Distance(start, end),
		f_const = rl.Vector2Distance(start, end),
	}


	append(&open_set, start_node)

	// make the start node as already visited 
	closed_set[start] = start_node


	for len(open_set) > 0 {
		// get the node with the lowest f score 
		current_node := pop(&open_set)


		// check if we are at the end location 
		if rl.Vector2Distance(current_node.position, end) < 0.1 {
			path := make([dynamic]rl.Vector2)
			node := current_node
			for node != nil {
				append(&path, node.position)
				node = node.parent
			}

			slice.reverse(path[:])
			return path


		}


		closed_set[current_node.position] = current_node


		// explore neighbors 
		for neighbor in get_neighbors(current_node.position, level_data) {
			if _, ok := closed_set[neighbor]; ok {
				continue // skip nodes in the closed_set

			}

		}

	}

}


get_neighbors :: proc(pos: rl.Vector2, level_data: ^Level) -> [dynamic]rl.Vector2 {
	neighbors := make([dynamic]rl.Vector2)
	for x := int(pos.x - 1); x <= int(pos.x + 1); x += 1 {
		for y := int(pos.y - 1); y <= int(pos.y + 1); y += 1 {
			if (x != int(pos.x) || y != int(pos.y) {
				if !is_blocked(rl.Vector2 {f32(x), f32(y)}, level_data) do 
					append(&neighbors.rl.Vector2{f32(x), f32(y)})
				
			}
		}
	}
}


is_blocked :: proc(pos: rl.Vector2, level_data: ^Level) -> bool {
	// Check if the position is blocked by any level geometry
	for entity in level_data.entities {
		if rl.CheckCollisionPointRec(
			pos,
			rl.Rectangle {
				x = entity.position.x,
				y = entity.position.y,
				width = entity.size.x,
				height = entity.size.y,
			},
		) {
			return true
		}
	}
	return false

}
