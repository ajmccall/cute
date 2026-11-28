# Chess phase transitions: position-based research

Research for [#63](https://github.com/ajmccall/cute/issues/63) and exploration [#62](https://github.com/ajmccall/cute/issues/62). This is evidence, not an approved rule, threshold, or schema. No move count is used as a trigger.

## What the chess sources say

The usual vocabulary is opening, middlegame, endgame, but the boundaries are judgments about the position, not crisp chess rules. Chess.com's instructional [opening](https://www.chess.com/terms/chess-openings) and [middlegame](https://www.chess.com/terms/chess-middlegame) explanations explicitly call the opening boundary subjective and say there is no solid definition of the endgame boundary. Their [endgame explanation](https://www.chess.com/terms/chess-endgame) describes most pieces having been exchanged, pawn promotion and a more active king; it also notes games may finish without an endgame. These are teaching descriptions, not a proven universal consensus or a detection specification.

### Opening to middlegame

Opening aims are developing pieces, controlling the centre and king safety ([opening](https://www.chess.com/terms/chess-openings)). Both sides' minor pieces largely deployed, kings sheltered, central pawns and piece activity are therefore observable clues. Chess.com's [middlegame discussion](https://www.chess.com/terms/chess-middlegame) considers both sides developed and castled a fairly safe indication, but says a middlegame can arise with incomplete development and players may never castle. Its examples also allow minor-piece development and castling while major pieces remain undeveloped.

**Ambiguity:** a piece off its original square is not necessarily active or developed; a piece on it may have returned or been replaced. A missing minor piece is not an undeveloped piece. A king on a castling destination does not establish that castling happened or that the king is safe. One side may be developed and the other not. Central pawn locations and attacked squares indicate structure and control, not whether either side has completed its opening aims. Book knowledge is player-dependent, not a board-only property ([middlegame](https://www.chess.com/terms/chess-middlegame)). Thus no single such feature is a necessary or sufficient phase boundary.

### Middlegame to endgame

Observable clues include remaining non-pawn material by side and type, queens present or absent, pawn structure and passed pawns, and kings' positions and safety. The strategic change is toward king activity and promotion when the remaining forces allow it, rather than merely a particular count ([endgame](https://www.chess.com/terms/chess-endgame)). The [middlegame explanation](https://www.chess.com/terms/chess-middlegame) explicitly notes queenless positions can still have several pieces and the point at which enough have been exchanged varies by observer.

Counterexamples:

- The [Berlin Defence](https://www.chess.com/openings/Ruy-Lopez-Opening-Berlin-Defense) describes its queen-exchange line as both a queenless middlegame and an unusual endgame. GM Kiril Georgiev's [Berlin endgame analysis](https://www.chess.com/blog/GrigorGrigorov/understand-the-berlin-endgame) discusses undeveloped rooks and opening preparation in the same position. Queen exchange alone can therefore put opening-development and ending vocabulary in tension; it cannot settle the boundary.
- [Queen-and-pawn endgames](https://www.chess.com/article/view/queen-endgames-q2p-vs-q) are endgames with queens still present, sometimes with perpetual-check danger. Neither queen absence nor a safely centralised king is necessary.
- A position may end by checkmate before an endgame ([endgame](https://www.chess.com/terms/chess-endgame)); it need not pass both observable boundaries. Promotion can add a queen or other non-pawn piece ([FIDE Laws, article 3.7.3](https://handbook.fide.com/chapter/e012023)), so remaining material and queen absence are not monotonic. Sudden exchanges can cross several heuristics in one move.

## What an engine example does—and does not show

A historical, pinned [Stockfish 2014 change](https://github.com/official-stockfish/Stockfish/commit/3b315c9adab141830a81afbdff70c18336763e51) computes a phase from the sum of both sides' non-pawn material, clamped at middlegame/endgame limits and interpolated between them. A later [Stockfish evaluation discussion](https://github.com/official-stockfish/Stockfish/pull/2371) shows interpolation between middlegame and endgame evaluation scores. This is an engine's evaluation device, not a chess-authority definition, opening detector, current-engine claim, or evidence that its limits are appropriate for a stake event. A continuous score discards positional details and asymmetry; forcing it into a single transition requires an additional arbitrary threshold.

## Implications for investigation, not decisions

Candidate position features to compare in future experiments are development and king shelter for the first boundary, and material composition together with king activity/safety and pawn structure for the second. Any composite, weighting, threshold or precedence is a **heuristic proposal**, not a conclusion of these sources. Validate against annotated positions spanning unequal development, early queen exchange, queen endgames, promotion and premature game endings, and report disagreements as well as agreement. A board snapshot cannot reconstruct all past events, and a position-based classification can fluctuate as pieces move or promote; deciding whether and how to remember an already observed transition is outside this research. Likewise handling simultaneous candidate transitions or no transition is unresolved. No product behavior is recommended here.
