package main

import "core:strings"
import rl "vendor:raylib"

GameOverOptions :: enum {
	RESTART,
	QUIT,
}


GameOverState :: struct {
	selected_option:  GameOverOptions,
	menu_options:     []string,
	menu_rect:        rl.Rectangle,
	option_height:    f32,
	background_alpha: f32,
}

game_over_state: GameOverState


game_over_screen_init :: proc() {
	game_over_state = GameOverState {
		selected_option = .RESTART,
		menu_options = []string{"Restart", "Main Menu"},
		menu_rect = rl.Rectangle {
			x = f32(rl.GetScreenWidth() / 2 - 150),
			y = f32(rl.GetScreenHeight() / 2 - 150),
			width = 300,
			height = 300,
		},
		option_height = 60,
		background_alpha = 0.7,
	}

}


game_over_screen_update :: proc(dt: f32) {

	if rl.IsKeyPressed(.UP) {
		if game_over_state.selected_option == .RESTART {
			game_over_state.selected_option = .QUIT
		} else if game_over_state.selected_option == .QUIT {
			game_over_state.selected_option = .RESTART
		}
	}

	if rl.IsKeyPressed(.DOWN) {
		if game_over_state.selected_option == .RESTART {
			game_over_state.selected_option = .QUIT
		} else if game_over_state.selected_option == .QUIT {
			game_over_state.selected_option = .RESTART
		}
	}

	// Handle menu selection
	if rl.IsKeyPressed(.ENTER) {
		switch game_over_state.selected_option {
		case .RESTART:
			// First change to title screen, which will then start a new game
			change_screen(.Title)
		case .QUIT:
			rl.CloseWindow()
		}
	}

	// Alternative: Resume game when pressing Escape again
	if rl.IsKeyPressed(.ESCAPE) {
		change_screen(.Game)
	}

}
game_over_screen_draw :: proc() {

	// Draw the game screen in the background (slightly darkened)
	if screen, ok := screen_manager.screens[.Game]; ok {
		screen.draw()
	}

	// Draw semi-transparent background
	rl.DrawRectangle(
		0,
		0,
		rl.GetScreenWidth(),
		rl.GetScreenHeight(),
		rl.ColorAlpha(rl.BLACK, game_over_state.background_alpha),
	)

	// Draw pause menu background
	rl.DrawRectangleRec(game_over_state.menu_rect, rl.ColorAlpha(rl.DARKGRAY, 0.8))

	// Draw menu title
	title_pos_x := i32(game_over_state.menu_rect.x + game_over_state.menu_rect.width / 2 - 80)
	title_pos_y := i32(game_over_state.menu_rect.y + 20)
	rl.DrawText("PAUSED", title_pos_x, title_pos_y, 40, rl.WHITE)

	// Draw menu options
	for option, i in game_over_state.menu_options {
		pos_x := game_over_state.menu_rect.x + 20
		pos_y := game_over_state.menu_rect.y + 100 + f32(i) * game_over_state.option_height

		// Draw selection indicator
		if GameOverOptions(i) == game_over_state.selected_option {
			rl.DrawRectangle(
				i32(pos_x - 10),
				i32(pos_y - 5),
				i32(game_over_state.menu_rect.width - 20),
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
	hint_pos_x := i32(game_over_state.menu_rect.x + 20)
	hint_pos_y := i32(game_over_state.menu_rect.y + game_over_state.menu_rect.height - 30)
	rl.DrawText(strings.clone_to_cstring(hint_text), hint_pos_x, hint_pos_y, 15, rl.LIGHTGRAY)
}
game_over_screen_unload :: proc() {


}
