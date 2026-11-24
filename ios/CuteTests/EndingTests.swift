import Foundation
import Testing
@testable import Cute

/// Automatic endings, resignation, agreed draws and new games, through the local-game boundary.
@Suite struct EndingTests {
    @Test func foolsMateEndsTheGameWithBlackWinningAndTheBoardStopsAcceptingMoves() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()

        game.tap("f2"); game.tap("f3")
        game.tap("e7"); game.tap("e5")
        game.tap("g2"); game.tap("g4")
        game.tap("d8"); game.tap("h4")

        let finalPosition = "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq -"
        #expect(game.result == .win(.black, .checkmate))
        #expect(game.position.fen == finalPosition)

        game.tap("e1")
        #expect(game.selection == nil)
        #expect(game.legalDestinations.isEmpty)

        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.result == .win(.black, .checkmate))
        #expect(reopened.position.fen == finalPosition)
        reopened.tap("a2")
        #expect(reopened.selection == nil)
    }

    @Test func stalemateIsADraw() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: "7k/4Q3/6K1/8/8/8/8/8 w - -", in: storage)

        game.tap("e7"); game.tap("f7")

        #expect(game.result == .draw(.stalemate))
        #expect(try storage.store.load()?.result == .draw(.stalemate))
    }

    /// Each position has the white king take a checking rook on d1, leaving the material named.
    @Test(arguments: [
        ("4k3/8/8/8/8/8/8/3rK3 w - -", true),          // kings alone
        ("4k3/8/8/8/8/8/8/N2rK3 w - -", true),         // one knight
        ("4k3/8/8/8/8/8/8/B2rK3 w - -", true),         // one bishop
        ("4k2b/8/8/8/8/8/8/B2rK3 w - -", true),        // bishops all on dark squares
        ("4k3/8/8/8/8/8/8/NN1rK3 w - -", false),       // two knights can't force mate, but it isn't a draw here
        ("4k3/7b/8/8/8/8/8/B2rK3 w - -", false),       // bishops on both colours
        ("4k3/8/8/8/8/8/P7/3rK3 w - -", false),        // a pawn
        ("4k3/8/8/8/8/8/8/R2rK3 w - -", false),        // a rook
    ])
    func insufficientMaterialIsADrawOnlyInTheStandardCases(fen: String, isDraw: Bool) throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: fen, in: storage)

        game.tap("e1"); game.tap("d1")

        #expect(game.result == (isDraw ? .draw(.insufficientMaterial) : nil))
    }

    @Test func resignationIsALossForTheSideToMove() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()
        game.tap("e2"); game.tap("e4")

        game.resign()

        #expect(game.result == .win(.white, .resignation))
        #expect(try storage.store.load()?.result == .win(.white, .resignation))
        game.tap("e7")
        #expect(game.selection == nil)
    }

    @Test func anAgreedDrawEndsTheGame() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()

        game.agreeDraw()

        #expect(game.result == .draw(.agreement))
        #expect(try storage.store.load()?.result == .draw(.agreement))
    }

    @Test func resigningOrAgreeingADrawDoesNothingOnceTheGameIsOver() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: "4k3/8/8/8/8/8/8/4K3 w - -", result: .draw(.insufficientMaterial), in: storage)

        game.resign()
        game.agreeDraw()

        #expect(game.result == .draw(.insufficientMaterial))
        #expect(!game.canResignOrAgreeDraw)
    }

    @Test func newGameStartsFreshAndAsksForConfirmationOnlyWhileStillPlaying() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()
        game.tap("e2"); game.tap("e4")
        #expect(game.newGameNeedsConfirmation)
        #expect(game.canResignOrAgreeDraw)

        game.resign()
        #expect(!game.newGameNeedsConfirmation)

        game.newGame()
        #expect(game.position == .opening)
        #expect(game.result == nil)
        #expect(try storage.store.load() == .opening)
        #expect(game.newGameNeedsConfirmation)
    }
}
