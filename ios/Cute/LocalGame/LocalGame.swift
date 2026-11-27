import Observation

/// The one pass-and-play game on this device, and the actions the board offers on it.
@Observable
final class LocalGame {
    private let store: GameStore

    /// The last committed position. Not a game to show while `couldNotReadSavedGame`.
    private(set) var position: Position = .opening
    private(set) var result: GameResult?
    /// The points this game is played for. Nil only for a game finished before the cube, which awards none.
    private(set) var stake: Int? = 1
    /// The side that took the last double and alone may offer the next; nil while either side may.
    private(set) var nextDoubler: PieceColor?
    /// The side to move offered a double, and the other side hasn't yet taken or declined it.
    private var doublePending = false
    /// White's and Black's totals in this match, including this game's award once it has finished.
    private(set) var score: MatchScore = .zero
    /// The opponent's pieces each colour has captured in this game, as last committed.
    private(set) var captures: Captures = .empty
    /// The saved game couldn't be read, and no game has been read or saved since.
    /// Nothing is playable and no board is shown until it is read or replaced.
    private(set) var couldNotReadSavedGame = false
    /// A change that failed to save, kept so Retry can save it again. Never shown as the saved game.
    private var unsavedChange: SavedGame?
    /// The selected piece's square; never saved.
    private(set) var selection: Square?
    /// A pawn's move to the last rank, waiting for the player to choose its new piece; never saved.
    private var promotionMove: Move?

    init(store: GameStore) {
        self.store = store
    }

    /// The last change wasn't saved; any board shown is still the last saved game.
    var hasUnsavedChange: Bool { unsavedChange != nil }

    /// A game is on the board and still being played, including while an offer waits for its answer.
    var isInPlay: Bool { result == nil && !couldNotReadSavedGame }

    /// An offer waits for the responder: the board accepts nothing but Take or Decline.
    var isAwaitingDoubleResponse: Bool { isInPlay && doublePending }

    /// The side that answers a pending offer: the other side from the offerer, who is the side to move.
    var responder: PieceColor { position.sideToMove.opponent }

    /// The side whose pieces the board puts at the bottom: the side to move, or the responder while an offer
    /// waits for its answer. Which way the board faces never changes whose move it is.
    var sideAtBottom: PieceColor { isAwaitingDoubleResponse ? responder : position.sideToMove }

    /// What a finished game awards: nothing while it is played, or for a game finished before the cube.
    var award: PointAward? {
        guard !couldNotReadSavedGame else { return nil }
        return committed.award
    }

    /// The game has finished with either total at the target or past it: the match is over, and New match
    /// is the only action.
    var isMatchOver: Bool { !couldNotReadSavedGame && result != nil && score.reachesTarget }

    /// The colour with the higher total once the match is over, or nil when the totals are equal and it is drawn.
    var matchWinner: PieceColor? { score.leader }

    /// Next game is offered once a game has finished with both totals below the target.
    var canStartNextGame: Bool { !couldNotReadSavedGame && result != nil && !isMatchOver }

    /// A game is in play and no offer is waiting, so the side to move can move, resign, agree a draw or offer.
    private var isAwaitingMove: Bool { isInPlay && !doublePending }

    /// Where the selected piece can legally move.
    var legalDestinations: Set<Square> {
        guard let selection else { return [] }
        return Set(position.legalMoves(from: selection).map(\.to))
    }

    /// Whether the side to move is in check while the game is still being played.
    var isInCheck: Bool { result == nil && position.isInCheck(position.sideToMove) }

    var canResignOrAgreeDraw: Bool { isAwaitingMove }

    /// New match is offered at any time except while an offer waits for its answer.
    var canStartNewMatch: Bool { !isAwaitingDoubleResponse }

    /// Whether starting over abandons a match still under way, or a saved game that couldn't be read.
    var newMatchNeedsConfirmation: Bool { !isMatchOver }

    /// Declining the pending offer would take the offerer's total, with the stake added, to the target or past it.
    var declineEndsMatch: Bool {
        guard isAwaitingDoubleResponse, let stake else { return false }
        return score[position.sideToMove] + Points(stake) >= MatchScore.target
    }

    var isChoosingPromotion: Bool { promotionMove != nil }

    /// The colour ahead in material on the committed position, and by how much; nil when material is equal.
    /// A promotion still being chosen isn't committed, so it doesn't count.
    var materialLead: MaterialLead? { MaterialLead(in: position) }

    /// Whether the side to move may offer to double the stake now (`SavedGame.sideToMoveMayOffer`).
    var canOfferDouble: Bool { isAwaitingMove && committed.sideToMoveMayOffer }

    /// Reads the current game, or starts the first game of a match when none is saved.
    /// A saved position the rules have already ended opens with that result, and its award added to the totals.
    /// Nothing is saved until a change.
    func open() {
        do {
            var saved = try store.load() ?? .opening
            if saved.result == nil, let automaticResult = saved.position.automaticResult {
                saved = saved.ending(with: automaticResult)
            }
            position = saved.position
            result = saved.result
            // An ongoing game saved before the cube is played on at one point; a finished one awards nothing.
            stake = saved.stake ?? (result == nil ? 1 : nil)
            nextDoubler = saved.nextDoubler
            doublePending = saved.doublePending
            score = saved.score
            captures = saved.captures
            couldNotReadSavedGame = false
            unsavedChange = nil
        } catch {
            couldNotReadSavedGame = true
        }
    }

    /// A tap on a board square: selects an own piece, or moves the selected one to a legal destination.
    /// Any other square clears the selection.
    func tap(_ square: Square) {
        guard isAwaitingMove, !isChoosingPromotion else { return }
        if position[square]?.color == position.sideToMove {
            selection = square
            return
        }
        guard let selection,
              let move = position.legalMoves(from: selection).first(where: { $0.to == square })
        else {
            self.selection = nil
            return
        }
        if move.promotion != nil {
            promotionMove = move
        } else {
            self.selection = nil
            play(move)
        }
    }

    func choosePromotion(_ kind: PieceKind) {
        guard var move = promotionMove, PieceKind.promotionChoices.contains(kind) else { return }
        move.promotion = kind
        clearSelection()
        play(move)
    }

    /// Leaves the position and turn as they were before the promotion destination was tapped,
    /// with the pawn still selected and its legal destinations marked.
    func cancelPromotion() {
        promotionMove = nil
    }

    /// Records a loss for the side to move. The board asks for confirmation first.
    func resign() {
        guard canResignOrAgreeDraw else { return }
        clearSelection()
        commit(committed.ending(with: .win(position.sideToMove.opponent, .resignation)))
    }

    /// Records a draw both players agreed at the board. The board asks for confirmation first.
    func agreeDraw() {
        guard canResignOrAgreeDraw else { return }
        clearSelection()
        commit(committed.ending(with: .draw(.agreement)))
    }

    /// Saves the side to move's offer to double the stake, leaving position, turn and stake as they were.
    /// The offer can't be withdrawn.
    func offerDouble() {
        guard canOfferDouble else { return }
        clearSelection()
        var change = committed
        change.doublePending = true
        commit(change)
    }

    /// The responder takes the pending offer: the game goes on from the same position, with the offerer
    /// to move, at twice the stake, and only the taker may offer the next double.
    func takeDouble() {
        guard isAwaitingDoubleResponse, let stake else { return }
        var change = committed
        change.stake = stake * 2
        change.nextDoubler = responder
        change.doublePending = false
        commit(change)
    }

    /// The responder declines the pending offer: the game ends without a move, and the offerer wins
    /// the stake as it was before the offer.
    func declineDouble() {
        guard isAwaitingDoubleResponse else { return }
        commit(committed.ending(with: .win(position.sideToMove, .doubleDeclined)))
    }

    /// Replaces the current game and the totals with the opening position, at one point and no points each.
    /// The board confirms first while the match is under way, and after a failed read, when this replaces the
    /// saved game that couldn't be read.
    func newMatch() {
        guard canStartNewMatch else { return }
        clearSelection()
        commit(.opening)
    }

    /// Starts the match's next game at once, in the opening position at one point, keeping the totals.
    func nextGame() {
        guard canStartNextGame else { return }
        clearSelection()
        var next = SavedGame.opening
        next.score = score
        commit(next)
    }

    /// Tries saving the change that failed to save again.
    func retrySave() {
        if let unsavedChange { commit(unsavedChange) }
    }

    /// Tries reading the saved game again. Once it reads, any change still waiting to be saved is dropped.
    func retryRead() {
        guard couldNotReadSavedGame else { return }
        open()
    }

    /// The game as last committed, the base for the next change.
    private var committed: SavedGame {
        SavedGame(position: position, result: result, stake: stake, nextDoubler: nextDoubler,
                  doublePending: doublePending, score: score, captures: captures)
    }

    private func play(_ move: Move) {
        var change = committed
        if let captured = position.capturedPiece(by: move) {
            change.captures[position.sideToMove].append(captured.kind)
        }
        change.position = position.applying(move)
        if let result = change.position.automaticResult {
            change = change.ending(with: result)
        }
        commit(change)
    }

    private func clearSelection() {
        selection = nil
        promotionMove = nil
    }

    /// Saves a change, and shows it only once it is saved.
    /// A failed save leaves an unread saved game unread, so no board is offered in its place.
    private func commit(_ game: SavedGame) {
        do {
            try store.save(game)
        } catch {
            unsavedChange = game
            return
        }
        unsavedChange = nil
        couldNotReadSavedGame = false
        position = game.position
        result = game.result
        stake = game.stake
        nextDoubler = game.nextDoubler
        doublePending = game.doublePending
        score = game.score
        captures = game.captures
    }
}
