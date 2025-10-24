# Nim 3D Terminal Tic-Tac-Toe Game

A colorful terminal-based 3D tic-tac-toe game written in Nim for Linux (and
similar terminals), featuring Player vs computer gameplay with 3D navigation
controls.

This was 95% written by AI, based on the vague memory of some computer game I
played as a child (on a friend's Atari, I think), as I wanted to play around
with Cursor, Cline, and OpenRouter.

## Features

- **3D 4x4x4 Board**: Full 3D tic-tac-toe with 64 cells (4 layers of 4x4)
- **Player vs AI**: Human plays as X, AI plays as O
- **3D Navigation**: Arrow keys for X,Y movement, SPACE key to change layers
- **3D Visual Display**: Shows all 4 layers side-by-side with vertical offset for 3D effect
- **ANSI Colors**: Colorful display with different colors for X, O, and UI elements
- **Win Highlighting**: Winning pieces are highlighted with background colors when a win occurs
- **Score Tracking**: Keeps track of wins, losses, and draws across multiple games
- **Continuous Play**: Automatically starts new games until you quit
- **Smart AI**: Always blocks wins, but makes random moves 15% of the time otherwise

## Requirements

- Linux system
- Nim compiler (tested with Nim 1.6+)
- Terminal with ANSI color support

## Installation

1. Make sure you have Nim installed:
   ```bash
   # On Arch Linux
   sudo pacman -S nim
   
   # On Ubuntu/Debian
   sudo apt install nim
   
   # Or install from official website: https://nim-lang.org/install.html
   ```

2. Clone or download this repository

## Compilation and Running

Compile to an executable & run it:
```bash
nim c tictactoe.nim
./tictactoe
```

## How to Play

1. **3D Movement**: Use arrow keys (↑↓←→) to move the cursor within the current layer
2. **Layer Navigation**: Press SPACE to cycle through the 4 layers (Z-axis)
3. **Place Piece**: Press Enter to place your X at the current 3D position
4. **AI Turn**: The AI will automatically make its move after you place yours
5. **New Game**: After each game ends, press any key to start a new round
6. **Quit**: Press 'q' or Escape to quit the game

## Game Controls

- **Arrow Keys**: Move cursor within current layer (X,Y movement)
- **SPACE**: Change layer (Z-axis movement)
- **Enter**: Place your piece (X) at current 3D position
- **q or Escape**: Quit the game
- **Any other key**: Continue after game ends

## Scoring

The game tracks:
- **Human wins** (you win)
- **AI wins** (AI wins) 
- **Draws** (tie games)
- **Total games played**

## Technical Details

- **3D Board**: 4x4x4 cube with 64 cells using 3D coordinate system
- **Comprehensive Win Detection**: Unified function checks all possible 4-in-a-row lines and stores winning positions for highlighting
- **3D Visual Display**: Shows all 4 layers side-by-side with vertical offset for 3D effect
- **3D Navigation**: SPACE key for layer switching, arrow keys for X,Y movement
- **Strategic AI**: Always blocks wins but makes random moves 30% of the time
- **Raw Terminal Mode**: Immediate key input with POSIX termios
- **ANSI Colors**: Full color support for enhanced visual experience

## Troubleshooting

If you encounter issues:

1. **Colors not showing**: Make sure your terminal supports ANSI colors
2. **Arrow keys not working**: Try running in a different terminal emulator
3. **Compilation errors**: Ensure you have a recent version of Nim installed

# Personal Notes on AI Development

I never would have written a Tic-Tac-Toe game myself, because I generally lack
the time and inspiration for such things.  I started with a normal 3x3
tic-tac-toe, then asked it to expand it to a 3rd dimension and to become 4x4x4,
with cross-layer win lines.

I asked the AI to introduce axis rotation, and then had to clean up a bit after
it.  I altered the rotation logic myself, and it may be technically wrong.  At
face value, it looks OK to me.

It did a pretty good job of the TUI using ANSI codes and the termios module,
but once again this needed some cleanup work, fixing of alignment issues, etc.

3D tic-tac-toe has been around since the 60s, with various computer
implementations, so there's nothing novel in this.  The computer player logic
seems decent, while giving the player a chance.

Since I never would have otherwise written this, it made me infinitely more
productive for this particular project.  Had I done it from scratch, I would
have structured the code a bit differently, written some tests, and probably
hard-coded the win-lines.  If I get bored, I may turn it into a JS app (which
the nim compiler can target).  For now, it served its purpose as a learning
tool.

I used Cursor's included credits for the 2d version, then switched to Cline and
OpenRouter for the 3d version.  It cost about $1.00 worth of OpenRouter
credits, including some futzing around and playing with different models.  I
spent about 10 hours on this, including installing and configuring tools,
play-testing, updating this README, etc.  I might even play it now and again.

## License

The code is open source and available under the MIT License (or copyright free,
where applicable).

This README's personal notes section are my own, and may not be reproduced
outside of this code repository and any forks, but then with attribution.
