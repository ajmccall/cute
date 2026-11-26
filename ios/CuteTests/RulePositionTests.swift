import Foundation
import Testing
@testable import Cute

/// Rule positions driven through the local-game boundary, each from an isolated saved position.
@Suite struct RulePositionTests {
    @Test func aPinnedPieceHasNoLegalDestinations() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: "4k3/4r3/8/8/8/8/4B3/4K3 w - -", in: storage)

        game.tap("e2")

        #expect(game.selection == Square("e2"))
        #expect(game.legalDestinations.isEmpty)
    }

    @Test func kingCanCastleOnBothSidesAndTheRookMovesWithIt() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: "r3k2r/8/8/8/8/8/8/R3K2R w KQkq -", in: storage)

        game.tap("e1")
        #expect(game.legalDestinations == squares("d1", "d2", "e2", "f2", "f1", "c1", "g1"))

        game.tap("g1")
        #expect(game.position.fen == "r3k2r/8/8/8/8/8/8/R4RK1 b kq -")

        game.tap("e8")
        game.tap("c8")
        #expect(game.position.fen == "2kr3r/8/8/8/8/8/8/R4RK1 w - -")
    }

    @Test(arguments: [
        // Castling through an attacked square (f1), but the queenside is clear.
        ("4kr2/8/8/8/8/8/8/R3K2R w KQ -", ["d1", "d2", "e2", "c1"]),
        // Castling out of check.
        ("4r1k1/8/8/8/8/8/8/R3K2R w KQ -", ["d1", "d2", "f2", "f1"]),
        // Castling into check (g1 attacked) and through a blocked queenside.
        ("4k1r1/8/8/8/8/8/8/RN2K2R w KQ -", ["d1", "d2", "e2", "f2", "f1"]),
        // No castling rights left.
        ("4k3/8/8/8/8/8/8/R3K2R w - -", ["d1", "d2", "e2", "f2", "f1"]),
    ])
    func kingCannotCastleWhereTheRulesForbid(fen: String, destinations: [String]) throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: fen, in: storage)

        game.tap("e1")

        #expect(game.legalDestinations == Set(destinations.map { Square($0)! }))
    }

    @Test func movingARookLosesThatSideOfCastlingEvenAfterReopening() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: "r3k2r/8/8/8/8/8/8/R3K2R w KQkq -", in: storage)

        game.tap("h1"); game.tap("h2")
        game.tap("a8"); game.tap("a7")
        game.tap("h2"); game.tap("h1")
        game.tap("a7"); game.tap("a8")

        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.position.castlingRights == [.whiteQueenside, .blackKingside])
        reopened.tap("e1")
        #expect(!reopened.legalDestinations.contains(Square("g1")!))
        #expect(reopened.legalDestinations.contains(Square("c1")!))
    }

    @Test func capturingARookOnItsSquareRemovesTheOpponentsCastlingRight() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: "r3k2r/8/8/8/8/8/8/R3K2R w KQkq -", in: storage)

        game.tap("a1"); game.tap("a8")

        #expect(game.position.castlingRights == [.whiteKingside, .blackKingside])
    }

    @Test func enPassantCapturesThePawnThatJustPassedAndSurvivesReopening() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: "4k3/8/8/8/3p4/8/4P3/4K3 w - -", in: storage)

        game.tap("e2"); game.tap("e4")
        #expect(game.position.fen == "4k3/8/8/8/3pP3/8/8/4K3 b - e3")

        let reopened = LocalGame(store: storage.store)
        reopened.open()
        reopened.tap("d4")
        #expect(reopened.legalDestinations == squares("d3", "e3"))

        reopened.tap("e3")
        #expect(reopened.position.fen == "4k3/8/8/8/8/4p3/8/4K3 w - -")
    }

    @Test func enPassantExpiresAfterOneMove() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: "4k3/8/8/8/3p4/8/4P3/4K3 w - -", in: storage)

        game.tap("e2"); game.tap("e4")
        game.tap("e8"); game.tap("f8")
        game.tap("e1"); game.tap("f1")
        game.tap("d4")

        #expect(game.legalDestinations == squares("d3"))
    }

    @Test func enPassantIsNotAllowedWhenItWouldExposeTheKing() throws {
        let storage = try TemporaryStorage()
        // Taking e3 en passant would clear the fourth rank between the black king and the white rook.
        let game = try openGame(at: "8/8/8/8/k2pP2R/8/8/4K3 b - e3", in: storage)

        game.tap("d4")

        #expect(game.legalDestinations == squares("d3"))
    }

    static let promotionPosition = "3r3k/4P3/8/8/8/8/8/K7 w - -"

    @Test func aPromotionWaitsForAChoiceAndCancellingChangesNothing() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: Self.promotionPosition, in: storage)

        game.tap("e7")
        #expect(game.legalDestinations == squares("e8", "d8"))
        game.tap("e8")
        #expect(game.isChoosingPromotion)
        #expect(game.position.fen == Self.promotionPosition)
        #expect(try storage.store.load()?.position.fen == Self.promotionPosition)

        game.cancelPromotion()
        #expect(!game.isChoosingPromotion)
        #expect(game.position.fen == Self.promotionPosition)
        #expect(game.selection == Square("e7"))
        #expect(game.legalDestinations == squares("e8", "d8"))
    }

    @Test(arguments: [
        (PieceKind.knight, "e8", "3rN2k/8/8/8/8/8/8/K7 b - -"),
        (.queen, "e8", "3rQ2k/8/8/8/8/8/8/K7 b - -"),
        (.rook, "d8", "3R3k/8/8/8/8/8/8/K7 b - -"),
        (.bishop, "d8", "3B3k/8/8/8/8/8/8/K7 b - -"),
    ])
    func choosingAPieceCompletesThePromotion(kind: PieceKind, destination: String, expected: String) throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: Self.promotionPosition, in: storage)

        game.tap("e7"); game.tap(destination)
        game.choosePromotion(kind)

        #expect(!game.isChoosingPromotion)
        #expect(game.position.fen == expected)
        #expect(try storage.store.load()?.position.fen == expected)
    }

    @Test func anUnfinishedPromotionIsNotAMoveAfterReopening() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: Self.promotionPosition, in: storage)
        game.tap("e7"); game.tap("e8")

        let reopened = LocalGame(store: storage.store)
        reopened.open()

        #expect(!reopened.isChoosingPromotion)
        #expect(reopened.position.fen == Self.promotionPosition)
    }
}

/// Opens a game from a saved position in its own temporary storage.
func openGame(at fen: String, result: GameResult? = nil, in storage: TemporaryStorage) throws -> LocalGame {
    var saved = SavedGame(position: try #require(Position(fen: fen)), result: nil)
    // A finished game's totals include its award.
    if let result { saved = saved.ending(with: result) }
    try storage.store.save(saved)
    let game = LocalGame(store: storage.store)
    game.open()
    try #require(game.hasNoFailure)
    return game
}
