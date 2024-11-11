package main
import "core:mem"
Animation_State :: enum {
	IDLE,
	WALK_NORTH,
	WALK_SOUTH,
	WALK_EAST,
	WALK_WEST,
	ATTACK_NORTH,
	ATTACK_SOUTH,
	ATTACK_EAST,
	ATTACK_WEST,
	DEAD,
}


Direction :: enum {
	NORTH,
	SOUTH,
	EAST,
	WEST,
}

Animation :: struct {
	row:          i32,
	frames:       i32,
	frame_speed:  i32,
	blocks_input: bool, // Whether the animation should block other inputs 
}
