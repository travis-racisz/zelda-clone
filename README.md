# Zelda Clone Game
[Zelda Clone Gameplay](https://github.com/user-attachments/assets/ec753852-f4d9-4c41-90d7-4f20d97c6c26)

A Zelda-inspired action-adventure game built with the Odin programming language and Raylib. This project was created as part of a game jam to explore game development with Odin.

## Features

- Top-down action-adventure gameplay
- State-based screen management (Title, Game, Pause, Game Over)
- Save/Load game functionality
- Built-in level editor
- Player animation system
- Enemy AI and pathfinding
- Collision detection system

## Technical Stack

- **Language**: [Odin](https://odin-lang.org/)
- **Graphics**: [Raylib](https://www.raylib.com/)
- **Save Format**: JSON

## Building and Running

### Prerequisites

1. Install the Odin compiler
2. Ensure you have the required assets in the `assets` directory

### Building

```bash
odin build . -file=main.odin
```

### Running

```bash
./zelda_clone
```

## Game Controls

- **WASD**: Move player/Navigate menus
- **Enter**: Select menu option
- **Escape**: Pause game
- **F2**: Toggle level editor
- **F3**: Toggle camera zoom (1.0x/4.0x) while in edit mode

## Level Editor

The game includes a built-in level editor accessible by pressing F2. Editor features include:

- Grid-based placement system
- Entity placement with left-click
- Entity deletion with right-click
- Adjustable placement size with mouse wheel
- Auto-save functionality
- Level loading from JSON
- scroll wheel will increase or decrease entity size

## Project Structure

- `main.odin`: Entry point and game loop
- `game_screen.odin`: Main game state and update logic
- `level_editor.odin`: Level editor implementation
- `screen_manager.odin`: Screen state management
- `title_screen.odin`: Title screen implementation

## Save System

The game implements a save system that stores:
- Player position and health
- Current level
- Enemy positions
- Level layout

Save files are stored in JSON format as `save_game.json`.

## Asset Requirements

Place the following assets in the `assets` directory:
- `Player/Player.png`: Player sprite sheet
- `level_1.png`: Background for the first level

## Development

### Adding New Features

1. Enemy types can be extended in the enemy animation system
2. New levels can be added to the `Levels` enum in `game_screen.odin`
3. Additional screen types can be added to `Screen_Type` enum in `screen_manager.odin`

### Debug Mode

When compiled in debug mode (`ODIN_DEBUG`), the game includes memory tracking to help identify memory leaks and incorrect frees.

## Known Issues

- Its not done, I ran out of time. some of the colisions are a bit buggy as well
- game ui loads in top right corner, would be an easy fix to just make it relative to the screen
- its not really a real game 

## Things I wanted to add but ran out of time 
- level loading, so the player could exit the first map and go to a second one
- new mechanic, like a grappling hook
- NPC's to talk to
- a boss to fight
- 


## Acknowledgments

- Raylib community
- Odin programming language team
