// DEPRECATED NOT USING THIS ANYMORE
//
//
//
// DO NOT USE THIS 
//
//
//
//
//
package main
import "core:container/priority_queue"
import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Path_Node :: struct {
	position: Grid_Position,
	g_cost:   f32, // Cost from start
	h_cost:   f32, // Estimated cost to end
	f_cost:   f32, // Total cost (g_cost + h_cost)
	parent:   ^Path_Node,
}

Path_Grid :: struct {
	width, height: int,
	cell_size:     f32,
	nodes:         [][]bool, // true if walkable
	debug_path:    [dynamic]Grid_Position, // For visualization
	start, end:    Grid_Position,
}

Grid_Position :: struct {
	x, y: int,
}

Path_Context :: struct {
	nodes:      [dynamic]^Path_Node,
	open_set:   priority_queue.Priority_Queue(^Path_Node),
	closed_set: map[Grid_Position]bool,
}

show_pathfinding: bool

init_path_grid :: proc(width, height: int, cell_size: f32) -> Path_Grid {
	grid := Path_Grid {
		width     = width,
		height    = height,
		cell_size = cell_size,
		nodes     = make([][]bool, height),
	}

	for y in 0 ..< height {
		grid.nodes[y] = make([]bool, width)
		for x in 0 ..< width {
			grid.nodes[y][x] = true // Initially all cells are walkable
		}
	}

	grid.debug_path = make([dynamic]Grid_Position)
	return grid
}

cleanup_path_grid :: proc(grid: ^Path_Grid) {
	for row in grid.nodes {
		delete(row)
	}
	delete(grid.nodes)
	delete(grid.debug_path)
}

update_walkable_from_entities :: proc(grid: ^Path_Grid, entities: []Entity) {
	// Reset all cells to walkable
	for y in 0 ..< grid.height {
		for x in 0 ..< grid.width {
			grid.nodes[y][x] = true
		}
	}

	// Mark cells with entities as non-walkable
	for entity in entities {
		start_x := int(entity.position.x / grid.cell_size)
		start_y := int(entity.position.y / grid.cell_size)
		end_x := int((entity.position.x + entity.size.x) / grid.cell_size)
		end_y := int((entity.position.y + entity.size.y) / grid.cell_size)

		for y := start_y; y <= end_y; y += 1 {
			for x := start_x; x <= end_x; x += 1 {
				if x >= 0 && x < grid.width && y >= 0 && y < grid.height {
					grid.nodes[y][x] = false
				}
			}
		}
	}
}

calc_heuristic :: proc(a, b: Grid_Position) -> f32 {
	dx := abs(a.x - b.x)
	dy := abs(a.y - b.y)
	return f32(dx + dy) // Manhattan distance
}


init_path_context :: proc() -> Path_Context {
	path_ctx := Path_Context{}
	path_ctx.nodes = make([dynamic]^Path_Node)
	priority_queue.init(&path_ctx.open_set, less_than_path_node, swap_path_node)
	path_ctx.closed_set = make(map[Grid_Position]bool)
	return path_ctx
}

cleanup_path_ctx :: proc(path_ctx: ^Path_Context) {
	for node in path_ctx.nodes {
		free(node)
	}
	delete(path_ctx.nodes)
	priority_queue.destroy(&path_ctx.open_set)
	delete(path_ctx.closed_set)
}

find_path :: proc(grid: ^Path_Grid, start, end: Grid_Position) -> bool {
	//if !is_valid_position(grid, start) || !is_valid_position(grid, end) {
	//	fmt.println("not valid position")
	//return false
	//	}

	// Clear previous debug path
	clear(&grid.debug_path)
	grid.start = start
	grid.end = end

	// Initialize path context
	path_ctx := init_path_context()
	defer cleanup_path_ctx(&path_ctx)

	// Create start node
	start_node := new(Path_Node)
	start_node^ = Path_Node {
		position = start,
		g_cost   = 0,
		h_cost   = calc_heuristic(start, end),
		parent   = nil,
	}
	start_node.f_cost = start_node.g_cost + start_node.h_cost
	append(&path_ctx.nodes, start_node)
	priority_queue.push(&path_ctx.open_set, start_node)

	// Process nodes
	for priority_queue.len(path_ctx.open_set) > 0 {
		current := priority_queue.pop(&path_ctx.open_set)
		path_ctx.closed_set[current.position] = true

		if current.position == end {
			// Reconstruct and store path for visualization
			for node := current; node != nil; node = node.parent {
				append(&grid.debug_path, node.position)
			}
			return true
		}

		// Check neighbors
		directions := [][2]int{{0, 1}, {1, 0}, {0, -1}, {-1, 0}}
		for dir in directions {
			neighbor_pos := Grid_Position {
				x = current.position.x + dir[0],
				y = current.position.y + dir[1],
			}

			if !is_valid_position(grid, neighbor_pos) ||
			   !grid.nodes[neighbor_pos.y][neighbor_pos.x] ||
			   neighbor_pos in path_ctx.closed_set {
				continue
			}

			g_cost := current.g_cost + 1
			h_cost := calc_heuristic(neighbor_pos, end)
			f_cost := g_cost + h_cost

			neighbor := new(Path_Node)
			neighbor^ = Path_Node {
				position = neighbor_pos,
				g_cost   = g_cost,
				h_cost   = h_cost,
				f_cost   = f_cost,
				parent   = current,
			}
			append(&path_ctx.nodes, neighbor)
			priority_queue.push(&path_ctx.open_set, neighbor)
		}
	}

	return true
}

// Add these helper procedures
less_than_path_node :: proc(a, b: ^Path_Node) -> bool {
	return a.f_cost < b.f_cost
}

swap_path_node :: proc(slice: []^Path_Node, i, j: int) {
	slice[i], slice[j] = slice[j], slice[i]
}

is_valid_position :: proc(grid: ^Path_Grid, pos: Grid_Position) -> bool {
	return pos.x >= 0 && pos.x < grid.width && pos.y >= 0 && pos.y < grid.height
}

draw_path_debug :: proc(grid: ^Path_Grid) {
	// Draw walkable/non-walkable cells
	for y in 0 ..< grid.height {
		for x in 0 ..< grid.width {
			pos := rl.Vector2{f32(x) * grid.cell_size, f32(y) * grid.cell_size}

			if !grid.nodes[y][x] {
				rl.DrawRectangle(
					i32(pos.x),
					i32(pos.y),
					i32(grid.cell_size),
					i32(grid.cell_size),
					rl.ColorAlpha(rl.RED, 0.2),
				)
			}
		}
	}

	// Draw start and end positions
	start_pos := rl.Vector2{f32(grid.start.x) * grid.cell_size, f32(grid.start.y) * grid.cell_size}
	end_pos := rl.Vector2{f32(grid.end.x) * grid.cell_size, f32(grid.end.y) * grid.cell_size}
	rl.DrawRectangle(
		i32(start_pos.x),
		i32(start_pos.y),
		i32(grid.cell_size),
		i32(grid.cell_size),
		rl.ColorAlpha(rl.GREEN, 0.5),
	)
	rl.DrawRectangle(
		i32(end_pos.x),
		i32(end_pos.y),
		i32(grid.cell_size),
		i32(grid.cell_size),
		rl.ColorAlpha(rl.BLUE, 0.5),
	)


	// Draw path
	if len(grid.debug_path) > 0 {
		for i := 0; i < len(grid.debug_path) - 1; i += 1 {
			start := rl.Vector2 {
				f32(grid.debug_path[i].x) * grid.cell_size + grid.cell_size / 2,
				f32(grid.debug_path[i].y) * grid.cell_size + grid.cell_size / 2,
			}
			end := rl.Vector2 {
				f32(grid.debug_path[i + 1].x) * grid.cell_size + grid.cell_size / 2,
				f32(grid.debug_path[i + 1].y) * grid.cell_size + grid.cell_size / 2,
			}
			rl.DrawLineEx(start, end, 3, rl.ColorAlpha(rl.YELLOW, 0.8))
		}
	}
}
