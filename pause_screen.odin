package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

Pause_Menu_Option :: enum {
	Resume,
	Restart,
	Quit,
}

Pause_State :: struct {
	selected_option:  Pause_Menu_Option,
	menu_options:     [3]string,
	menu_rect:        rl.Rectangle,
	option_height:    f32,
	background_alpha: f32,
	initialized:      bool,
}

pause_state: Pause_State

pause_screen_init :: proc() {

	// Create menu options with proper allocation
	options := [3]string{strings.clone("Resume"), strings.clone("Restart"), strings.clone("Quit")}

	pause_state = Pause_State {
		selected_option = .Resume,
		menu_options = options,
		menu_rect = rl.Rectangle {
			x = f32(rl.GetScreenWidth()) / 2 - 150,
			y = f32(rl.GetScreenHeight()) / 2 - 150,
			width = 300,
			height = 300,
		},
		option_height = 60,
		background_alpha = 0.7,
		initialized = true,
	}

}

pause_screen_update :: proc(dt: f32) {
	// Handle menu navigation
	if rl.IsKeyPressed(.UP) {
		if pause_state.selected_option == .Resume {
			pause_state.selected_option = .Quit
		} else if pause_state.selected_option == .Restart {
			pause_state.selected_option = .Resume
		} else if pause_state.selected_option == .Quit {
			pause_state.selected_option = .Restart
		}
	}

	if rl.IsKeyPressed(.DOWN) {
		if pause_state.selected_option == .Resume {
			pause_state.selected_option = .Restart
		} else if pause_state.selected_option == .Restart {
			pause_state.selected_option = .Quit
		} else if pause_state.selected_option == .Quit {
			pause_state.selected_option = .Resume
		}
	}

	// Handle menu selection
	if rl.IsKeyPressed(.ENTER) {
		switch pause_state.selected_option {
		case .Resume:
			change_screen(.Game)
		case .Restart:
			change_screen(.Title)
		case .Quit:
			rl.CloseWindow()
		}
	}

	// Alternative: Resume game when pressing Escape again
	if rl.IsKeyPressed(.ESCAPE) {
		change_screen(.Game)
	}
}

pause_screen_draw :: proc() {
	// Draw darkened overlay
	rl.DrawRectangle(
		0,
		0,
		rl.GetScreenWidth(),
		rl.GetScreenHeight(),
		rl.ColorAlpha(rl.BLACK, pause_state.background_alpha),
	)

	// Draw pause menu background
	rl.DrawRectangleRec(pause_state.menu_rect, rl.ColorAlpha(rl.DARKGRAY, 0.8))

	// Draw menu title
	title_pos_x := i32(pause_state.menu_rect.x + pause_state.menu_rect.width / 2 - 80)
	title_pos_y := i32(pause_state.menu_rect.y + 20)
	rl.DrawText("PAUSED", title_pos_x, title_pos_y, 40, rl.WHITE)

	// Draw menu options
	for option, i in pause_state.menu_options {
		pos_x := pause_state.menu_rect.x + 20
		pos_y := pause_state.menu_rect.y + 100 + f32(i) * pause_state.option_height

		// Draw selection indicator
		if Pause_Menu_Option(i) == pause_state.selected_option {
			rl.DrawRectangle(
				i32(pos_x - 10),
				i32(pos_y - 5),
				i32(pause_state.menu_rect.width - 20),
				40,
				rl.ColorAlpha(rl.WHITE, 0.2),
			)
			rl.DrawText(
				strings.clone_to_cstring(option),
				i32(pos_x + 20),
				i32(pos_y),
				30,
				rl.YELLOW,
			)
		} else {
			rl.DrawText(
				strings.clone_to_cstring(option),
				i32(pos_x + 20),
				i32(pos_y),
				30,
				rl.WHITE,
			)
		}
	}

	// Draw controls hint
	hint_text := "Use UP/DOWN arrows to navigate, ENTER to select"
	hint_pos_x := i32(pause_state.menu_rect.x + 20)
	hint_pos_y := i32(pause_state.menu_rect.y + pause_state.menu_rect.height - 30)
	rl.DrawText(strings.clone_to_cstring(hint_text), hint_pos_x, hint_pos_y, 15, rl.LIGHTGRAY)
}

pause_screen_unload :: proc() {
	// No resources to unload
}
