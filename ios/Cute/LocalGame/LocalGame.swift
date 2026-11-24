import Observation

/// The one pass-and-play game on this device, and the actions the board offers on it.
@Observable
final class LocalGame {
    private let store: GameStore

    /// The last committed position. Not a game to show while `couldNotReadSavedGame`.
    private(set) var position: Position = .opening
    private(set) var result: GameResult?
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

    /// A game is on the board and still being played.
    var isInPlay: Bool { result == nil && !couldNotReadSavedGame }

    /// Where the selected piece can legally move.
    var legalDestinations: Set<Square> {
        guard let selection else { return [] }
        return Set(position.legalMoves(from: selection).map(\.to))
    }

    /// Whether the side to move is in check while the game is still being played.
    var isInCheck: Bool { result == nil && position.isInCheck(position.sideToMove) }

    var canResignOrAgreeDraw: Bool { isInPlay }

    /// Whether starting over abandons a game still in play, or a saved game that couldn't be read.
    var newGameNeedsConfirmation: Bool { result == nil || couldNotReadSavedGame }

    var isChoosingPromotion: Bool { promotionMove != nil }

    /// Reads the current game, or starts the opening position when none is saved.
    /// A saved position the rules have already ended opens with that result.
    func open() {
        do {
            let saved = try store.load() ?? .opening
            position = saved.position
            result = saved.result ?? saved.position.automaticResult
            couldNotReadSavedGame = false
            unsavedChange = nil
        } catch {
            couldNotReadSavedGame = true
        }
    }

    /// A tap on a board square: selects an own piece, or moves the selected one to a legal destination.
    /// Any other square clears the selection.
    func tap(_ square: Square) {
        guard isInPlay, !isChoosingPromotion else { return }
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
        commit(SavedGame(position: position, result: .win(position.sideToMove.opponent, .resignation)))
    }

    /// Records a draw both players agreed at the board. The board asks for confirmation first.
    func agreeDraw() {
        guard canResignOrAgreeDraw else { return }
        clearSelection()
        commit(SavedGame(position: position, result: .draw(.agreement)))
    }

    /// Replaces the current game with the opening position. The board confirms first while still playing,
    /// and after a failed read, when this replaces the saved game that couldn't be read.
    func newGame() {
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

    private func play(_ move: Move) {
        let next = position.applying(move)
        commit(SavedGame(position: next, result: next.automaticResult))
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
    }
}
