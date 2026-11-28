# Local game

Two people play a match of untimed chess games to 15 points by handing a phone back and forth, with a doubling cube to raise each game's point stake. Players can offer voluntary doubles; a testing switch enables automatic doubles at up to two position-based milestones per game. The app stays in portrait when the phone is rotated; this is separate from the board turning to face a player.

## Data

### Current game (one per device)

| Field | Type | Saved | Notes |
|---|---|---|---|
| Position | chess position | yes | Pieces on squares, side to move, castling rights and en passant availability. Starts in the standard chess opening position, White to move. |
| Result | text? | yes | Absent before the game finishes. Otherwise records winner or draw and the reason. |
| Stake | number? | yes | 1, 2, 4, 8, 16, 32 or 64 points. Absent only for a game already finished in a save from before the cube; show its result without a point award. |
| Next doubler | colour? | yes | Before the first take this is absent and either colour has the right to offer. After a take, records the taker's colour. At 64 points neither can offer. |
| Double pending | true or false | yes | True after a voluntary offer is made and before it is answered. The offerer is the side to move; the responder is the other colour. |
| Automatic milestones | availability for opening and endgame | yes | Both available in a fresh game and in saves from before automatic doubles. Once used or retired, a milestone cannot become available again in that game. |
| Automatic double pending | decision? | yes | Absent outside an automatic-double decision. The first responder is the mover, opposite the saved side to move; save their Continue or Stop answer once given. |
| Captures | pieces for each colour | yes | The opponent's pieces each colour has captured in this game, in the order taken. Each is the piece that stood on the captured square: a captured promoted piece is its promoted kind, and an en passant capture is a pawn. Empty in a fresh game. |
| Selection | square? | no | Absent until a player selects one of their pieces. |

Material is not saved. Each colour's material is the total value of its pieces on the board: pawn 1, knight 3, bishop 3, rook 5, queen 9, and kings not counted. The colour with the higher total is ahead by the difference.

### Testing control (one per device)

| Field | Type | Saved | Notes |
|---|---|---|---|
| Automatic doubles | true or false | yes | Starts false on a fresh install. A device-local control for the whole automatic-doubling rule; not a setting saved per game. Remains set across app restarts and updates. |

### Match score (one per device)

| Field | Type | Saved | Notes |
|---|---|---|---|
| White total | number | yes | Whole or half points, from 0. The sum of the points awarded to White in this match's games, including the current game once it has finished. |
| Black total | number | yes | As White total, for Black. |

The match score and the current game are saved together as one record: a game's result and its award to the totals are written in the same save. Colours stay fixed for the whole match, so the totals belong to White and Black, not to the people holding the phone. The target is 15 points.

## States

**Game.** States: playing, choosing promotion, awaiting double response (voluntary), awaiting first automatic answer, awaiting second automatic answer, finished, match over. Initial: playing in a fresh match at 0 to 0; otherwise restore the saved state as below.

The side to move is eligible to offer while playing if the stake is below 64 and the next doubler is absent or is that side. This includes the opening turn and turns in check. No rule limits doubling by the match score.

A game that ends awards its stake to the winner, or half its stake to each colour on a draw, and adds the award to the match score. The game ends in match over when, with the award added, either total is 15 or more; otherwise it ends in finished. In match over the higher total wins the match, and equal totals draw it. The match is under way in every state but match over.

| From | Event | Guard | To | Effect |
|---|---|---|---|---|
| playing | Select own piece | — | playing | Replace selection and mark its legal destinations. An invalid destination never moves a piece. |
| playing | Tap any other square | Piece selected; the square is neither an own piece nor a legal destination | playing | Clear the selection and its marked destinations. Keep position and turn. |
| playing | Tap legal destination | Promotion required | choosing promotion | Keep position and turn uncommitted. |
| choosing promotion | Cancel | — | playing | Keep original position and turn, with the pawn still selected and its legal destinations marked. |
| playing, choosing promotion | Complete move | Legal destination selected, promotion choice supplied if required | playing, awaiting first automatic answer, finished or match over | Save the new position and any capture with either an automatic chess ending and its award or a triggered automatic-double decision and its milestone changes. If play continues without a decision, hand off to the other colour. |
| awaiting first automatic answer | Continue or Stop | — | awaiting second automatic answer | Save the mover's answer without changing position, stake, or side to move. Turn the board to the other player without showing the first answer. |
| awaiting second automatic answer | Continue or Stop | Both choose Continue | playing | Save twice the old stake and clear the decision. Keep the position, side to move, and voluntary offer right. |
| awaiting second automatic answer | Continue or Stop | At least one chooses Stop | finished or match over | Clear the decision and save the result and award together at the old stake: the sole player choosing Continue wins, or both choosing Stop draw. Keep the position. |
| playing | Tap Offer double | Side to move is eligible | awaiting double response | Save the pending offer at once, without confirmation and without changing the position, turn or stake. Clear selection. The offer can't be withdrawn. |
| awaiting double response | Take | — | playing | Save twice the old stake, the responder as next doubler, and no pending offer together. Keep the position and turn. |
| awaiting double response | Decline | — | finished or match over | Save a win for the offerer by declined double, no pending offer and the old stake awarded to the offerer together. Keep the position and old stake. |
| playing | Confirm resignation or agreed draw | — | finished or match over | Record a loss for the side to move, or a draw, respectively, with its award to the match score. Cancelling changes nothing. |
| finished | Next game | — | playing | At once, without confirmation, replace the current game with the opening position, no result, a stake of one point, neither a named next doubler nor a pending decision, no captures for either colour, and both automatic milestones available. Keep the match score and the Automatic doubles setting. |
| playing, finished, match over | New match | Confirm replacement unless match over | playing | Replace the current game as for Next game, and set both totals to 0. Cancelling keeps the match. |
| any | Reopen | Saved game exists | playing, awaiting double response, awaiting first automatic answer, awaiting second automatic answer, finished or match over | Restore the last committed game and match score without checking for a new automatic double. Resume any pending automatic decision at the saved answer step, without revealing a saved first answer. Unfinished promotions are not committed changes. An ongoing save from before the cube opens at one point with either player eligible on their turn, without changing the position or turn. A save from before matches opens as the first game of a match: an ongoing game at 0 to 0, a finished game with a stake with its award as the score, and a finished game from before the cube at 0 to 0. A save from before captures opens with no captures for either colour, without changing anything else. |

**Automatic doubles.** With the switch on, check the resulting position only when completing a legal move, including any promotion, and only if the game continues. No check on reopening, toggling the switch or answering a voluntary offer. Turning the switch on in an existing game uses the same check on its next completed move; do not replay past positions or infer past milestones. With the switch off, do not check automatic milestones or present a new automatic decision.

- **Opening milestone:** At least six of the eight knight and bishop starting squares no longer hold a piece of the starting colour and kind for that square. A matching piece on the square counts as not cleared, regardless of which piece moved there. Castling is not required.
- **Endgame milestone:** At most four pieces other than kings and pawns remain across both colours. Count promoted pieces as their current kinds.
- Check the available endgame milestone first. If met, consume it and retire the opening milestone if it is still available; otherwise, if the available opening milestone is met, consume it. A used or retired milestone never re-arms in that game. Neither milestone guarantees a prompt: at a stake of 64, skip it and continue. At 32, the proposed stake is 64.
- A triggered automatic double pauses play before the next player can move or offer a voluntary double. Only one doubling decision can be pending. Both kinds use the current stake and the same cap; there is no cooldown after a voluntary take and no limit based on the match score. An automatic double does not transfer the right to offer a voluntary double.
- Finish a pending decision before changing the switch. A switch change never reverses a stake or points already awarded. A failed save leaves the last committed step intact: only show a move, answer, stake increase, result or award as recorded after saving it.

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
| Automatic double decision | Board | awaiting first or second automatic answer | The board stays visible and faces the named responder. Only Continue and Stop are available. |

## Component roles

| Element | Role | Meaning | Content and behaviour |
|---|---|---|---|
| Board.position | chessboard | Play surface | 64 squares; each labelled by coordinate and occupant, with selection and legal destination conveyed without relying on colour alone. During either kind of doubling decision, put the responder's pieces at the bottom instead of the side to move's and accept no board moves. |
| Board.status | game-status | Turn, responder or final result | Announce turn and check when applicable, who must answer a pending doubling decision, or the outcome including reason and any point award. In match over, also the match result. Keep final board visible and no longer playable. |
| Board.stake | game-stake | Points in play and right to offer | Show the stake and who holds the right to offer during play, even when it is not that player's turn. During either kind of doubling decision, show the current stake alongside the decision's consequences. |
| Board.score | match-score | Points each colour has in the match, and the target | Show White's and Black's totals and the target in every state, including during a double response and in match over. No game number and no list of earlier games. |
| Board.captures | captured-pieces | Opponent's pieces each colour has taken in this game | In every state, show each colour's captures at that colour's edge of the board, so they move with the board when it turns, grouped by kind in the order pawn, knight, bishop, rook, queen with a count. A kind with one piece shows its icon alone; ×N is shown from 2 up, and the announced text keeps the count, such as “1 knight”. Each collection is named by its colour and announced as text, not by piece icons alone. Reflects only committed moves. |
| Board.material | material-advantage | Which colour has more material on the board, and by how much | In every state, show +N beside the captures of the colour ahead in material, from the committed position, directly after its last captured piece in the same row rather than at the far edge, and nothing when material is equal. Never in point units and never placed or worded as part of the stake or match score. |
| Board.automaticDoubles | switch | Control the experimental automatic-doubling rule | A visible switch on the game panel while playing or finished, available in every build; show its current setting. It is not actionable while a doubling decision is pending. |
| Board.actions | game-actions | Manage the current game and match | New match is available outside dialogs except during a pending doubling decision. Next game only in finished. In match over, New match is the only action. Resign and agree draw only while playing. Confirm an agreed draw on behalf of both people at the board. Offer double is actionable only for an eligible side to move. |
| Double response.actions | double-choice | Resolve the offer | Name the responder and explain the point consequences of Take and Decline alongside the two actions, including when declining ends the match. |
| Automatic double decision.actions | two-player double choice | Decide whether to continue at twice the stake | Give both colours the same choices and explanation, name the responder, and show the current and proposed stakes. Each answer commits without confirmation, cancellation or backtracking. Go straight from the first answer to the second prompt, without revealing the first answer or adding a handover step; resolve after the second answer without an acknowledgement step. |
| Promotion.options | piece-choice | Complete promotion | Queen, rook, bishop or knight of the mover's colour. |

## Interface text

| Key | Text | Notes |
|---|---|---|
| turn / check | {side} to move / {side} to move · Check | Side is White or Black. |
| square | {coordinate}, {occupant} | Empty or colour and piece name; coordinate independent of orientation. |
| selection / destination | Selected / Legal destination | Square states. |
| win | {winner} wins · {reason} | Checkmate, Resignation, Double declined or Opponent stopped at automatic double. |
| draw | Draw · {reason} | Stalemate, Insufficient material, Agreement or Both stopped at automatic double. |
| stake | Stake: {stake} | Include point units. |
| doubleRight | Either player can offer / Only {next doubler} can offer / Maximum stake reached | Right to offer on one's own turn. |
| offer | Offer double | Makes the offer at once, without confirmation. |
| automaticDoubles | Automatic doubles | Label for the testing switch. |
| automaticResponse | {responder}, continue at {proposed stake}? | Show the current stake as well. Include point units; responder is White or Black. |
| automaticContinue / automaticStop | Continue / Stop | Stop is not a resignation. |
| automaticEffects | If both continue, play for {proposed stake}. If only one continues, they win {current stake}. If both stop, it’s a draw and each earns {half current stake}. | Show the same explanation to both players. Include point units. |
| response | {responder}, answer the double | Responder is White or Black. |
| take / decline | Take / Decline | Actions for the responder. |
| takeEffect | Take: play for {doubled stake}. | Include point units. |
| declineEffect / declineEffectMatch | Decline: {offerer} wins {stake}. / Decline: {offerer} wins {stake} and the match. | Include point units. Offerer is White or Black. The second when the offerer's total with the old stake added is 15 or more. |
| winAward / drawAward | {winner} earns {stake}. / Each player earns {half stake}. | Include point units. Show half a point as ½ point and announce it as “half a point.” |
| matchScore | White {White total} · Black {Black total} · first to 15 | Include point units on each total and the target. Show a half as ½ after the whole number, as in 4½ points, or ½ point alone, and announce it as “and a half”, or “half a point” alone. |
| matchWin / matchDraw | {winner} wins the match, {winner's total} to {loser's total} / Match drawn, {total} to {total} | Shown with the game's result and award in match over. Totals without units, with halves as in matchScore. |
| captures / noCaptures | Captured by {side}: {pieces} / Captured by {side}: none | Side is White or Black. Pieces are counts and kinds in the order pawn, knight, bishop, rook, queen, such as “2 pawns, 1 knight”. Piece icons may stand in visually; the text is what's announced. |
| advantage | +{N} | Beside the leading side's captures. Announce as “{side} ahead by {N} in material”. No point units. |
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
- Differs, not decided: after a failed game save Android disables the switch until a game change is saved; after a failed switch save it disables game actions until the switch is saved (storage failure; #71).
- Differs, not decided: iOS and Android: when the saved game can’t be read and the confirmed New match then can’t be saved, iOS shows "Couldn’t open the saved game." and "Change not saved.", each with its own Retry, while Android shows only "Change not saved.", whose Retry saves the new match again. Neither shows a board or turn, and the saved file is untouched (behind a failed read and a failed save together; #2).

## Non-goals

Tablet support is outside the playtest scope; this does not block Android installations on tablets. No clock, computer opponent, undo, saved-game list, remote play, separate plain-chess mode, single game outside a match, or currency. No choice of target, tiebreaker, Crawford rule or other limit on doubling by the match score, swapping colours between games, game number or list of earlier games. No way to end a game except by its own endings; New match replaces the whole match. No tournament claim controls or automatic repetition/move-count adjudication; players may agree a draw. No move list, captures carried across games, evaluation beyond counting material, or option to hide captures or material. No automatic-double tutorial, progress cue, advance warning, or explanation of which threshold fired. No privacy mechanism for answering on the shared phone, remote configuration, rollout framework, or separate game mode.

## Links to other features

None

## Acceptance criteria

- **C1.** When opening without a game, the players shall see the standard opening position with White at the bottom and White to move. On reopening a game they shall see the last committed position, turn or result, with the same legal continuations. If the app is ended while a change is saving, then the app shall reopen on the saved game as it was before or after that change, never part of either (simplifications, #5 and #6). On Android, ending the app also drops a selection or an open dialog (simplification, #6).
- **C2.** While playing, the player shall be able to tap or reselect an own piece, see only its legal destinations, and commit by tapping one, including castling and en passant; promotion requires choosing a piece before commitment. An illegal move shall leave position and turn unchanged. If a tap can't be used, then on iOS the app shall leave position and turn unchanged, with no message (simplification, #5).
- **C3.** After a move that continues play without triggering an automatic double, the board shall put the next player's pieces at the bottom, identify their turn and any check, and accept their move immediately without confirmation, a ready screen or take-back.
- **C4.** When an automatic ending occurs or the players confirm resignation or a draw, the board shall show the final position, result and reason and stop accepting moves. While the saved game is loading or a change is saving, on Android the app shall not offer New match or Next game and shall ignore taps, without showing progress (simplification, #6).
- **C5.** If the current game cannot be read or a change cannot be saved, the app shall preserve the last saved game, identify what failed and not present a fresh game or an unsaved change as committed. Each failure is named without its cause. If the app is ended after a failed save, then the unsaved change is lost without notice and the last saved game reopens (simplifications, #5 and #6).
- **C6.** When starting a game or reopening an ongoing game saved before the cube, the players shall see a stake of one point and that either player can offer. While playing, the board shall show the stake and who has the right to offer, and allow Offer double only for the eligible side to move, including on the opening turn or in check, but never at 64 points.
- **C7.** When a player taps Offer double, the app shall make the offer at once, without confirmation. While awaiting a response to an offer, including on reopening, the board shall face the named responder, show the unchanged position and the point consequences of taking or declining, and accept no game action other than Take or Decline.
- **C8.** When the responder takes, the board shall face the offerer again and let them move from the same position, at twice the old stake. Only the taker shall have the right to offer the next double, on a later turn of theirs and below the maximum stake.
- **C9.** When the responder declines, the app shall end the game without a move and show the offerer winning by declined double at the old stake. For a finished game with a stake, the final board shall show the winner awarded the stake or, on a draw, each player awarded half, including ½ point each at a stake of one. A game saved before the cube that was already finished shall still show its original result without a point award.
- **C10.** The board shall show White's and Black's match totals and the target of 15 points in every state, including during a double response and after the match ends, starting at 0 to 0 in a new match. When a game ends, the app shall add its award to the totals, saved with the game's result, so that reopening shows the same totals.
- **C11.** When a game ends with both totals below 15, the board shall offer Next game. When the players tap it, the app shall start the next game at once, without confirmation, in the opening position with White at the bottom and White to move, at a stake of one point that either player can offer, and keep the totals.
- **C12.** When a game ends with either total at 15 or more, the board shall show the match result with the game's result and award, such as "White wins the match, 16 to 9" or "Match drawn, 15 to 15", the higher total winning and equal totals drawing. New match shall then be the only action, and start a new match at 0 to 0 without confirmation.
- **C13.** While a match is under way, New match shall ask for confirmation, and on confirmation replace the current game and the totals with a fresh game at 0 to 0; cancelling changes nothing. New match shall not be available during either kind of doubling decision.
- **C14.** When declining a pending offer would give the offerer 15 points or more, the double response shall say that the offerer wins the match by the decline, such as "Decline: White wins 4 points and the match."
- **C15.** When reopening a game saved before matches, the app shall show it as the first game of a match: an ongoing game at 0 to 0, a finished game with a stake with its award as the totals, and a finished game from before the cube at 0 to 0. Once that game has finished, the board shall offer Next game, or the match result if a total has reached 15.
- **C16.** In every state, including during a double response, a finished game and match over, the board shall show the pieces each player has captured in this game at that player's edge of the board, moving with them when the board turns. When a capturing move is committed, including en passant or a capture of a promoted piece, the piece that stood on the captured square shall join the mover's captures, saved with the move, and reopening shall show the same captures. A fresh game, by Next game or New match, shall start with no captures, and a game saved before captures shall open with none.
- **C17.** In every state, the board shall show +N beside the player with more material on the board, N being the difference between the players' totals of pawn 1, knight 3, bishop 3, rook 5 and queen 9, kings excluded, and no number when material is equal. A promotion shall change the balance when it is committed, whether or not it captures. VoiceOver and TalkBack shall announce each player's captures by colour, kind and count, and the advantage by colour and amount, without point units and apart from the stake and match score.
- **C18.** On a phone, the app shall stay in portrait when the phone is rotated, and the players shall still be able to play. The board shall still turn to face the appropriate player as play proceeds.
- **C19.** The game panel shall show an Automatic doubles switch in every build, off on a fresh install. Changing it shall not require a new build, and its setting shall persist across app restarts and updates. A pending doubling decision shall be completed before changing the switch. With the switch off, voluntary doubling and match rules shall still work as specified above.
- **C20.** The app shall read the current switch setting when checking for an automatic double, including in an existing or ongoing game. Off shall prevent new automatic-double decisions; on shall use the normal trigger logic without replaying past positions. A decision already presented shall be completed, and changing the switch shall not reverse a stake or points already awarded.
- **C21.** With automatic doubles on, only a completed legal move that does not end the game shall trigger a decision from the resulting position, at the opening or endgame thresholds above. Each milestone shall be used at most once per game; the endgame milestone shall take precedence and retire any unused opening milestone. Reopening, toggling the switch, or completing a voluntary response shall not itself trigger a decision.
- **C22.** At a triggered automatic double, the board shall pause play, face and name the mover first and then the other player, and show both the same Continue and Stop choices, stakes and consequences. No other game action shall be available. Each answer shall commit without confirmation, cancellation or backtracking. The second prompt shall not reveal the first answer or require a separate handover step. The prompt shall explain the choices, not which position threshold fired.
- **C23.** The second answer shall resolve immediately. If both choose Continue, play shall resume in the unchanged position with the same side to move at twice the stake. If exactly one chooses Continue, they shall win the old stake; if both choose Stop, draw and award half the old stake to each. Apply the existing match result rules, including a 15–15 draw if the score was 14–14 and both stop at a stake of two.
- **C24.** Automatic and voluntary doubles shall share the current stake and the 64-point cap. A taken voluntary double shall not delay a later automatic decision; an automatic double shall not change who has the right to offer a voluntary double. At 32, an automatic double may take the stake to 64; at 64 it shall not prompt. Neither the match score nor an automatic-doubling setting change shall alter voluntary doubling rights.
- **C25.** The app shall save a triggering move and its pending automatic decision together, save the first answer before showing the second prompt, and save the second answer's resolution with the new stake or the result and match award. Reopening after a save or interruption shall restore only the last committed step with used or retired milestones still spent and any first answer not revealed. A save from before automatic doubling shall reopen without changing its position, turn, stake, result, match score or pending voluntary offer; any subsequent automatic check uses the current setting and position.
