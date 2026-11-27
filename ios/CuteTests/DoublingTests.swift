import Foundation
import Testing
@testable import Cute

/// The doubling cube through the local-game boundary, on the real file store in its own temporary folder.
@Suite struct DoublingTests {
    @Test func aFreshGameIsPlayedForOnePointAndEitherSideCanOffer() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()

        #expect(game.stake == 1)
        #expect(game.nextDoubler == nil)
        #expect(game.canOfferDouble)

        game.tap("e2"); game.tap("e4")
        #expect(game.canOfferDouble)
    }

    @Test func anOfferIsSavedWithTheSamePositionTurnAndStakeAndSurvivesReopening() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: Self.afterE4, in: storage)
        game.tap("e7")

        game.offerDouble()

        #expect(game.isAwaitingDoubleResponse)
        #expect(game.responder == .white)
        #expect(game.position.fen == Self.afterE4)
        #expect(game.stake == 1)
        #expect(game.selection == nil)

        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.hasNoFailure)
        #expect(reopened.isAwaitingDoubleResponse)
        #expect(reopened.responder == .white)
        #expect(reopened.position.fen == Self.afterE4)
        #expect(reopened.stake == 1)
    }

    @Test func whileAwaitingAResponseNoGameActionButTakeOrDeclineIsAccepted() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: Self.afterE4, in: storage)
        game.offerDouble()

        #expect(!game.canOfferDouble)
        #expect(!game.canResignOrAgreeDraw)
        #expect(!game.canStartNewMatch)
        game.tap("e7")
        #expect(game.selection == nil)
        game.tap("e2")
        #expect(game.selection == nil)
        game.offerDouble()
        game.resign()
        game.agreeDraw()
        game.newMatch()

        #expect(game.isAwaitingDoubleResponse)
        #expect(game.result == nil)
        #expect(game.position.fen == Self.afterE4)
        #expect(try storage.store.load() == SavedGame(position: try #require(Position(fen: Self.afterE4)), result: nil,
                                                      stake: 1, nextDoubler: nil, doublePending: true))
    }

    @Test func takingDoublesTheStakeAndTheOffererMovesFromTheSamePositionWhileOnlyTheTakerMayRedouble() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: Self.afterE4, in: storage)
        game.offerDouble()

        game.takeDouble()

        #expect(!game.isAwaitingDoubleResponse)
        #expect(game.stake == 2)
        #expect(game.nextDoubler == .white)
        #expect(game.position.fen == Self.afterE4)
        #expect(!game.canOfferDouble)
        game.tap("e7"); game.tap("e5")
        #expect(game.position.sideToMove == .white)
        #expect(game.canOfferDouble)
        game.tap("g1"); game.tap("f3")
        #expect(!game.canOfferDouble)

        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.stake == 2)
        #expect(reopened.nextDoubler == .white)
        #expect(!reopened.canOfferDouble)
    }

    @Test func aTakeAtThirtyTwoReachesTheMaximumStakeAndNeitherSideCanOfferAgain() throws {
        let storage = try TemporaryStorage()
        try storage.store.save(SavedGame(position: try #require(Position(fen: Self.afterE4)), result: nil,
                                         stake: 32, nextDoubler: .black))
        let game = LocalGame(store: storage.store)
        game.open()
        #expect(game.canOfferDouble)

        game.offerDouble()
        game.takeDouble()

        #expect(game.stake == 64)
        #expect(game.nextDoubler == .white)
        game.tap("e7"); game.tap("e5")
        #expect(game.position.sideToMove == .white)
        #expect(!game.canOfferDouble)
        game.offerDouble()
        #expect(!game.isAwaitingDoubleResponse)
    }

    @Test func anOfferCanBeMadeOnTheOpeningTurnAndInCheck() throws {
        let storage = try TemporaryStorage()
        let opening = LocalGame(store: storage.store)
        opening.open()
        opening.offerDouble()
        #expect(opening.isAwaitingDoubleResponse)
        #expect(opening.responder == .black)

        let checkStorage = try TemporaryStorage()
        let checked = try openGame(at: "R3k3/8/8/8/8/8/8/4K3 b - -", in: checkStorage)
        #expect(checked.isInCheck)
        #expect(checked.canOfferDouble)
        checked.offerDouble()
        #expect(checked.isAwaitingDoubleResponse)
        #expect(checked.responder == .white)
    }

    @Test func decliningEndsTheGameWithoutAMoveAndTheOffererWinsTheOldStake() throws {
        let storage = try TemporaryStorage()
        try storage.store.save(SavedGame(position: try #require(Position(fen: Self.afterE4)), result: nil,
                                         stake: 4, nextDoubler: .black))
        let game = LocalGame(store: storage.store)
        game.open()
        game.offerDouble()

        game.declineDouble()

        #expect(game.result == .win(.black, .doubleDeclined))
        #expect(game.award == .win(.black, 4))
        #expect(game.position.fen == Self.afterE4)
        #expect(!game.isAwaitingDoubleResponse)
        #expect(!game.canResignOrAgreeDraw)
        #expect(game.canStartNextGame)

        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.result == .win(.black, .doubleDeclined))
        #expect(reopened.award == .win(.black, 4))
        #expect(reopened.position.fen == Self.afterE4)
    }

    @Test func aFirstOfferDeclinedPaysOnePoint() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()
        game.offerDouble()
        game.declineDouble()

        #expect(game.result == .win(.white, .doubleDeclined))
        #expect(game.award == .win(.white, 1))
    }

    @Test func aWinAfterATakeAwardsTheDoubledStake() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()
        game.tap("f2"); game.tap("f3")
        game.offerDouble()
        game.takeDouble()
        game.tap("e7"); game.tap("e5")
        game.tap("g2"); game.tap("g4")
        game.tap("d8"); game.tap("h4")

        #expect(game.result == .win(.black, .checkmate))
        #expect(game.award == .win(.black, 2))
    }

    @Test func aDrawSplitsTheStake() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()
        game.agreeDraw()
        #expect(game.award == .split(1))

        game.nextGame()
        game.offerDouble()
        game.takeDouble()
        game.agreeDraw()
        #expect(game.award == .split(2))
    }

    @Test func aGameInPlayAwardsNothingYet() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()
        #expect(game.award == nil)
    }

    @Test func anOngoingGameSavedBeforeTheCubeOpensAtOnePointWithEitherSideAbleToOffer() throws {
        let storage = try TemporaryStorage()
        let saved = Data(#"{"version": 1, "position": "\#(Self.afterE4)", "result": null}"#.utf8)
        try saved.write(to: storage.fileURL)

        let game = LocalGame(store: storage.store)
        game.open()

        #expect(game.hasNoFailure)
        #expect(game.position.fen == Self.afterE4)
        #expect(game.stake == 1)
        #expect(game.nextDoubler == nil)
        #expect(game.canOfferDouble)
        #expect(game.award == nil)
        #expect(try Data(contentsOf: storage.fileURL) == saved)

        game.offerDouble()
        game.takeDouble()
        #expect(game.stake == 2)
        #expect(try storage.store.load()?.stake == 2)
    }

    @Test(arguments: [
        (#"{"version": 1, "position": "4k3/8/8/8/8/8/8/4K3 w - -", "result": {"winner": "black", "reason": "resignation"}}"#,
         GameResult.win(.black, .resignation)),
        (#"{"version": 1, "position": "4k3/8/8/8/8/8/8/4K3 w - -", "result": {"draw": "agreement"}}"#,
         GameResult.draw(.agreement)),
        // Fool's mate, saved without its result.
        (#"{"version": 1, "position": "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq -", "result": null}"#,
         GameResult.win(.black, .checkmate)),
    ])
    func aFinishedGameSavedBeforeTheCubeKeepsItsResultWithoutAnAward(contents: String, result: GameResult) throws {
        let storage = try TemporaryStorage()
        try Data(contents.utf8).write(to: storage.fileURL)

        let game = LocalGame(store: storage.store)
        game.open()

        #expect(game.hasNoFailure)
        #expect(game.result == result)
        #expect(game.award == nil)
        #expect(!game.canOfferDouble)

        game.nextGame()
        #expect(game.stake == 1)
        #expect(game.canOfferDouble)
    }

    /// The award text, which XCUITest reads only as spoken: half a point is shown as "½ point".
    @Test(arguments: [
        (PointAward.split(1), "Each player earns ½ point.", "Each player earns half a point."),
        (PointAward.split(2), "Each player earns 1 point.", "Each player earns 1 point."),
        (PointAward.split(64), "Each player earns 32 points.", "Each player earns 32 points."),
        (PointAward.win(.white, 1), "White earns 1 point.", "White earns 1 point."),
        (PointAward.win(.black, 64), "Black earns 64 points.", "Black earns 64 points."),
    ])
    func theAwardIsShownWithItsUnitsAndHalfAPointIsSpokenInWords(award: PointAward, shown: String, spoken: String) {
        #expect(BoardText.award(award, spoken: false) == shown)
        #expect(BoardText.award(award, spoken: true) == spoken)
    }

    static let afterE4 = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -"
}
