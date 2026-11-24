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

    /// What a finished game awards: nothing while it is played, or for a game finished before the cube.
    var award: PointAward? {
        guard !couldNotReadSavedGame, let stake else { return nil }
        return switch result {
        case let .win(winner, _): .win(winner, stake)
        case .draw: .split(stake)
        case nil: nil
        }
    }

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

    /// New game is offered at any time except while an offer waits for its answer.
    var canStartNewGame: Bool { !isAwaitingDoubleResponse }

    /// Whether starting over abandons a game still in play, or a saved game that couldn't be read.
    var newGameNeedsConfirmation: Bool { result == nil || couldNotReadSavedGame }

    var isChoosingPromotion: Bool { promotionMove != nil }

    /// Whether the side to move may offer to double the stake now (`SavedGame.sideToMoveMayOffer`).
    var canOfferDouble: Bool { isAwaitingMove && committed.sideToMoveMayOffer }

    /// Reads the current game, or starts the opening position when none is saved.
    /// A saved position the rules have already ended opens with that result. Nothing is saved until a change.
    func open() {
        do {
            let saved = try store.load() ?? .opening
            position = saved.position
            result = saved.result ?? saved.position.automaticResult
            // An ongoing game saved before the cube is played on at one point; a finished one awards nothing.
            stake = saved.stake ?? (result == nil ? 1 : nil)
            nextDoubler = saved.nextDoubler
            doublePending = saved.doublePending
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
        var change = committed
        change.result = .win(position.sideToMove.opponent, .resignation)
        commit(change)
    }

    /// Records a draw both players agreed at the board. The board asks for confirmation first.
    func agreeDraw() {
        guard canResignOrAgreeDraw else { return }
        clearSelection()
        var change = committed
        change.result = .draw(.agreement)
        commit(change)
    }

    /// Saves the side to move's offer to double the stake, leaving position, turn and stake as they were.
    /// The board asks for confirmation first.
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
        var change = committed
        change.result = .win(position.sideToMove, .doubleDeclined)
        change.doublePending = false
        commit(change)
    }

    /// Replaces the current game with the opening position, at one point. The board confirms first while
    /// still playing, and after a failed read, when this replaces the saved game that couldn't be read.
    func newGame() {
        guard canStartNewGame else { return }
        clearSelection()
        commit(.opening)
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
                  doublePending: doublePending)
    }

    private func play(_ move: Move) {
        var change = committed
        change.position = position.applying(move)
        change.result = change.position.automaticResult
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
    }
}
