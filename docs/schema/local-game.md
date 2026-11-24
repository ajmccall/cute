# Local game

Two people play one untimed game of chess by handing a phone back and forth.

## Data

### Current game (one per device)

| Field | Type | Saved | Notes |
|---|---|---|---|
| Position | chess position | yes | Pieces on squares, side to move, castling rights and en passant availability. Starts in the standard chess opening position, White to move. |
| Result | text? | yes | Absent during play. Otherwise records winner or draw and the reason. |
| Selection | square? | no | Absent until a player selects one of their pieces. |

## States

**Game.** States: playing, choosing promotion, finished. Initial: playing unless restoring a finished game.

| From | Event | Guard | To | Effect |
|---|---|---|---|---|
| playing | Select own piece | — | playing | Replace selection and mark its legal destinations. An invalid destination never moves a piece. |
| playing | Tap any other square | Piece selected; the square is neither an own piece nor a legal destination | playing | Clear the selection and its marked destinations. Keep position and turn. |
| playing | Tap legal destination | Promotion required | choosing promotion | Keep position and turn uncommitted. |
| choosing promotion | Cancel | — | playing | Keep original position and turn, with the pawn still selected and its legal destinations marked. |
| playing, choosing promotion | Complete move | Legal destination selected, promotion choice supplied if required | playing or finished | Save the new position and any automatic result together. If play continues, hand off to the other colour. |
| playing | Confirm resignation or agreed draw | — | finished | Record a loss for the side to move, or a draw, respectively. Cancelling changes nothing. |
| playing, finished | New game | Confirm replacement if still playing | playing | Replace current game with the opening position and no result. Cancelling keeps the game. |
| any | Reopen | Saved game exists | playing or finished | Show last committed game; an unfinished promotion never becomes a move on relaunch. |

Automatic endings: checkmate wins for the mover; stalemate draws. Draw for insufficient mating material with kings alone, just one bishop or knight besides the kings, or only bishops besides the kings with all bishops on squares of one colour. These are not tests for whether a mate can be *forced*.

## Screens and surfaces

| Destination | Kind | Opens from | Returns to |
|---|---|---|---|
| Board | root | Launch | — |
| Promotion choice | dialog | Board, promotion destination | Board |
| Confirm action | dialog | Board, resign / agree draw / replace ongoing game | Board |

## Component roles

| Element | Role | Meaning | Content and behaviour |
|---|---|---|---|
| Board.position | chessboard | Play surface | 64 squares; each labelled by coordinate and occupant, with selection and legal destination conveyed without relying on colour alone. |
| Board.status | game-status | Whose turn or final result | Announce turn, check when applicable, or outcome including reason. Keep final board visible and no longer playable. |
| Board.actions | game-actions | Manage current game | New game always available outside a dialog. Resign and agree draw only during play. Confirm an agreed draw on behalf of both people at the board. |
| Promotion.options | piece-choice | Complete promotion | Queen, rook, bishop or knight of the mover's colour. |

## Interface text

| Key | Text | Notes |
|---|---|---|
| turn / check | {side} to move / {side} to move · Check | Side is White or Black. |
| square | {coordinate}, {occupant} | Empty or colour and piece name; coordinate independent of orientation. |
| selection / destination | Selected / Legal destination | Square states. |
| win | {winner} wins · {reason} | Checkmate or Resignation. |
| draw | Draw · {reason} | Stalemate, Insufficient material or Agreement. |
| new / replace | New game / Replace this game? | Replace only on confirmation during play. |
| resign / confirmResign | Resign / Resign as {side}? | Side to move. |
| agree / confirmDraw | Agree draw / Do both players agree to a draw? | Confirm or cancel locally. |
| confirm / cancel | Confirm / Cancel | Dialog actions. |
| readFailure / writeFailure | Couldn’t open the saved game. / Change not saved. | Leave the last committed data untouched; allow retry. |
| retry | Retry | Try the failed operation again. |
| promotion / choices | Promote pawn / Queen, Rook, Bishop, Knight | Four separate choices. |

## Deliberate platform differences

- Android: departs from Android rule 5.2 for the board's squares only. Each square is one eighth of the board's width, so it falls below 48 dp on screens narrower than 384 dp (45 dp at 360 dp); every other control keeps 48 dp (the squares touch with no gaps, so every tap lands on exactly one square, and a scrolling board would hide part of it; product owner decision 1a on [#6](https://github.com/ajmccall/cute/issues/6), 2026-11-23).
- Differs, not decided: iOS and Android: when the saved game can't be read and the confirmed New game then can't be saved, iOS shows "Couldn’t open the saved game." and "Change not saved.", each with its own Retry, while Android shows only "Change not saved.", whose Retry saves the new game again. Neither shows a board or turn, and the saved file is untouched (behind a failed read and a failed save together; #2).

## Non-goals

No clock, computer opponent, undo, saved-game list, remote play, cube, stakes or match score. No tournament claim controls or automatic repetition/move-count adjudication; players may agree a draw.

## Links to other features

None

## Acceptance criteria

- **C1.** When opening without a game, the players shall see the standard opening position with White at the bottom and White to move. On reopening a game they shall see the last committed position, turn or result, with the same legal continuations. If the app is ended while a change is saving, then the app shall reopen on the saved game as it was before or after that change, never part of either (simplifications, #5 and #6). On Android, ending the app also drops a selection or an open dialog (simplification, #6).
- **C2.** While playing, the player shall be able to tap or reselect an own piece, see only its legal destinations, and commit by tapping one, including castling and en passant; promotion requires choosing a piece before commitment. An illegal move shall leave position and turn unchanged. If a tap can't be used, then on iOS the app shall leave position and turn unchanged, with no message (simplification, #5).
- **C3.** After a move that continues play, the board shall put the next player's pieces at the bottom, identify their turn and any check, and accept their move immediately without confirmation, a ready screen or take-back.
- **C4.** When an automatic ending occurs or the players confirm resignation or a draw, the board shall show the final position, result and reason and stop accepting moves. New game shall start fresh, requiring confirmation only when abandoning an ongoing game. While the saved game is loading or a change is saving, on Android the app shall not offer New game and shall ignore taps, without showing progress (simplification, #6).
- **C5.** If the current game cannot be read or a change cannot be saved, the app shall preserve the last saved game, identify what failed and not present a fresh game or an unsaved change as the saved position. Each failure is named without its cause. If the app is ended after a failed save, then the unsaved change is lost without notice and the last saved game reopens (simplifications, #5 and #6).
