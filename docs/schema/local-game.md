# Local game

Two people play a match of untimed chess games to 15 points by handing a phone back and forth, with a doubling cube to raise each game's point stake.

## Data

### Current game (one per device)

| Field | Type | Saved | Notes |
|---|---|---|---|
| Position | chess position | yes | Pieces on squares, side to move, castling rights and en passant availability. Starts in the standard chess opening position, White to move. |
| Result | text? | yes | Absent before the game finishes. Otherwise records winner or draw and the reason. |
| Stake | number? | yes | 1, 2, 4, 8, 16, 32 or 64 points. Absent only for a game already finished in a save from before the cube; show its result without a point award. |
| Next doubler | colour? | yes | Before the first take this is absent and either colour has the right to offer. After a take, records the taker's colour. At 64 points neither can offer. |
| Double pending | true or false | yes | True after an offer is made and before it is answered. The offerer is the side to move; the responder is the other colour. |
| Selection | square? | no | Absent until a player selects one of their pieces. |

### Match score (one per device)

| Field | Type | Saved | Notes |
|---|---|---|---|
| White total | number | yes | Whole or half points, from 0. The sum of the points awarded to White in this match's games, including the current game once it has finished. |
| Black total | number | yes | As White total, for Black. |

The match score and the current game are saved together as one record: a game's result and its award to the totals are written in the same save. Colours stay fixed for the whole match, so the totals belong to White and Black, not to the people holding the phone. The target is 15 points.

## States

**Game.** States: playing, choosing promotion, awaiting double response, finished, match over. Initial: playing in a fresh match at 0 to 0; otherwise restore the saved state as below.

The side to move is eligible to offer while playing if the stake is below 64 and the next doubler is absent or is that side. This includes the opening turn and turns in check. No rule limits doubling by the match score.

A game that ends awards its stake to the winner, or half its stake to each colour on a draw, and adds the award to the match score. The game ends in match over when, with the award added, either total is 15 or more; otherwise it ends in finished. In match over the higher total wins the match, and equal totals draw it. The match is under way in every state but match over.

| From | Event | Guard | To | Effect |
|---|---|---|---|---|
| playing | Select own piece | — | playing | Replace selection and mark its legal destinations. An invalid destination never moves a piece. |
| playing | Tap any other square | Piece selected; the square is neither an own piece nor a legal destination | playing | Clear the selection and its marked destinations. Keep position and turn. |
| playing | Tap legal destination | Promotion required | choosing promotion | Keep position and turn uncommitted. |
| choosing promotion | Cancel | — | playing | Keep original position and turn, with the pawn still selected and its legal destinations marked. |
| playing, choosing promotion | Complete move | Legal destination selected, promotion choice supplied if required | playing, finished or match over | Save the new position, any automatic result and its award to the match score together. If play continues, hand off to the other colour. |
| playing | Tap Offer double | Side to move is eligible | awaiting double response | Save the pending offer at once, without confirmation and without changing the position, turn or stake. Clear selection. The offer can't be withdrawn. |
| awaiting double response | Take | — | playing | Save twice the old stake, the responder as next doubler, and no pending offer together. Keep the position and turn. |
| awaiting double response | Decline | — | finished or match over | Save a win for the offerer by declined double, no pending offer and the old stake awarded to the offerer together. Keep the position and old stake. |
| playing | Confirm resignation or agreed draw | — | finished or match over | Record a loss for the side to move, or a draw, respectively, with its award to the match score. Cancelling changes nothing. |
| finished | Next game | — | playing | At once, without confirmation, replace the current game with the opening position, no result, a stake of one point and neither a named next doubler nor a pending offer. Keep the match score. |
| playing, finished, match over | New match | Confirm replacement unless match over | playing | Replace the current game as for Next game, and set both totals to 0. Cancelling keeps the match. |
| any | Reopen | Saved game exists | playing, awaiting double response, finished or match over | Restore the last committed game and match score. Unfinished promotions are not committed changes. An ongoing save from before the cube opens at one point with either player eligible on their turn, without changing the position or turn. A save from before matches opens as the first game of a match: an ongoing game at 0 to 0, a finished game with a stake with its award as the score, and a finished game from before the cube at 0 to 0. |

Automatic endings: checkmate wins for the mover; stalemate draws. Draw for insufficient mating material with kings alone, just one bishop or knight besides the kings, or only bishops besides the kings with all bishops on squares of one colour. These are not tests for whether a mate can be *forced*.

## Screens and surfaces

| Destination | Kind | Opens from | Returns to |
|---|---|---|---|
| Board | root | Launch | — |
| Promotion choice | dialog | Board, promotion destination | Board |
| Confirm action | dialog | Board, resign / agree draw / replace a match under way | Board |

| Surface | Shown on | Shown while | Notes |
|---|---|---|---|
| Double response | Board | awaiting double response | The board stays visible and no game action other than Take or Decline is available. |

## Component roles

| Element | Role | Meaning | Content and behaviour |
|---|---|---|---|
| Board.position | chessboard | Play surface | 64 squares; each labelled by coordinate and occupant, with selection and legal destination conveyed without relying on colour alone. During a double response, put the responder's pieces at the bottom instead of the side to move's and accept no board moves. |
| Board.status | game-status | Turn, responder or final result | Announce turn and check when applicable, who must answer a pending offer, or the outcome including reason and any point award. In match over, also the match result. Keep final board visible and no longer playable. |
| Board.stake | game-stake | Points in play and right to offer | Show the stake and who holds the right to offer during play, even when it is not that player's turn. During a response, show the old stake alongside the offer's consequences. |
| Board.score | match-score | Points each colour has in the match, and the target | Show White's and Black's totals and the target in every state, including during a double response and in match over. No game number and no list of earlier games. |
| Board.actions | game-actions | Manage the current game and match | New match is available outside dialogs except during a double response. Next game only in finished. In match over, New match is the only action. Resign and agree draw only while playing. Confirm an agreed draw on behalf of both people at the board. Offer double is actionable only for an eligible side to move. |
| Double response.actions | double-choice | Resolve the offer | Name the responder and explain the point consequences of Take and Decline alongside the two actions, including when declining ends the match. |
| Promotion.options | piece-choice | Complete promotion | Queen, rook, bishop or knight of the mover's colour. |

## Interface text

| Key | Text | Notes |
|---|---|---|
| turn / check | {side} to move / {side} to move · Check | Side is White or Black. |
| square | {coordinate}, {occupant} | Empty or colour and piece name; coordinate independent of orientation. |
| selection / destination | Selected / Legal destination | Square states. |
| win | {winner} wins · {reason} | Checkmate, Resignation or Double declined. |
| draw | Draw · {reason} | Stalemate, Insufficient material or Agreement. |
| stake | Stake: {stake} | Include point units. |
| doubleRight | Either player can offer / Only {next doubler} can offer / Maximum stake reached | Right to offer on one's own turn. |
| offer | Offer double | Makes the offer at once, without confirmation. |
| response | {responder}, answer the double | Responder is White or Black. |
| take / decline | Take / Decline | Actions for the responder. |
| takeEffect | Take: play for {doubled stake}. | Include point units. |
| declineEffect / declineEffectMatch | Decline: {offerer} wins {stake}. / Decline: {offerer} wins {stake} and the match. | Include point units. Offerer is White or Black. The second when the offerer's total with the old stake added is 15 or more. |
| winAward / drawAward | {winner} earns {stake}. / Each player earns {half stake}. | Include point units. Show half a point as ½ point and announce it as “half a point.” |
| matchScore | White {White total} · Black {Black total} · first to 15 | Include point units on each total and the target. Show a half as ½ after the whole number, as in 4½ points, or ½ point alone, and announce it as “and a half”, or “half a point” alone. |
| matchWin / matchDraw | {winner} wins the match, {winner's total} to {loser's total} / Match drawn, {total} to {total} | Shown with the game's result and award in match over. Totals without units, with halves as in matchScore. |
| next | Next game | Starts the next game at once. |
| new / replace | New match / Replace this match? | Replace only on confirmation while the match is under way. |
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

No clock, computer opponent, undo, saved-game list, remote play, separate plain-chess mode, single game outside a match, or currency. No choice of target, tiebreaker, Crawford rule or other limit on doubling by the match score, swapping colours between games, game number or list of earlier games. No way to end a game except by its own endings; New match replaces the whole match. No tournament claim controls or automatic repetition/move-count adjudication; players may agree a draw.

## Links to other features

None

## Acceptance criteria

- **C1.** When opening without a game, the players shall see the standard opening position with White at the bottom and White to move. On reopening a game they shall see the last committed position, turn or result, with the same legal continuations. If the app is ended while a change is saving, then the app shall reopen on the saved game as it was before or after that change, never part of either (simplifications, #5 and #6). On Android, ending the app also drops a selection or an open dialog (simplification, #6).
- **C2.** While playing, the player shall be able to tap or reselect an own piece, see only its legal destinations, and commit by tapping one, including castling and en passant; promotion requires choosing a piece before commitment. An illegal move shall leave position and turn unchanged. If a tap can't be used, then on iOS the app shall leave position and turn unchanged, with no message (simplification, #5).
- **C3.** After a move that continues play, the board shall put the next player's pieces at the bottom, identify their turn and any check, and accept their move immediately without confirmation, a ready screen or take-back.
- **C4.** When an automatic ending occurs or the players confirm resignation or a draw, the board shall show the final position, result and reason and stop accepting moves. While the saved game is loading or a change is saving, on Android the app shall not offer New match or Next game and shall ignore taps, without showing progress (simplification, #6).
- **C5.** If the current game cannot be read or a change cannot be saved, the app shall preserve the last saved game, identify what failed and not present a fresh game or an unsaved change as committed. Each failure is named without its cause. If the app is ended after a failed save, then the unsaved change is lost without notice and the last saved game reopens (simplifications, #5 and #6).
- **C6.** When starting a game or reopening an ongoing game saved before the cube, the players shall see a stake of one point and that either player can offer. While playing, the board shall show the stake and who has the right to offer, and allow Offer double only for the eligible side to move, including on the opening turn or in check, but never at 64 points.
- **C7.** When a player taps Offer double, the app shall make the offer at once, without confirmation. While awaiting a response to an offer, including on reopening, the board shall face the named responder, show the unchanged position and the point consequences of taking or declining, and accept no game action other than Take or Decline.
- **C8.** When the responder takes, the board shall face the offerer again and let them move from the same position, at twice the old stake. Only the taker shall have the right to offer the next double, on a later turn of theirs and below the maximum stake.
- **C9.** When the responder declines, the app shall end the game without a move and show the offerer winning by declined double at the old stake. For a finished game with a stake, the final board shall show the winner awarded the stake or, on a draw, each player awarded half, including ½ point each at a stake of one. A game saved before the cube that was already finished shall still show its original result without a point award.
- **C10.** The board shall show White's and Black's match totals and the target of 15 points in every state, including during a double response and after the match ends, starting at 0 to 0 in a new match. When a game ends, the app shall add its award to the totals, saved with the game's result, so that reopening shows the same totals.
- **C11.** When a game ends with both totals below 15, the board shall offer Next game. When the players tap it, the app shall start the next game at once, without confirmation, in the opening position with White at the bottom and White to move, at a stake of one point that either player can offer, and keep the totals.
- **C12.** When a game ends with either total at 15 or more, the board shall show the match result with the game's result and award, such as "White wins the match, 16 to 9" or "Match drawn, 15 to 15", the higher total winning and equal totals drawing. New match shall then be the only action, and start a new match at 0 to 0 without confirmation.
- **C13.** While a match is under way, New match shall ask for confirmation, and on confirmation replace the current game and the totals with a fresh game at 0 to 0; cancelling changes nothing. New match shall not be available during a double response.
- **C14.** When declining a pending offer would give the offerer 15 points or more, the double response shall say that the offerer wins the match by the decline, such as "Decline: White wins 4 points and the match."
- **C15.** When reopening a game saved before matches, the app shall show it as the first game of a match: an ongoing game at 0 to 0, a finished game with a stake with its award as the totals, and a finished game from before the cube at 0 to 0. Once that game has finished, the board shall offer Next game, or the match result if a total has reached 15.
