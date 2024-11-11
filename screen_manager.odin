package main

import "core:fmt"
import rl "vendor:raylib"

Screen_Type :: enum {
	None,
	Title,
	Game,
	Pause,
	Game_Over,
}

Screen :: struct {
	init:   proc(),
	update: proc(dt: f32),
	draw:   proc(),
	unload: proc(),
}

Screen_Manager :: struct {
	current_screen:   Screen_Type,
	previous_screen:  Screen_Type,
	screens:          map[Screen_Type]Screen,
	transition_alpha: f32,
	transitioning:    bool,
}

screen_manager: Screen_Manager

init_screen_manager :: proc() {
	screen_manager = Screen_Manager {
		current_screen   = .Title,
		previous_screen  = .None,
		transitioning    = false,
		transition_alpha = 0,
	}

	// Initialize screen map
	screen_manager.screens = make(map[Screen_Type]Screen)

	// Register all screens
	screen_manager.screens[.Title] = Screen {
		init   = title_screen_init,
		update = title_screen_update,
		draw   = title_screen_draw,
		unload = title_screen_unload,
	}

	screen_manager.screens[.Game] = Screen {
		init   = game_screen_init,
		update = game_screen_update,
		draw   = game_screen_draw,
		unload = game_screen_unload,
	}

	screen_manager.screens[.Pause] = Screen {
		init   = pause_screen_init,
		update = pause_screen_update,
		draw   = pause_screen_draw,
		unload = pause_screen_unload,
	}

	screen_manager.screens[.Game_Over] = Screen {
		init   = game_over_screen_init,
		update = game_over_screen_update,
		draw   = game_over_screen_draw,
		unload = game_over_screen_unload,
	}

	// Initialize the first screen
	if screen, ok := screen_manager.screens[screen_manager.current_screen]; ok {
		screen.init()
	}
}

change_screen :: proc(new_screen: Screen_Type) {
	if new_screen != screen_manager.current_screen {
		old_screen := screen_manager.current_screen

		// Only unload if we're not just pausing/unpausing
		should_unload := !((old_screen == .Game && new_screen == .Pause) ||
			(old_screen == .Pause && new_screen == .Game))

		if should_unload {
			if screen, ok := screen_manager.screens[screen_manager.current_screen]; ok {
				screen.unload()
			}
		}

		screen_manager.previous_screen = screen_manager.current_screen
		screen_manager.current_screen = new_screen

		// Initialize new screen
		if screen, ok := screen_manager.screens[screen_manager.current_screen]; ok {
			screen.init()
		}
	}
}

update_screen_manager :: proc(dt: f32) {
	if screen, ok := screen_manager.screens[screen_manager.current_screen]; ok {
		screen.update(dt)
	}
}

draw_screen_manager :: proc() {

	if screen, ok := screen_manager.screens[screen_manager.current_screen]; ok {
		screen.draw()
	}

	// Draw transition effect if needed
	//	if screen_manager.transitioning {
	//		rl.DrawRectangle(
	//			0,
	//			0,
	//			rl.GetScreenWidth(),
	//			rl.GetScreenHeight(),
	//			rl.ColorAlpha(rl.BLACK, screen_manager.transition_alpha),
	//		)
	//	}
}

cleanup_screen_manager :: proc() {
	// Unload current screen
	if screen, ok := screen_manager.screens[screen_manager.current_screen]; ok {
		screen.unload()
	}
	delete(screen_manager.screens)
}

title_screen_init :: proc() {
	// Initialize title screen resources
}

title_screen_update :: proc(dt: f32) {
	// Handle title screen input and logic
	if rl.IsKeyPressed(.ENTER) {
		change_screen(.Game)
	}
}

title_screen_draw :: proc() {
	rl.DrawText(
		"ZELDA CLONE",
		i32(rl.GetScreenWidth() / 2 - 100),
		i32(rl.GetScreenHeight() / 2 - 30),
		30,
		rl.WHITE,
	)
	rl.DrawText(
		"Press ENTER to start",
		i32(rl.GetScreenWidth() / 2 - 110),
		i32(rl.GetScreenHeight() / 2 + 20),
		20,
		rl.WHITE,
	)
}

title_screen_unload :: proc() {
	// Unload title screen resources
}
