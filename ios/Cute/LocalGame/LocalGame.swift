import Observation

/// The one pass-and-play game on this device, and the actions the board offers on it.
@Observable
final class LocalGame {
    enum Failure: Equatable {
        /// The saved game couldn't be read; nothing is playable until a retry succeeds.
        case read
        /// The last change wasn't saved; the board still shows the last saved game.
        case write
    }

    private let store: GameStore

    /// The last committed position.
    private(set) var position: Position = .opening
    private(set) var result: GameResult?
    private(set) var failure: Failure?
    /// The selected piece's square; never saved.
    private(set) var selection: Square?

    /// Where the selected piece can legally move.
    var legalDestinations: Set<Square> {
        guard let selection else { return [] }
        return Set(position.legalMoves(from: selection).map(\.to))
    }

    init(store: GameStore) {
        self.store = store
    }

    /// Reads the current game, or starts the opening position when none is saved.
    /// A saved position the rules have already ended opens with that result.
    func open() {
        do {
            let saved = try store.load() ?? .opening
            position = saved.position
            result = saved.result ?? saved.position.automaticResult
            failure = nil
        } catch {
            failure = .read
        }
    }

    /// A tap on a board square: selects an own piece, or moves the selected one to a legal destination.
    func tap(_ square: Square) {
        guard result == nil, failure != .read, !isChoosingPromotion else { return }
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

    private func play(_ move: Move) {
        let next = position.applying(move)
        commit(SavedGame(position: next, result: next.automaticResult))
    }

    /// Whether the side to move is in check while the game is still being played.
    var isInCheck: Bool { result == nil && position.isInCheck(position.sideToMove) }

    var canResignOrAgreeDraw: Bool { result == nil && failure != .read }

    /// Whether starting over abandons a game still in play, or a saved game that couldn't be read.
    var newGameNeedsConfirmation: Bool { result == nil || failure == .read }

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

    private func clearSelection() {
        selection = nil
        promotionMove = nil
    }

    /// A pawn's move to the last rank, waiting for the player to choose its new piece; never saved.
    private var promotionMove: Move?

    var isChoosingPromotion: Bool { promotionMove != nil }

    func choosePromotion(_ kind: PieceKind) {
        guard var move = promotionMove, PieceKind.promotionChoices.contains(kind) else { return }
        move.promotion = kind
        clearSelection()
        play(move)
    }

    /// Leaves the position and turn as they were before the promotion destination was tapped.
    func cancelPromotion() {
        clearSelection()
    }

    /// A change that failed to save, kept so Retry can try it again. Never shown as the saved game.
    private var unsavedChange: SavedGame?

    /// Saves a change, and shows it only once it is saved.
    private func commit(_ game: SavedGame) {
        do {
            try store.save(game)
        } catch {
            unsavedChange = game
            failure = .write
            return
        }
        unsavedChange = nil
        position = game.position
        result = game.result
        failure = nil
    }

    /// Tries the failed operation again: reading the saved game, or saving the last change.
    func retry() {
        switch failure {
        case .read:
            open()
        case .write:
            if let unsavedChange { commit(unsavedChange) }
        case nil:
            break
        }
    }
}
