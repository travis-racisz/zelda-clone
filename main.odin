package main

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"


// -----------------------------------------
// TODO: get editor working correctly again 
// add in new type of collision rect that will change the level by loading a load screen, unloading all of the assets and loading in the new assets 
// set up collision rects for level 2 
// add in a new mechanic, grappling hook
// add boss 
// add in win screen 
// redo game over screen 
// GAME IS DONE 
// -----------------------------------------

main :: proc() {

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	rl.InitWindow(1920, 1080, "ZeldaClone")
	rl.SetTargetFPS(60)
	init_editor()
	init_screen_manager()
	defer cleanup_screen_manager()
	defer save_game()
	defer rl.CloseWindow()

	// defer write_level()

	for !ExitGame {
		dt := rl.GetFrameTime()

		rl.BeginDrawing()

		{
			update_screen_manager(dt)
			draw_screen_manager()
		}
		rl.EndDrawing()
	}
}


save_game :: proc() {
	// get all of the date required, such as all of the enemies, their positions, the player as well as the current level
	// save to JSON file 
	create_save_file()

}
