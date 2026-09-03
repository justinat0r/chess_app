/// What the player chose on a win or tie screen.
enum ResultAction {
  /// Start another game from the initial position.
  rematch,

  /// Return to the title screen.
  mainMenu,

  /// Go back to the finished board to look at the final position.
  reviewBoard,
}
