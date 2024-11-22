package main


import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

TitleScreenOption :: enum {
	NewGame,
	LoadGame,
	Quit,
}

TitleScreenState :: struct {
	selected_option:    TitleScreenOption,
	title_menu_options: [3]string,
	option_height:      f32,
}

title_screen_state: TitleScreenState

title_screen_init :: proc() {
	// Initialize title screen resources
	options := [3]string {
		strings.clone("New Game"),
		strings.clone("Load Game"),
		strings.clone("Quit"),
	}

	title_screen_state = TitleScreenState {
		selected_option    = .NewGame,
		title_menu_options = options,
		option_height      = 50.0,
	}
}

title_screen_update :: proc(dt: f32) {
	// Handle title screen input and logic
	if rl.IsKeyPressed(.DOWN) {
		if title_screen_state.selected_option == .NewGame {

			title_screen_state.selected_option = .LoadGame
		} else if title_screen_state.selected_option == .LoadGame {

			title_screen_state.selected_option = .Quit
		} else if title_screen_state.selected_option == .Quit {
			title_screen_state.selected_option = .NewGame
		}

	}

	if rl.IsKeyPressed(.UP) {
		if title_screen_state.selected_option == .NewGame {

			title_screen_state.selected_option = .Quit
		} else if title_screen_state.selected_option == .LoadGame {

			title_screen_state.selected_option = .NewGame
		} else if title_screen_state.selected_option == .Quit {
			title_screen_state.selected_option = .LoadGame
		}


	}
	if rl.IsKeyPressed(.ENTER) {
		switch title_screen_state.selected_option {
		case .NewGame:
			change_screen(.Game)
			break

		case .LoadGame:
			change_screen(.Game)
			break

		case .Quit:
			title_screen_unload()
			ExitGame = true
		}
	}
}

title_screen_draw :: proc() {
	for option, i in title_screen_state.title_menu_options {
		temp_str := strings.clone_to_cstring(option)
		pos_x := 800 + 20
		pos_y := 300 + 100 + f32(i) * title_screen_state.option_height


		if TitleScreenOption(i) == title_screen_state.selected_option {
			rl.DrawText(temp_str, i32(pos_x + 20), i32(pos_y), 30, rl.YELLOW)
		} else {
			rl.DrawText(temp_str, i32(pos_x + 20), i32(pos_y), 30, rl.WHITE)
		}

		defer delete(temp_str)
	}
	rl.DrawText(
		"ZELDA CLONE",
		i32(rl.GetScreenWidth() / 2 - 100),
		i32(rl.GetScreenHeight() / 2 - 300),
		30,
		rl.WHITE,
	)
}

title_screen_unload :: proc() {
	// Delete each string in the array
	for &option in title_screen_state.title_menu_options {
		if len(option) > 0 {
			delete(option)
			option = "" // Clear the string after deleting
		}
	}
	// Reset the state
	// title_screen_state = TitleScreenState{}
}
