import Foundation
import Testing
@testable import Cute

@Suite struct LocalGameTests {
    @Test func openingWithoutAGameShowsTheStandardOpeningWithWhiteToMove() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)

        game.open()

        #expect(game.position.fen == "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -")
        #expect(game.position.sideToMove == .white)
        #expect(game.result == nil)
        #expect(game.hasNoFailure)
    }

    @Test func selectingAnOwnPieceShowsOnlyItsLegalDestinationsAndCanBeChanged() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()

        game.tap("e2")
        #expect(game.selection == Square("e2"))
        #expect(game.legalDestinations == squares("e3", "e4"))

        game.tap("g1")
        #expect(game.selection == Square("g1"))
        #expect(game.legalDestinations == squares("f3", "h3"))
    }

    @Test(arguments: ["e7", "e4", "a8"])
    func tappingAnOpponentPieceOrEmptySquareSelectsNothing(square: String) throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()

        game.tap(square)

        #expect(game.selection == nil)
        #expect(game.legalDestinations.isEmpty)
    }

    @Test func tappingALegalDestinationCommitsAndSavesTheMoveForTheOtherSide() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()

        game.tap("g1")
        game.tap("f3")

        let afterMove = "rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R b KQkq -"
        #expect(game.position.fen == afterMove)
        #expect(game.selection == nil)
        #expect(game.hasNoFailure)

        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.position.fen == afterMove)
        #expect(reopened.result == nil)
        reopened.tap("e7")
        #expect(reopened.legalDestinations == squares("e6", "e5"))
    }

    @Test func aMoveThatGivesCheckIdentifiesTheCheckForTheNextPlayer() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: "4k3/8/8/8/8/8/8/R3K3 w - -", in: storage)
        #expect(!game.isInCheck)

        game.tap("a1"); game.tap("a8")

        #expect(game.position.sideToMove == .black)
        #expect(game.isInCheck)
        #expect(game.result == nil)
        game.tap("e8")
        #expect(game.legalDestinations == squares("d7", "e7", "f7"))
    }

    @Test func anIllegalDestinationLeavesPositionAndTurnUnchanged() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()

        game.tap("e2")
        game.tap("e5")

        #expect(game.position == .opening)
        #expect(try storage.store.load() == nil)
        #expect(game.selection == nil)
    }
}

func squares(_ coordinates: String...) -> Set<Square> {
    Set(coordinates.map { Square($0)! })
}

extension LocalGame {
    func tap(_ coordinate: String) {
        tap(Square(coordinate)!)
    }

    /// The saved game was read or saved, and no change is waiting to be saved.
    var hasNoFailure: Bool { !couldNotReadSavedGame && !hasUnsavedChange }
}
