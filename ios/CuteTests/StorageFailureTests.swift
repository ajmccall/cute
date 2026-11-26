import Foundation
import Testing
@testable import Cute

/// Failed reads and saves on the real file store, each in its own temporary folder.
@Suite struct StorageFailureTests {
    static let savedPosition = "rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R b KQkq -"

    @Test func aChangeThatCannotBeSavedLeavesTheLastSavedGameAndCanBeRetried() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: Self.savedPosition, in: storage)
        let savedBytes = try Data(contentsOf: storage.fileURL)

        try storage.makeReadOnly()
        game.tap("e7"); game.tap("e5")

        #expect(game.hasUnsavedChange)
        #expect(game.position.fen == Self.savedPosition)
        #expect(try Data(contentsOf: storage.fileURL) == savedBytes)

        game.retrySave()
        #expect(game.hasUnsavedChange)
        #expect(game.position.fen == Self.savedPosition)

        try storage.makeWritable()
        game.retrySave()
        let afterMove = "rnbqkbnr/pppp1ppp/8/4p3/8/5N2/PPPPPPPP/RNBQKB1R w KQkq e6"
        #expect(game.hasNoFailure)
        #expect(game.position.fen == afterMove)
        #expect(try storage.store.load()?.position.fen == afterMove)
    }

    @Test(arguments: ["resign", "agreeDraw", "newGame"])
    func anEndingOrNewGameThatCannotBeSavedChangesNothing(action: String) throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: Self.savedPosition, in: storage)

        try storage.makeReadOnly()
        switch action {
        case "resign": game.resign()
        case "agreeDraw": game.agreeDraw()
        default: game.newGame()
        }

        #expect(game.hasUnsavedChange)
        #expect(game.result == nil)
        #expect(game.position.fen == Self.savedPosition)
    }

    @Test func aMoveAfterAFailedSaveReplacesTheChangeWaitingToBeRetried() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: Self.savedPosition, in: storage)

        try storage.makeReadOnly()
        game.tap("e7"); game.tap("e5")
        try storage.makeWritable()
        game.tap("d7"); game.tap("d5")

        #expect(game.hasNoFailure)
        #expect(game.position.fen == "rnbqkbnr/ppp1pppp/8/3p4/8/5N2/PPPPPPPP/RNBQKB1R w KQkq d6")
        game.retrySave()
        #expect(game.position.fen == "rnbqkbnr/ppp1pppp/8/3p4/8/5N2/PPPPPPPP/RNBQKB1R w KQkq d6")
    }

    @Test(arguments: [
        Data(),
        Data("not json".utf8),
        Data([0xFF, 0xFE, 0x00, 0x12]),
        Data(#"{"version": 3, "position": "4k3/8/8/8/8/8/8/4K3 w - -", "result": null, "stake": 1, "nextDoubler": null, "doublePending": false}"#.utf8),
        Data(#"{"position": "4k3/8/8/8/8/8/8/4K3 w - -", "result": null}"#.utf8),
        Data(#"{"version": 1, "result": null}"#.utf8),
        Data(#"{"version": 1, "position": "4k3/8/8/8/8/8/8/4K3 w - -", "result": {"winner": "green", "reason": "checkmate"}}"#.utf8),
        Data(#"{"version": 1, "position": "4k3/8/8/8/8/8/8/4K3 w - -", "result": {"draw": "boredom"}}"#.utf8),
        Data(#"{"version": 1, "position": "", "result": null}"#.utf8),
        Data(#"{"version": 1, "position": "4k3/8/8/8/8/8/4K3 w - -", "result": null}"#.utf8),
        Data(#"{"version": 1, "position": "4k3/8/8/8/8/8/8/4K4 w - -", "result": null}"#.utf8),
        Data(#"{"version": 1, "position": "4k3/8/8/8/8/8/8/4X3 w - -", "result": null}"#.utf8),
        Data(#"{"version": 1, "position": "4k3/8/8/8/8/8/8/4K3 x - -", "result": null}"#.utf8),
        Data(#"{"version": 1, "position": "4k3/8/8/8/8/8/8/4K3 w KK -", "result": null}"#.utf8),
        Data(#"{"version": 1, "position": "4k3/8/8/8/8/8/8/4K3 w - z9", "result": null}"#.utf8),
    ])
    func anUnreadableSavedGameIsReportedAndKeptUntouched(contents: Data) throws {
        try expectReadFailure(contents)
    }

    /// Well-formed text that no legal game can reach.
    @Test(arguments: [
        "8/8/8/8/8/8/8/4K3 w - -",                 // no black king
        "4k3/8/8/8/8/8/8/3KK3 w - -",              // two white kings
        "4k3/8/8/8/8/8/8/4K2P w - -",              // a pawn on the first rank
        "4k2P/8/8/8/8/8/8/4K3 w - -",              // a pawn on the last rank
        "4k2R/8/8/8/8/8/8/4K3 w - -",              // the side that just moved left its king in check
        "4k3/8/8/8/8/8/8/4K3 w K -",               // a castling right without its rook
        "4k3/8/8/8/8/8/8/3K3R w K -",              // a castling right without its king at home
        "4k3/8/8/8/4P3/8/8/4K3 w - e3",            // en passant on the wrong side's rank
        "4k3/8/8/8/8/8/8/4K3 b - e3",              // en passant with no pawn that passed
    ])
    func anImpossiblePositionIsReportedAsUnreadable(fen: String) throws {
        try expectReadFailure(Data(#"{"version": 1, "position": "\#(fen)", "result": null}"#.utf8))
    }

    /// Version 2 files whose cube is missing, malformed or one that no game can reach,
    /// each on a position with Black to move after 1. e4.
    @Test(arguments: [
        #""result": null, "nextDoubler": null, "doublePending": false"#,                          // no stake
        #""result": null, "stake": null, "nextDoubler": null, "doublePending": false"#,           // a null stake
        #""result": null, "stake": "1", "nextDoubler": null, "doublePending": false"#,            // a stake as text
        #""result": null, "stake": 0, "nextDoubler": null, "doublePending": false"#,              // below one point
        #""result": null, "stake": 3, "nextDoubler": "white", "doublePending": false"#,           // not a doubling
        #""result": null, "stake": 128, "nextDoubler": "white", "doublePending": false"#,         // above the maximum
        #""result": null, "stake": 2, "nextDoubler": null, "doublePending": false"#,              // a take with no taker
        #""result": null, "stake": 1, "nextDoubler": "white", "doublePending": false"#,           // a taker with no take
        #""result": null, "stake": 2, "nextDoubler": "green", "doublePending": false"#,           // no such side
        #""result": null, "stake": 1, "doublePending": false"#,                                   // no next doubler
        #""result": null, "stake": 1, "nextDoubler": null"#,                                      // no pending flag
        #""result": null, "stake": 1, "nextDoubler": null, "doublePending": "yes""#,              // a flag as text
        #""result": {"draw": "agreement"}, "stake": 1, "nextDoubler": null, "doublePending": true"#,  // an offer after the end
        #""result": null, "stake": 64, "nextDoubler": "black", "doublePending": true"#,           // an offer at the maximum
        #""result": null, "stake": 2, "nextDoubler": "white", "doublePending": true"#,            // an offer by the wrong side
    ])
    func anImpossibleCubeIsReportedAsUnreadable(fields: String) throws {
        let fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -"
        try expectReadFailure(Data(#"{"version": 2, "position": "\#(fen)", \#(fields)}"#.utf8))
    }

    @Test func anOfferOnAPositionAlreadyEndedIsReportedAsUnreadable() throws {
        // Fool's mate, with an offer waiting from the mated side.
        let fen = "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq -"
        try expectReadFailure(Data(
            #"{"version": 2, "position": "\#(fen)", "result": null, "stake": 1, "nextDoubler": null, "doublePending": true}"#.utf8))
    }

    @Test func aDeclinedDoubleInAGameSavedBeforeTheCubeIsReportedAsUnreadable() throws {
        try expectReadFailure(Data(
            #"{"version": 1, "position": "4k3/8/8/8/8/8/8/4K3 w - -", "result": {"winner": "white", "reason": "doubleDeclined"}}"#.utf8))
    }

    @Test(arguments: ["offer", "take", "decline"])
    func anOfferOrAnswerThatCannotBeSavedLeavesTheLastSavedGameAndCanBeRetried(action: String) throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: Self.savedPosition, in: storage)
        if action != "offer" { game.offerDouble() }
        let before = try storage.store.load()
        let savedBytes = try Data(contentsOf: storage.fileURL)

        try storage.makeReadOnly()
        switch action {
        case "offer": game.offerDouble()
        case "take": game.takeDouble()
        default: game.declineDouble()
        }

        #expect(game.hasUnsavedChange)
        #expect(game.isAwaitingDoubleResponse == (action != "offer"))
        #expect(game.stake == 1)
        #expect(game.result == nil)
        #expect(game.position.fen == Self.savedPosition)
        #expect(try Data(contentsOf: storage.fileURL) == savedBytes)
        #expect(try storage.store.load() == before)

        try storage.makeWritable()
        game.retrySave()
        #expect(game.hasNoFailure)
        switch action {
        case "offer":
            #expect(game.isAwaitingDoubleResponse)
        case "take":
            #expect(!game.isAwaitingDoubleResponse)
            #expect(game.stake == 2)
        default:
            #expect(game.result == .win(.black, .doubleDeclined))
        }
        let saved = try #require(try storage.store.load())
        #expect(saved.doublePending == game.isAwaitingDoubleResponse)
        #expect(saved.stake == game.stake)
        #expect(saved.result == game.result)
    }

    @Test(arguments: [
        #"{"version": 1, "position": "4k3/8/8/8/8/8/8/4K3 w - - 12 40", "result": null}"#,
        #"{"version": 2, "position": "4k3/8/8/8/8/8/8/4K3 w - -", "result": null, "stake": 64, "nextDoubler": "black", "doublePending": false}"#,
        #"{"version": 2, "position": "4k3/8/8/8/8/8/8/R3K3 w - -", "result": null, "stake": 32, "nextDoubler": "white", "doublePending": true}"#,
        #"{"version": 2, "position": "4k3/8/8/8/8/8/8/4K3 w - -", "result": {"winner": "white", "reason": "doubleDeclined"}, "stake": 1, "nextDoubler": null, "doublePending": false}"#,
        #"{"result": {"draw": "agreement"}, "position": "4k3/8/8/8/8/8/8/4K3 w - -", "version": 1, "extra": true}"#,
        #"{"version": 1, "position": "r3k2r/8/8/8/3pP3/8/8/R3K2R b KQkq e3", "result": null}"#,
    ])
    func wellFormedSavedGamesAtTheEdgesOfTheFormatOpen(contents: String) throws {
        let storage = try TemporaryStorage()
        try Data(contents.utf8).write(to: storage.fileURL)

        let game = LocalGame(store: storage.store)
        game.open()

        #expect(game.hasNoFailure)
    }

    @Test func afterAFailedReadNewGameReplacesTheUnreadableGameOnlyOnConfirmation() throws {
        let storage = try TemporaryStorage()
        try Data("not json".utf8).write(to: storage.fileURL)
        let game = LocalGame(store: storage.store)
        game.open()
        #expect(game.couldNotReadSavedGame)
        #expect(game.newGameNeedsConfirmation)

        game.newGame()

        #expect(game.hasNoFailure)
        #expect(game.position == .opening)
        #expect(try storage.store.load() == .opening)
    }

    @Test func whenNewGameCannotBeSavedAfterAFailedReadNoBoardIsPlayableAndBothFailuresAreIdentified() throws {
        let storage = try TemporaryStorage()
        let unreadable = Data("not json".utf8)
        try unreadable.write(to: storage.fileURL)
        try storage.makeReadOnly()
        let game = LocalGame(store: storage.store)
        game.open()

        game.newGame()

        #expect(game.couldNotReadSavedGame)
        #expect(game.couldNotReadSavedGame)
        #expect(game.hasUnsavedChange)
        #expect(!game.canResignOrAgreeDraw)
        game.tap("e2")
        #expect(game.selection == nil)
        #expect(try Data(contentsOf: storage.fileURL) == unreadable)

        game.retrySave()
        #expect(game.couldNotReadSavedGame)
        #expect(game.hasUnsavedChange)

        // Once the folder takes writes again, retrying the save starts the new game.
        try storage.makeWritable()
        game.retrySave()
        #expect(game.hasNoFailure)
        #expect(!game.couldNotReadSavedGame)
        #expect(!game.hasUnsavedChange)
        #expect(game.position == .opening)
        #expect(try storage.store.load() == .opening)
    }

    @Test func whenTheSavedGameReadsOnRetryTheUnsavedNewGameIsDropped() throws {
        let storage = try TemporaryStorage()
        try Data("not json".utf8).write(to: storage.fileURL)
        try storage.makeReadOnly()
        let game = LocalGame(store: storage.store)
        game.open()
        game.newGame()

        try storage.makeWritable()
        try SavedGame(position: try #require(Position(fen: Self.savedPosition)), result: nil).encodedForTest()
            .write(to: storage.fileURL)
        game.retryRead()

        #expect(game.hasNoFailure)
        #expect(!game.hasUnsavedChange)
        #expect(game.position.fen == Self.savedPosition)
        game.retrySave()
        #expect(game.position.fen == Self.savedPosition)
    }

    @Test func aSavedPositionThatAlreadyEndedOpensWithItsResult() throws {
        let storage = try TemporaryStorage()
        // Fool's mate, saved without its result.
        let game = try openGame(at: "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq -", in: storage)

        #expect(game.result == .win(.black, .checkmate))
        #expect(!game.canResignOrAgreeDraw)
    }

    private func expectReadFailure(_ contents: Data, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let storage = try TemporaryStorage()
        try contents.write(to: storage.fileURL)

        let game = LocalGame(store: storage.store)
        game.open()

        #expect(game.couldNotReadSavedGame, sourceLocation: sourceLocation)
        #expect(!game.canResignOrAgreeDraw, sourceLocation: sourceLocation)
        game.tap("e2")
        game.resign()
        game.agreeDraw()
        #expect(game.selection == nil, sourceLocation: sourceLocation)
        #expect(try Data(contentsOf: storage.fileURL) == contents, sourceLocation: sourceLocation)

        // Once readable again, a retry opens the saved game.
        try SavedGame(position: try #require(Position(fen: Self.savedPosition)), result: nil).encodedForTest()
            .write(to: storage.fileURL)
        game.retryRead()
        #expect(game.hasNoFailure, sourceLocation: sourceLocation)
        #expect(game.position.fen == Self.savedPosition, sourceLocation: sourceLocation)
    }
}

extension SavedGame {
    func encodedForTest() throws -> Data { try JSONEncoder().encode(self) }
}

extension TemporaryStorage {
    /// Stops new files being written in the folder, so the next save fails.
    func makeReadOnly() throws {
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: folder.path)
    }

    func makeWritable() throws {
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder.path)
    }
}
