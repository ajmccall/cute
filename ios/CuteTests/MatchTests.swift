import Foundation
import Testing
@testable import Cute

/// The match to 15 points through the local-game boundary, on the real file store in its own temporary folder:
/// local-game C10 to C15, and C5 for a match change that can't be saved.
@Suite struct MatchTests {
    // MARK: C10

    @Test func aNewMatchStartsAtNoPointsEachAndAWinAddsTheStakeToTheWinnerSavedWithTheResult() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()
        #expect(game.matchScore == MatchScore(white: 0, black: 0))

        game.tap("e2"); game.tap("e4")
        game.resign()

        #expect(game.result == .win(.white, .resignation))
        #expect(game.matchScore == MatchScore(white: 1, black: 0))
        let saved = try #require(try storage.store.load())
        #expect(saved.result == .win(.white, .resignation))
        #expect(saved.matchScore == MatchScore(white: 1, black: 0))

        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.matchScore == MatchScore(white: 1, black: 0))
    }

    @Test func aDrawAddsHalfTheStakeToEachTotal() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()

        game.agreeDraw()

        #expect(game.matchScore == MatchScore(white: 0.5, black: 0.5))
        #expect(try storage.store.load()?.matchScore == MatchScore(white: 0.5, black: 0.5))
    }

    @Test func aDeclinedDoubleAndACheckmateEachAddTheirAwardToTheTotalsSoFar() throws {
        let storage = try TemporaryStorage()
        try storage.store.save(SavedGame(position: .opening, result: nil, stake: 4, nextDoubler: .white,
                                         matchScore: MatchScore(white: 3.5, black: 2)))
        let game = LocalGame(store: storage.store)
        game.open()

        game.offerDouble()
        game.declineDouble()
        #expect(game.matchScore == MatchScore(white: 7.5, black: 2))

        game.nextGame()
        game.tap("f2"); game.tap("f3")
        game.tap("e7"); game.tap("e5")
        game.tap("g2"); game.tap("g4")
        game.tap("d8"); game.tap("h4")
        #expect(game.result == .win(.black, .checkmate))
        #expect(game.matchScore == MatchScore(white: 7.5, black: 3))
        #expect(try storage.store.load()?.matchScore == MatchScore(white: 7.5, black: 3))
    }

    // MARK: C11

    @Test func aGameEndingBelowTheTargetOffersNextGameWhichStartsAFreshGameAtOnceAndKeepsTheTotals() throws {
        let storage = try TemporaryStorage()
        try storage.store.save(SavedGame(position: try #require(Position(fen: Self.afterE4)), result: nil,
                                         stake: 2, nextDoubler: .black, matchScore: MatchScore(white: 4, black: 6.5)))
        let game = LocalGame(store: storage.store)
        game.open()
        #expect(!game.canStartNextGame)

        game.resign()

        #expect(game.result == .win(.white, .resignation))
        #expect(game.matchScore == MatchScore(white: 6, black: 6.5))
        #expect(!game.isMatchOver)
        #expect(game.canStartNextGame)

        game.nextGame()

        #expect(game.position == .opening)
        #expect(game.result == nil)
        #expect(game.stake == 1)
        #expect(game.nextDoubler == nil)
        #expect(game.canOfferDouble)
        #expect(game.matchScore == MatchScore(white: 6, black: 6.5))
        #expect(try storage.store.load() == SavedGame(position: .opening, result: nil,
                                                      matchScore: MatchScore(white: 6, black: 6.5)))
        #expect(!game.canStartNextGame)
    }

    // MARK: C12

    /// Each ending takes a total to 15 or more: by a win, by a decline, and by a split draw past 15 on both sides.
    /// Each game is Black to move after 1. e4, entitled to offer.
    @Test(arguments: [
        (MatchScore(white: 13, black: 9), 2, "resign", MatchScore(white: 15, black: 9), PieceColor?.some(.white)),
        (MatchScore(white: 9, black: 12), 4, "decline", MatchScore(white: 9, black: 16), .black),
        (MatchScore(white: 14.5, black: 13), 4, "draw", MatchScore(white: 16.5, black: 15), .white),
        (MatchScore(white: 13, black: 13), 4, "draw", MatchScore(white: 15, black: 15), nil),
        (MatchScore(white: 14.5, black: 14.5), 1, "draw", MatchScore(white: 15, black: 15), nil),
    ])
    func aGameThatTakesATotalToTheTargetEndsTheMatchWithTheHigherTotalWinning(
        before: MatchScore, stake: Int, ending: String, after: MatchScore, winner: PieceColor?
    ) throws {
        let storage = try TemporaryStorage()
        try storage.store.save(SavedGame(position: try #require(Position(fen: Self.afterE4)), result: nil,
                                         stake: stake, nextDoubler: stake == 1 ? nil : .black, matchScore: before))
        let game = LocalGame(store: storage.store)
        game.open()
        try #require(!game.isMatchOver)

        switch ending {
        case "resign": game.resign()
        case "draw": game.agreeDraw()
        default: game.offerDouble(); game.declineDouble()
        }

        #expect(game.matchScore == after)
        #expect(game.isMatchOver)
        #expect(game.matchScore.leader == winner)
        #expect(!game.canStartNextGame)
        #expect(!game.canResignOrAgreeDraw)
        #expect(!game.canOfferDouble)
        #expect(game.canStartNewMatch)
        #expect(!game.newMatchNeedsConfirmation)

        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.isMatchOver)
        #expect(reopened.matchScore == after)
        #expect(reopened.matchScore.leader == winner)
    }

    @Test func onceTheMatchIsOverNewMatchStartsANewMatchAtNoPointsEachWithoutConfirmation() throws {
        let storage = try TemporaryStorage()
        try storage.store.save(SavedGame(position: .opening, result: .win(.white, .resignation), stake: 1,
                                         matchScore: MatchScore(white: 15, black: 3)))
        let game = LocalGame(store: storage.store)
        game.open()
        #expect(game.isMatchOver)
        #expect(!game.newMatchNeedsConfirmation)

        game.newMatch()

        #expect(!game.isMatchOver)
        #expect(game.position == .opening)
        #expect(game.result == nil)
        #expect(game.stake == 1)
        #expect(game.matchScore == .zero)
        #expect(try storage.store.load() == .opening)
    }

    // MARK: C13

    @Test func whileTheMatchIsUnderWayNewMatchNeedsConfirmationAndReplacesTheGameAndTotals() throws {
        let storage = try TemporaryStorage()
        try storage.store.save(SavedGame(position: try #require(Position(fen: Self.afterE4)), result: nil,
                                         stake: 2, nextDoubler: .black, matchScore: MatchScore(white: 4, black: 6.5)))
        let game = LocalGame(store: storage.store)
        game.open()
        #expect(game.canStartNewMatch)
        #expect(game.newMatchNeedsConfirmation)

        game.resign()
        // Finished but below the target: the match is still under way.
        #expect(game.canStartNewMatch)
        #expect(game.newMatchNeedsConfirmation)

        game.newMatch()

        #expect(game.position == .opening)
        #expect(game.result == nil)
        #expect(game.matchScore == .zero)
        #expect(game.nextDoubler == nil)
        #expect(try storage.store.load() == .opening)
        #expect(game.newMatchNeedsConfirmation)
    }

    @Test func newMatchIsNotAvailableDuringADoubleResponse() throws {
        let storage = try TemporaryStorage()
        try storage.store.save(SavedGame(position: .opening, result: nil, matchScore: MatchScore(white: 2, black: 1)))
        let game = LocalGame(store: storage.store)
        game.open()
        game.offerDouble()

        #expect(!game.canStartNewMatch)
        game.newMatch()

        #expect(game.isAwaitingDoubleResponse)
        #expect(game.matchScore == MatchScore(white: 2, black: 1))
        #expect(try storage.store.load()?.doublePending == true)
    }

    /// The saved game's format, field for field: the totals stay `whiteTotal` and `blackTotal` whatever the code
    /// calls the match score.
    @Test func theMatchScoreIsSavedAsWhiteTotalAndBlackTotal() throws {
        let storage = try TemporaryStorage()
        let saved = SavedGame(position: try #require(Position(fen: CapturesTests.afterExd5)), result: nil, stake: 2,
                              nextDoubler: .white, matchScore: MatchScore(white: 4.5, black: 3),
                              captures: Captures(white: [.pawn], black: []))
        let contents = #"{"version": 4, "position": "\#(CapturesTests.afterExd5)", "result": null, "stake": 2, "nextDoubler": "white", "doublePending": false, "whiteTotal": 4.5, "blackTotal": 3, "captures": {"white": ["pawn"], "black": []}}"#

        try storage.store.save(saved)
        let written = try JSONSerialization.jsonObject(with: Data(contentsOf: storage.fileURL)) as? NSDictionary
        let expected = try JSONSerialization.jsonObject(with: Data(contents.utf8)) as? NSDictionary
        #expect(written == expected)

        try Data(contents.utf8).write(to: storage.fileURL)
        #expect(try storage.store.load() == saved)
    }

    // MARK: C14

    @Test(arguments: [
        (Points(10.5), 4, false),
        (Points(11), 4, true),
        (Points(14.5), 1, true),
        (Points(0), 16, true),
        (Points(0), 8, false),
    ])
    func declineEndsTheMatchWhenTheOfferersTotalWithTheOldStakeReachesTheTarget(
        offerersTotal: Points, stake: Int, endsMatch: Bool
    ) throws {
        let storage = try TemporaryStorage()
        // Black to move and entitled to offer.
        try storage.store.save(SavedGame(position: try #require(Position(fen: Self.afterE4)), result: nil,
                                         stake: stake, nextDoubler: stake == 1 ? nil : .black,
                                         matchScore: MatchScore(white: 3, black: offerersTotal)))
        let game = LocalGame(store: storage.store)
        game.open()
        game.offerDouble()

        #expect(game.declineEndsMatch == endsMatch)
    }

    @Test(arguments: [
        (PieceColor.white, 4, false, "Decline: White wins 4 points."),
        (PieceColor.white, 4, true, "Decline: White wins 4 points and the match."),
        (PieceColor.black, 1, true, "Decline: Black wins 1 point and the match."),
    ])
    func theDeclineTextNamesTheMatchWhenDecliningEndsIt(
        offerer: PieceColor, stake: Int, endsMatch: Bool, text: String
    ) {
        #expect(BoardText.declineEffect(offerer: offerer, stake: stake, endsMatch: endsMatch) == text)
    }

    // MARK: C15

    /// Games saved before matches, each opening as the first game of a match.
    @Test(arguments: [
        // Ongoing, before the cube and after it.
        (#"{"version": 1, "position": "\#(MatchTests.afterE4)", "result": null}"#,
         MatchScore.zero, false, false),
        (#"{"version": 2, "position": "\#(MatchTests.afterE4)", "result": null, "stake": 2, "nextDoubler": "black", "doublePending": false}"#,
         MatchScore.zero, false, false),
        (#"{"version": 2, "position": "\#(MatchTests.afterE4)", "result": null, "stake": 1, "nextDoubler": null, "doublePending": true}"#,
         MatchScore.zero, false, false),
        // Finished with a stake: its award is the match score.
        (#"{"version": 2, "position": "\#(MatchTests.afterE4)", "result": {"winner": "white", "reason": "resignation"}, "stake": 4, "nextDoubler": "white", "doublePending": false}"#,
         MatchScore(white: 4, black: 0), true, false),
        (#"{"version": 2, "position": "\#(MatchTests.afterE4)", "result": {"draw": "agreement"}, "stake": 1, "nextDoubler": null, "doublePending": false}"#,
         MatchScore(white: 0.5, black: 0.5), true, false),
        (#"{"version": 2, "position": "\#(MatchTests.afterE4)", "result": {"winner": "black", "reason": "doubleDeclined"}, "stake": 16, "nextDoubler": "black", "doublePending": false}"#,
         MatchScore(white: 0, black: 16), false, true),
        // Fool's mate, saved without its result, at two points.
        (#"{"version": 2, "position": "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq -", "result": null, "stake": 2, "nextDoubler": "black", "doublePending": false}"#,
         MatchScore(white: 0, black: 2), true, false),
        // Finished before the cube: no award, so no points.
        (#"{"version": 1, "position": "4k3/8/8/8/8/8/8/R3K3 w - -", "result": {"winner": "black", "reason": "resignation"}}"#,
         MatchScore.zero, true, false),
    ])
    func aGameSavedBeforeMatchesOpensAsTheFirstGameOfAMatch(
        contents: String, matchScore: MatchScore, offersNextGame: Bool, isMatchOver: Bool
    ) throws {
        let storage = try TemporaryStorage()
        let saved = Data(contents.utf8)
        try saved.write(to: storage.fileURL)

        let game = LocalGame(store: storage.store)
        game.open()

        #expect(game.hasNoFailure)
        #expect(game.matchScore == matchScore)
        #expect(game.canStartNextGame == offersNextGame)
        #expect(game.isMatchOver == isMatchOver)
        #expect(try Data(contentsOf: storage.fileURL) == saved)
    }

    @Test func anOngoingGameSavedBeforeMatchesOffersNextGameOnceItHasFinished() throws {
        let storage = try TemporaryStorage()
        try Data(#"{"version": 1, "position": "\#(Self.afterE4)", "result": null}"#.utf8).write(to: storage.fileURL)
        let game = LocalGame(store: storage.store)
        game.open()

        game.resign()

        #expect(game.matchScore == MatchScore(white: 1, black: 0))
        #expect(game.canStartNextGame)
        game.nextGame()
        #expect(game.matchScore == MatchScore(white: 1, black: 0))
        #expect(try storage.store.load()?.matchScore == MatchScore(white: 1, black: 0))
    }

    // MARK: C5

    /// An ending that can't be saved adds nothing to the totals, and Retry saves the result and its award together.
    @Test(arguments: ["resign", "agreeDraw", "decline", "checkmate"])
    func anEndingThatCannotBeSavedLeavesTheLastSavedGameAndTotals(ending: String) throws {
        let storage = try TemporaryStorage()
        // White to move with mate in one (Qh5xf7#), at 13 to 12.
        let mateInOne = "r1bqkbnr/pppp1ppp/2n5/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq -"
        let before = MatchScore(white: 13, black: 12)
        try storage.store.save(SavedGame(position: try #require(Position(fen: mateInOne)), result: nil, matchScore: before))
        let game = LocalGame(store: storage.store)
        game.open()
        if ending == "decline" { game.offerDouble() }
        let savedBytes = try Data(contentsOf: storage.fileURL)

        try storage.makeReadOnly()
        switch ending {
        case "resign": game.resign()
        case "agreeDraw": game.agreeDraw()
        case "decline": game.declineDouble()
        default: game.tap("h5"); game.tap("f7")
        }

        #expect(game.hasUnsavedChange)
        #expect(game.result == nil)
        #expect(game.matchScore == before)
        #expect(game.position.fen == mateInOne)
        #expect(!game.canStartNextGame)
        #expect(try Data(contentsOf: storage.fileURL) == savedBytes)

        try storage.makeWritable()
        game.retrySave()
        #expect(game.hasNoFailure)
        #expect(game.result != nil)
        #expect(game.matchScore != before)
        let saved = try #require(try storage.store.load())
        #expect(saved.result == game.result)
        #expect(saved.matchScore == game.matchScore)
    }

    @Test(arguments: ["nextGame", "newMatch"])
    func nextGameOrNewMatchThatCannotBeSavedKeepsTheFinishedGameAndTotals(action: String) throws {
        let storage = try TemporaryStorage()
        try storage.store.save(SavedGame(position: try #require(Position(fen: Self.afterE4)),
                                         result: .win(.white, .resignation), matchScore: MatchScore(white: 5, black: 2)))
        let game = LocalGame(store: storage.store)
        game.open()
        let savedBytes = try Data(contentsOf: storage.fileURL)

        try storage.makeReadOnly()
        if action == "nextGame" { game.nextGame() } else { game.newMatch() }

        #expect(game.hasUnsavedChange)
        #expect(game.result == .win(.white, .resignation))
        #expect(game.position.fen == Self.afterE4)
        #expect(game.matchScore == MatchScore(white: 5, black: 2))
        #expect(try Data(contentsOf: storage.fileURL) == savedBytes)

        try storage.makeWritable()
        game.retrySave()
        #expect(game.hasNoFailure)
        #expect(game.position == .opening)
        #expect(game.matchScore == (action == "nextGame" ? MatchScore(white: 5, black: 2) : .zero))
        #expect(try storage.store.load()?.matchScore == game.matchScore)
    }

    // MARK: Interface text

    /// The match score line, which XCUITest reads only as spoken: a half is shown as ½.
    @Test(arguments: [
        (MatchScore.zero, "White 0 points · Black 0 points · first to 15 points",
         "White 0 points · Black 0 points · first to 15 points"),
        (MatchScore(white: 1, black: 0.5), "White 1 point · Black ½ point · first to 15 points",
         "White 1 point · Black half a point · first to 15 points"),
        (MatchScore(white: 4.5, black: 16), "White 4½ points · Black 16 points · first to 15 points",
         "White 4 and a half points · Black 16 points · first to 15 points"),
        (MatchScore(white: 1.5, black: 0), "White 1½ points · Black 0 points · first to 15 points",
         "White 1 and a half points · Black 0 points · first to 15 points"),
    ])
    func theMatchScoreLineShowsBothTotalsAndTheTargetWithTheirUnits(matchScore: MatchScore, shown: String, spoken: String) {
        #expect(BoardText.matchScore(matchScore, spoken: false) == shown)
        #expect(BoardText.matchScore(matchScore, spoken: true) == spoken)
    }

    /// The match result, with totals in the winner's-first order and without units.
    @Test(arguments: [
        (MatchScore(white: 16, black: 9), "White wins the match, 16 to 9", "White wins the match, 16 to 9"),
        (MatchScore(white: 3, black: 15), "Black wins the match, 15 to 3", "Black wins the match, 15 to 3"),
        (MatchScore(white: 16.5, black: 15), "White wins the match, 16½ to 15",
         "White wins the match, 16 and a half to 15"),
        (MatchScore(white: 15, black: 15), "Match drawn, 15 to 15", "Match drawn, 15 to 15"),
        (MatchScore(white: 15.5, black: 15.5), "Match drawn, 15½ to 15½",
         "Match drawn, 15 and a half to 15 and a half"),
        (MatchScore(white: 0.5, black: 64.5), "Black wins the match, 64½ to ½",
         "Black wins the match, 64 and a half to a half"),
    ])
    func theMatchResultNamesTheWinnerAndBothTotals(matchScore: MatchScore, shown: String, spoken: String) {
        #expect(BoardText.matchResult(matchScore, spoken: false) == shown)
        #expect(BoardText.matchResult(matchScore, spoken: true) == spoken)
    }

    nonisolated static let afterE4 = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -"
}
