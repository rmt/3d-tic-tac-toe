#
# A terminal-based tic-tac-toe game with a 4x4x4 grid.
#

import os, posix, termios, random

# ANSI Color Codes
const
  RESET = "\e[0m"
  BOLD = "\e[1m"
  RED = "\e[31m"
  GREEN = "\e[32m"
  YELLOW = "\e[33m"
  BLUE = "\e[34m"
  CYAN = "\e[36m"
  WHITE = "\e[37m"
  BG_GREEN = "\e[42m"
  BG_RED = "\e[41m"
  BG_BLUE = "\e[44m"
  CLEAR_SCREEN = "\e[2J\e[H"
  HIDE_CURSOR = "\e[?25l"
  SHOW_CURSOR = "\e[?25h"

# Game state types
type
  Player = enum
    Empty = 0, X = 1, O = 2
  
  GameState = enum
    Playing, XWins, OWins, Draw
  
  Game = object
    board: array[64, Player]  # 4x4x4 = 64 cells
    currentPlayer: Player
    cursorX: int  # 0-3
    cursorY: int  # 0-3  
    cursorZ: int  # 0-3 (current layer)
    gameState: GameState
    humanScore: int
    aiScore: int
    draws: int
    totalGames: int
    winningPositions: seq[int]  # Store winning positions for highlighting

  Axis = enum X, Y, Z

# Initialize game
proc initGame(): Game =
  # Initialize 64 empty cells (4x4x4)
  for i in 0..63:
    result.board[i] = Player.Empty
  result.currentPlayer = Player.X
  result.cursorX = 0
  result.cursorY = 0
  result.cursorZ = 0
  result.gameState = GameState.Playing
  result.humanScore = 0
  result.aiScore = 0
  result.draws = 0
  result.totalGames = 0
  result.winningPositions = @[]

# Reset game state (preserves scores)
proc resetGame(game: var Game) =
  # Reset 64 empty cells (4x4x4)
  for i in 0..63:
    game.board[i] = Player.Empty
  game.currentPlayer = Player.X
  game.cursorX = 0
  game.cursorY = 0
  game.cursorZ = 0
  game.gameState = GameState.Playing
  game.winningPositions = @[]

# Clear screen and hide cursor
proc clearScreen() =
  stdout.write(CLEAR_SCREEN)
  stdout.flushFile()

# Show cursor
proc showCursor() =
  stdout.write(SHOW_CURSOR)
  stdout.flushFile()

# Hide cursor
proc hideCursor() =
  stdout.write(HIDE_CURSOR)
  stdout.flushFile()

# Convert 3D coordinates to linear index
proc get3DIndex(x, y, z: int): int =
  return z * 16 + y * 4 + x

# Convert linear index to 3D coordinates
proc get3DCoords(index: int): (int, int, int) =
  let z = index div 16
  let y = (index mod 16) div 4
  let x = index mod 4
  return (x, y, z)

# Get player symbol with color
proc getPlayerSymbol(player: Player): string =
  case player:
  of Player.X: return RED & "X" & RESET
  of Player.O: return BLUE & "O" & RESET
  of Player.Empty: return " "

# Get player symbol with win highlighting
proc getPlayerSymbolWithWin(player: Player, isWinning: bool): string =
  if isWinning:
    case player:
    of Player.X: return BG_RED & WHITE & "X" & RESET
    of Player.O: return BG_BLUE & WHITE & "O" & RESET
    of Player.Empty: return " "
  else:
    return getPlayerSymbol(player)

# Optimized winning lines generation - all 76 possible 4-in-a-row combinations in 4x4x4 space
# Each line is represented as an array of 4 board positions (0-63)

# Helper function to generate lines along a specific axis
proc generateAxisLines(fixedAxis1, fixedAxis2: int, varyingAxis: int): array[4, int] =
  # Generate a line where one axis varies from 0-3 while the other two are fixed
  case varyingAxis:
  of 0:  # X varies
    return [
      get3DIndex(0, fixedAxis1, fixedAxis2),
      get3DIndex(1, fixedAxis1, fixedAxis2),
      get3DIndex(2, fixedAxis1, fixedAxis2),
      get3DIndex(3, fixedAxis1, fixedAxis2)
    ]
  of 1:  # Y varies
    return [
      get3DIndex(fixedAxis1, 0, fixedAxis2),
      get3DIndex(fixedAxis1, 1, fixedAxis2),
      get3DIndex(fixedAxis1, 2, fixedAxis2),
      get3DIndex(fixedAxis1, 3, fixedAxis2)
    ]
  of 2:  # Z varies
    return [
      get3DIndex(fixedAxis1, fixedAxis2, 0),
      get3DIndex(fixedAxis1, fixedAxis2, 1),
      get3DIndex(fixedAxis1, fixedAxis2, 2),
      get3DIndex(fixedAxis1, fixedAxis2, 3)
    ]
  else:
    return [0, 0, 0, 0]  # Should never reach here

# Helper function to generate diagonal lines within planes
proc generatePlaneDiagonals(fixedCoord: int, planeAxis: int, mainDiag: bool): array[4, int] =
  # Generate diagonal lines within a plane (XY, XZ, or YZ plane)
  case planeAxis:
  of 0:  # XY plane (Z fixed)
    if mainDiag:
      return [
        get3DIndex(0, 0, fixedCoord),
        get3DIndex(1, 1, fixedCoord),
        get3DIndex(2, 2, fixedCoord),
        get3DIndex(3, 3, fixedCoord)
      ]
    else:  # Anti-diagonal
      return [
        get3DIndex(3, 0, fixedCoord),
        get3DIndex(2, 1, fixedCoord),
        get3DIndex(1, 2, fixedCoord),
        get3DIndex(0, 3, fixedCoord)
      ]
  of 1:  # XZ plane (Y fixed)
    if mainDiag:
      return [
        get3DIndex(0, fixedCoord, 0),
        get3DIndex(1, fixedCoord, 1),
        get3DIndex(2, fixedCoord, 2),
        get3DIndex(3, fixedCoord, 3)
      ]
    else:  # Anti-diagonal
      return [
        get3DIndex(3, fixedCoord, 0),
        get3DIndex(2, fixedCoord, 1),
        get3DIndex(1, fixedCoord, 2),
        get3DIndex(0, fixedCoord, 3)
      ]
  of 2:  # YZ plane (X fixed)
    if mainDiag:
      return [
        get3DIndex(fixedCoord, 0, 0),
        get3DIndex(fixedCoord, 1, 1),
        get3DIndex(fixedCoord, 2, 2),
        get3DIndex(fixedCoord, 3, 3)
      ]
    else:  # Anti-diagonal
      return [
        get3DIndex(fixedCoord, 3, 0),
        get3DIndex(fixedCoord, 2, 1),
        get3DIndex(fixedCoord, 1, 2),
        get3DIndex(fixedCoord, 0, 3)
      ]
  else:
    return [0, 0, 0, 0]  # Should never reach here

proc generateWinningLines(): seq[array[4, int]] =
  var lines: seq[array[4, int]] = @[]
  
  # Generate axis-aligned lines (48 lines total: 16 each for X, Y, Z directions)
  # X-direction lines (horizontal within layers)
  for z in 0..3:
    for y in 0..3:
      lines.add(generateAxisLines(y, z, 0))
  
  # Y-direction lines (vertical within layers)  
  for z in 0..3:
    for x in 0..3:
      lines.add(generateAxisLines(x, z, 1))
  
  # Z-direction lines (depth across layers)
  for x in 0..3:
    for y in 0..3:
      lines.add(generateAxisLines(x, y, 2))
  
  # Generate diagonal lines within planes (24 lines total: 8 each for XY, XZ, YZ planes)
  # XY plane diagonals (within each Z layer)
  for z in 0..3:
    lines.add(generatePlaneDiagonals(z, 0, true))   # Main diagonal
    lines.add(generatePlaneDiagonals(z, 0, false))  # Anti-diagonal
  
  # XZ plane diagonals (across layers for each Y position)
  for y in 0..3:
    lines.add(generatePlaneDiagonals(y, 1, true))   # Main diagonal
    lines.add(generatePlaneDiagonals(y, 1, false))  # Anti-diagonal
  
  # YZ plane diagonals (across layers for each X position)
  for x in 0..3:
    lines.add(generatePlaneDiagonals(x, 2, true))   # Main diagonal
    lines.add(generatePlaneDiagonals(x, 2, false))  # Anti-diagonal
  
  # Generate 3D space diagonals (4 lines: corner to opposite corner)
  # Define the 4 space diagonal patterns
  let spaceDiagonals = @[
    [(0, 0, 0), (1, 1, 1), (2, 2, 2), (3, 3, 3)],  # (0,0,0) -> (3,3,3)
    [(3, 0, 0), (2, 1, 1), (1, 2, 2), (0, 3, 3)],  # (3,0,0) -> (0,3,3)
    [(0, 3, 0), (1, 2, 1), (2, 1, 2), (3, 0, 3)],  # (0,3,0) -> (3,0,3)
    [(0, 0, 3), (1, 1, 2), (2, 2, 1), (3, 3, 0)]   # (0,0,3) -> (3,3,0)
  ]
  
  for diag in spaceDiagonals:
    lines.add([
      get3DIndex(diag[0][0], diag[0][1], diag[0][2]),
      get3DIndex(diag[1][0], diag[1][1], diag[1][2]),
      get3DIndex(diag[2][0], diag[2][1], diag[2][2]),
      get3DIndex(diag[3][0], diag[3][1], diag[3][2])
    ])
  
  return lines

# Cache the winning lines (computed once at compile time would be ideal, but using runtime for simplicity)
let WINNING_LINES = generateWinningLines()

# Simplified function to check win conditions and get winning positions
proc checkWinAndGetPositions(board: array[64, Player]): (GameState, seq[int]) =
  # Check each possible winning line
  for line in WINNING_LINES:
    let first = board[line[0]]
    # Check if all 4 positions in this line have the same non-empty player
    if first != Player.Empty and
       first == board[line[1]] and
       first == board[line[2]] and
       first == board[line[3]]:
      # Found a winner!
      let winner = if first == Player.X: GameState.XWins else: GameState.OWins
      let winningPositions = @[line[0], line[1], line[2], line[3]]
      return (winner, winningPositions)
  
  # No winner found - check for draw or still playing
  for cell in board:
    if cell == Player.Empty:
      return (GameState.Playing, @[])
  
  return (GameState.Draw, @[])

# reorientCoords will return x,y,z coordinates reoriented along an axis
proc reorientCoords(newUp: Axis, x: int, y: int, z: int): (int, int, int) {.inline.} =
  case newUp
  of X:
    return (z, y, x)
  of Y:
    return (x, z, y)
  of Z:
    return (z, x, y)

# reorient allows us to reorient the perspective along an axis
proc reorient(game: var Game, newUp: Axis) =
  var newBoard: array[64, Player]
  for x in 0..3:
    for y in 0..3:
      for z in 0..3:
        let oldIndex = x + 4*y + 16*z
        var newX, newY, newZ: int
        (newX, newY, newZ) = reorientCoords(newUp, x, y, z)
        let newIndex = newX + 4*newY + 16*newZ
        newBoard[newIndex] = game.board[oldIndex]
  
  game.board = newBoard

  # also reorient cursor and winningPositions, if set
  (game.cursorX, game.cursorY, game.cursorZ) = reorientCoords(newUp, game.cursorX, game.cursorY, game.cursorZ)

  for i, pos in game.winningPositions.pairs:
    var (x, y, z) = get3DCoords(pos)
    (x, y, z) = reorientCoords(newUp, x, y, z)
    game.winningPositions[i] = get3DIndex(x, y, z)

# Display the board (3D side-by-side with vertical offset)
proc displayBoard(game: Game) =
  clearScreen()
  echo BOLD & CYAN & "=== NIM 3D TIC-TAC-TOE (4x4x4) ===" & RESET
  echo ""
  echo "Scores - Human: " & GREEN & $game.humanScore & RESET & " | AI: " & BLUE & $game.aiScore & RESET & " | Draws: " & YELLOW & $game.draws & RESET
  echo "Games played: " & WHITE & $game.totalGames & RESET
  echo ""
  
  # Create display buffer for all layers
  var layerBuffers: array[4, array[4, string]]  # 4 layers, 4 rows each
  
  # Fill layer buffers
  for layer in 0..3:
    for row in 0..3:
      var rowStr = ""
      for col in 0..3:
        let pos = get3DIndex(col, row, layer)
        let isWinning = pos in game.winningPositions
        let symbol = getPlayerSymbolWithWin(game.board[pos], isWinning)
        
        # Check if this is the current cursor position
        if col == game.cursorX and row == game.cursorY and layer == game.cursorZ and game.gameState == GameState.Playing:
          rowStr &= BG_GREEN & WHITE & "[" & symbol & BG_GREEN & "]" & RESET
        else:
          rowStr &= "[" & symbol & "]"
        
        if col < 3:
          rowStr &= " "
      layerBuffers[layer][row] = rowStr
  
  # Display with vertical offset: each board starts 2 lines lower than previous
  # Total height needed: 4 (rows) + 3 (spacing) + 6 (offset for layer 4) = ~13 lines
  let maxRows = 4 + 6  # 4 board rows + 6 lines offset for layer 4
  
  for displayRow in 0..<maxRows+1:
    for layer in 0..3:
      let layerOffset = layer * 2  # Each layer offset by 2 lines
      
      # Display layer header on first line
      if displayRow == layerOffset:
        stdout.write("Layer " & $(layer + 1) & ":")
      # Display board rows
      elif displayRow > layerOffset and displayRow <= layerOffset + 4:
        let boardRow = displayRow - layerOffset - 1
        if boardRow < 4:
          stdout.write(layerBuffers[layer][boardRow])
        else:
          stdout.write("               ")  # Empty space
      else:
        stdout.write("               ")  # Empty space (8 spaces to match board width)
      
      if layer < 3:
        stdout.write("    ")  # Horizontal spacing between layers
    echo ""
  
  echo ""
  echo BOLD & "Current Layer: " & $(game.cursorZ + 1) & RESET & " | Position: (" & $(game.cursorX + 1) & "," & $(game.cursorY + 1) & "," & $(game.cursorZ + 1) & ")"
  echo ""
  
  case game.gameState:
  of GameState.Playing:
    if game.currentPlayer == Player.X:
      echo BOLD & GREEN & "Your turn! Use arrow keys to move, SPACE or TAB to change layer, Enter to place X" & RESET
      echo ""
      echo GREEN & "You can change perspective using 'x', 'y', and 'z', which can be both helpful and confusing" & RESET
    else:
      echo BOLD & BLUE & "AI is thinking..." & RESET
  of GameState.XWins:
    echo BOLD & GREEN & "🎉 You win! 🎉" & RESET
  of GameState.OWins:
    echo BOLD & BLUE & "🤖 AI wins! 🤖" & RESET
  of GameState.Draw:
    echo BOLD & YELLOW & "🤝 It's a draw! 🤝" & RESET
  
  echo ""
  echo "Controls: Arrow keys=move, SPACE=change layer, Enter=place, 'q'=quit"


# Make a move (3D)
proc makeMove(game: var Game, x, y, z: int): bool =
  if x < 0 or x >= 4 or y < 0 or y >= 4 or z < 0 or z >= 4:
    return false
  
  let pos = get3DIndex(x, y, z)
  if game.board[pos] != Player.Empty:
    return false
  
  game.board[pos] = game.currentPlayer
  let (gameState, winningPositions) = checkWinAndGetPositions(game.board)
  game.gameState = gameState
  game.winningPositions = winningPositions
  
  # Update scores when win is detected
  case game.gameState:
  of GameState.XWins:
    game.humanScore += 1
  of GameState.OWins:
    game.aiScore += 1
  of GameState.Draw:
    game.draws += 1
  else:
    discard
  
  if game.gameState == GameState.Playing:
    game.currentPlayer = if game.currentPlayer == Player.X: Player.O else: Player.X
  
  return true

# Minimax algorithm for AI (3D) with depth limiting
# MAX_DEPTH prevents endless loops in 3D space (64 cells can be computationally expensive)
const MAX_DEPTH = 4  # Limit search depth to prevent endless loops

proc minimax(board: array[64, Player], depth: int, isMaximizing: bool): int =
  let (state, _) = checkWinAndGetPositions(board)
  
  case state:
  of GameState.OWins: return 10 - depth
  of GameState.XWins: return depth - 10
  of GameState.Draw: return 0
  of GameState.Playing:
    # Limit depth to prevent endless loops
    if depth >= MAX_DEPTH:
      return 0  # Return neutral score at max depth
    
    if isMaximizing:
      var bestScore = -1000
      for i in 0..63:
        if board[i] == Player.Empty:
          var newBoard = board
          newBoard[i] = Player.O
          let score = minimax(newBoard, depth + 1, false)
          bestScore = max(bestScore, score)
      return bestScore
    else:
      var bestScore = 1000
      for i in 0..63:
        if board[i] == Player.Empty:
          var newBoard = board
          newBoard[i] = Player.X
          let score = minimax(newBoard, depth + 1, true)
          bestScore = min(bestScore, score)
      return bestScore

# Check if a move would result in a win for a player (3D)
proc wouldWin(board: array[64, Player], x, y, z: int, player: Player): bool =
  var testBoard = board
  let pos = get3DIndex(x, y, z)
  testBoard[pos] = player
  let (state, _) = checkWinAndGetPositions(testBoard)
  return (state == GameState.XWins and player == Player.X) or (state == GameState.OWins and player == Player.O)

# Get AI move (3D) - Smart AI with strategic thinking
proc getAIMove(game: Game): (int, int, int) =
  var availableMoves: seq[(int, int, int)] = @[]
  
  # Find all available moves
  for x in 0..3:
    for y in 0..3:
      for z in 0..3:
        let pos = get3DIndex(x, y, z)
        if game.board[pos] == Player.Empty:
          availableMoves.add((x, y, z))
  
  # If no moves available, return (0,0,0) (shouldn't happen)
  if availableMoves.len == 0:
    return (0, 0, 0)
  
  # PRIORITY 1: Take winning moves immediately
  for move in availableMoves:
    if wouldWin(game.board, move[0], move[1], move[2], Player.O):
      return move
  
  # PRIORITY 2: Block human wins (prevent immediate loss)
  for move in availableMoves:
    if wouldWin(game.board, move[0], move[1], move[2], Player.X):
      return move
  
  # PRIORITY 3: Look for moves that create multiple threats (forks)
  # A fork is a move that creates two or more potential winning lines
  for move in availableMoves:
    let (x, y, z) = move
    let pos = get3DIndex(x, y, z)
    var testBoard = game.board
    testBoard[pos] = Player.O
    
    # Count how many winning moves this creates for AI
    var winningMovesCreated = 0
    for nextMove in availableMoves:
      if nextMove == move:
        continue
      if wouldWin(testBoard, nextMove[0], nextMove[1], nextMove[2], Player.O):
        winningMovesCreated += 1
    
    # If this move creates 2+ winning opportunities, it's a strong fork
    if winningMovesCreated >= 2:
      return move
  
  # PRIORITY 4: Block human forks (moves that create multiple threats for human)
  for move in availableMoves:
    let (x, y, z) = move
    let pos = get3DIndex(x, y, z)
    var testBoard = game.board
    testBoard[pos] = Player.X  # Simulate human playing here
    
    # Count how many winning moves this would create for human
    var humanWinningMoves = 0
    for nextMove in availableMoves:
      if nextMove == move:
        continue
      if wouldWin(testBoard, nextMove[0], nextMove[1], nextMove[2], Player.X):
        humanWinningMoves += 1
    
    # If human would get 2+ winning opportunities, block this
    if humanWinningMoves >= 2:
      return move
  
  # PRIORITY 5: Prefer center and strategic positions
  # Center positions (1,1,1), (1,1,2), (1,2,1), (1,2,2), (2,1,1), (2,1,2), (2,2,1), (2,2,2) are more valuable
  var strategicMoves: seq[(int, int, int)] = @[]
  for move in availableMoves:
    let (x, y, z) = move
    # Count how many winning lines this position is part of
    var lineCount = 0
    for line in WINNING_LINES:
      for pos in line:
        if pos == get3DIndex(x, y, z):
          lineCount += 1
          break
    
    # Positions that are part of more winning lines are more strategic
    if lineCount >= 4:  # Positions in 4+ winning lines are strategic
      strategicMoves.add(move)
  
  # If we have strategic moves, pick one randomly
  if strategicMoves.len > 0:
    let randomIndex = rand(strategicMoves.len - 1)
    return strategicMoves[randomIndex]
  
  # PRIORITY 6: Use minimax for optimal play when no clear strategic moves
  # Only use minimax when there are reasonable number of moves left
  if availableMoves.len <= 16:
    var bestScore = -1000
    var bestMove = availableMoves[0]  # Default to first available move
    
    for x in 0..3:
      for y in 0..3:
        for z in 0..3:
          let pos = get3DIndex(x, y, z)
          if game.board[pos] == Player.Empty:
            var newBoard = game.board
            newBoard[pos] = Player.O
            let score = minimax(newBoard, 0, false)
            if score > bestScore:
              bestScore = score
              bestMove = (x, y, z)
    
    return bestMove
  
  # PRIORITY 7: If too many moves or no clear strategy, make a reasonable random choice
  # Prefer positions that are part of more winning lines
  var weightedMoves: seq[(int, int, int)] = @[]
  for move in availableMoves:
    let (x, y, z) = move
    var lineCount = 0
    for line in WINNING_LINES:
      for pos in line:
        if pos == get3DIndex(x, y, z):
          lineCount += 1
          break
    
    # Add move multiple times based on its strategic value
    for i in 1..lineCount:
      weightedMoves.add(move)
  
  if weightedMoves.len > 0:
    let randomIndex = rand(weightedMoves.len - 1)
    return weightedMoves[randomIndex]
  else:
    # Fallback to completely random
    let randomIndex = rand(availableMoves.len - 1)
    return availableMoves[randomIndex]

# Setup raw terminal mode
proc setupRawTerminal() =
  var termios: Termios
  discard tcgetattr(STDIN_FILENO, termios.addr)
  termios.c_lflag = termios.c_lflag and not (ICANON or ECHO)
  termios.c_cc[VMIN] = 1.char
  termios.c_cc[VTIME] = 0.char
  discard tcsetattr(STDIN_FILENO, TCSANOW, termios.addr)

# Restore terminal mode
proc restoreTerminal() =
  var termios: Termios
  discard tcgetattr(STDIN_FILENO, termios.addr)
  termios.c_lflag = termios.c_lflag or ICANON or ECHO
  discard tcsetattr(STDIN_FILENO, TCSANOW, termios.addr)

# Read single character
proc readChar(): char =
  var ch: char
  discard read(STDIN_FILENO, ch.addr, 1)
  return ch

# Handle 3D input
proc handleInput(game: var Game): bool =
  let ch = readChar()
  
  case ch:
  of 'q', 'Q':  # q or Q
    return false
  of ' ', '\t':  # SPACE or TAB key - change layer
    if game.gameState == GameState.Playing and game.currentPlayer == Player.X:
      game.cursorZ = (game.cursorZ + 1) mod 4
    return true
  of 'x':  # reorient along X axis
    reorient(game, Axis.X)
    return true
  of 'y':  # reorient along Y axis
    reorient(game, Axis.Y)
    return true
  of 'z':  # reorient along Z axis
    reorient(game, Axis.Z)
    return true
  of '\x1b':  # Escape key or start of escape sequence
    let ch2 = readChar()
    if ch2 == '[':
      let ch3 = readChar()
      case ch3:
      of 'A':  # Up arrow
        if game.gameState == GameState.Playing and game.currentPlayer == Player.X:
          game.cursorY = (game.cursorY - 1 + 4) mod 4
      of 'B':  # Down arrow
        if game.gameState == GameState.Playing and game.currentPlayer == Player.X:
          game.cursorY = (game.cursorY + 1) mod 4
      of 'C':  # Right arrow
        if game.gameState == GameState.Playing and game.currentPlayer == Player.X:
          game.cursorX = (game.cursorX + 1) mod 4
      of 'D':  # Left arrow
        if game.gameState == GameState.Playing and game.currentPlayer == Player.X:
          game.cursorX = (game.cursorX - 1 + 4) mod 4
      else:
        discard
      return true
    else:
      return true
  of '\r', '\n':  # Enter
    if game.gameState == GameState.Playing and game.currentPlayer == Player.X:
      if makeMove(game, game.cursorX, game.cursorY, game.cursorZ):
        if game.gameState == GameState.Playing:
          # AI move
          let aiMove = getAIMove(game)
          discard makeMove(game, aiMove[0], aiMove[1], aiMove[2])
    elif game.gameState != GameState.Playing:
      # Start new game
      resetGame(game)
      game.totalGames += 1
    return true
  else:
    return true

# Main game loop
proc main() =
  var game = initGame()
  game.totalGames = 1
  
  setupRawTerminal()
  hideCursor()
  
  try:
    while true:
      displayBoard(game)
      
      if not handleInput(game):
        break
      
      # Small delay for AI move visibility
      if game.currentPlayer == Player.O and game.gameState == GameState.Playing:
        sleep(500)  # 500ms delay
        let aiMove = getAIMove(game)
        discard makeMove(game, aiMove[0], aiMove[1], aiMove[2])
  
  finally:
    restoreTerminal()
    showCursor()
    clearScreen()
    echo BOLD & GREEN & "Thanks for playing!" & RESET

when isMainModule:
  main()
