import XCTest

/// The match to 15 points on the running board: local-game C10 to C15, and C5 for an ending that can't be saved.
final class MatchUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Black to move after 1. e4.
    static let afterE4 = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -"

    /// A version 3 game file with the given cube and totals, for seeding with `launch(seedFile:)`.
    static func savedGame(_ fen: String = afterE4, result: String = "null", stake: Int = 1,
                          nextDoubler: String? = nil, white: Double, black: Double) -> String {
        let doubler = nextDoubler.map { #""\#($0)""# } ?? "null"
        return #"{"version": 3, "position": "\#(fen)", "result": \#(result), "stake": \#(stake), "nextDoubler": \#(doubler), "doublePending": false, "whiteTotal": \#(white), "blackTotal": \#(black)}"#
    }

    // MARK: C10

    @MainActor
    func testTheMatchScoreLineShowsBothTotalsAndTheTargetInPlayDuringAResponseAndAfterTheEnd() throws {
        let board = BoardRobot()
        board.launch()
        board.expectText("matchScore", "White 0 points · Black 0 points · first to 15 points")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C10", to: self)

        board.offerDouble.tap()
        board.expectStatus("Black, answer the double")
        board.expectText("matchScore", "White 0 points · Black 0 points · first to 15 points")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C10-response", to: self)

        board.app.buttons["Decline"].tap()
        board.expectStatus("White wins · Double declined")
        board.expectText("award", "White earns 1 point.")
        board.expectText("matchScore", "White 1 point · Black 0 points · first to 15 points")

        board.launch()
        board.expectStatus("White wins · Double declined")
        board.expectText("matchScore", "White 1 point · Black 0 points · first to 15 points")
    }

    // MARK: C10, C11

    @MainActor
    func testADrawAtOnePointGivesHalfAPointEachAndNextGameStartsAtOnceKeepingTheTotals() throws {
        let board = BoardRobot()
        board.launch(seedFile: Self.savedGame(white: 3, black: 2))
        board.app.buttons["Agree draw"].tap()
        board.app.alerts.firstMatch.buttons["Confirm"].tap()

        board.expectStatus("Draw · Agreement")
        // Shown as "3½ points" (MatchTests checks the text; the screenshot shows it), spoken in words.
        board.expectText("matchScore",
                         "White 3 and a half points · Black 2 and a half points · first to 15 points")
        XCTAssertTrue(board.app.buttons["Next game"].exists)
        XCTAssertTrue(board.app.buttons["New match"].exists)
        XCTAssertFalse(board.app.buttons["Resign"].exists)
        XCTAssertFalse(board.offerDouble.exists)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C10-C11-draw", to: self)

        board.app.buttons["Next game"].tap()
        XCTAssertFalse(board.app.alerts.firstMatch.waitForExistence(timeout: 1))
        board.expectStatus("White to move")
        XCTAssertTrue(board.isAtBottom("White"))
        board.expectSquare("e2", "e2, White pawn")
        board.expectSquare("e4", "e4, Empty")
        board.expectText("stake", "Stake: 1 point")
        board.expectText("doubleRight", "Either player can offer")
        XCTAssertTrue(board.offerDouble.isEnabled)
        XCTAssertFalse(board.app.buttons["Next game"].exists)
        board.expectText("matchScore",
                         "White 3 and a half points · Black 2 and a half points · first to 15 points")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C11", to: self)

        board.launch()
        board.expectStatus("White to move")
        board.expectText("matchScore",
                         "White 3 and a half points · Black 2 and a half points · first to 15 points")
    }

    @MainActor
    func testHalfAPointAloneIsSpokenInWords() throws {
        let board = BoardRobot()
        board.launch()
        board.app.buttons["Agree draw"].tap()
        board.app.alerts.firstMatch.buttons["Confirm"].tap()

        board.expectText("matchScore", "White half a point · Black half a point · first to 15 points")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C10-half", to: self)
    }

    // MARK: C12

    @MainActor
    func testAWinThatReachesFifteenEndsTheMatchAndNewMatchIsTheOnlyAction() throws {
        let board = BoardRobot()
        board.launch(seedFile: Self.savedGame(stake: 2, nextDoubler: "black", white: 13, black: 9))
        board.app.buttons["Resign"].tap()
        board.app.alerts.firstMatch.buttons["Confirm"].tap()

        board.expectStatus("White wins · Resignation")
        board.expectText("award", "White earns 2 points.")
        board.expectText("matchResult", "White wins the match, 15 to 9")
        board.expectText("matchScore", "White 15 points · Black 9 points · first to 15 points")
        try expectNewMatchAlone(board)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C12-win", to: self)

        board.launch()
        board.expectText("matchResult", "White wins the match, 15 to 9")
        try expectNewMatchAlone(board)

        board.app.buttons["New match"].tap()
        XCTAssertFalse(board.app.alerts.firstMatch.waitForExistence(timeout: 1))
        board.expectStatus("White to move")
        board.expectSquare("e4", "e4, Empty")
        board.expectText("matchScore", "White 0 points · Black 0 points · first to 15 points")
        board.expectText("stake", "Stake: 1 point")
        XCTAssertFalse(board.app.staticTexts["matchResult"].exists)
    }

    @MainActor
    func testASplitDrawPastFifteenIsWonByTheHigherTotalAndEqualTotalsDrawTheMatch() throws {
        let board = BoardRobot()
        board.launch(seedFile: Self.savedGame(stake: 4, nextDoubler: "black", white: 14.5, black: 13))
        board.app.buttons["Agree draw"].tap()
        board.app.alerts.firstMatch.buttons["Confirm"].tap()
        board.expectStatus("Draw · Agreement")
        board.expectText("award", "Each player earns 2 points.")
        // Shown as "16½ to 15" (MatchTests checks the text), spoken in words.
        board.expectText("matchResult", "White wins the match, 16 and a half to 15")
        try expectNewMatchAlone(board)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C12-split-draw", to: self)

        board.launch(seedFile: Self.savedGame(stake: 4, nextDoubler: "black", white: 13, black: 13))
        board.app.buttons["Agree draw"].tap()
        board.app.alerts.firstMatch.buttons["Confirm"].tap()
        board.expectText("matchResult", "Match drawn, 15 to 15")
        board.expectText("matchScore", "White 15 points · Black 15 points · first to 15 points")
        try expectNewMatchAlone(board)
        board.attachScreenshot(named: "local-game-C12-drawn", to: self)
    }

    /// In match over, New match is the only action and the board takes no move.
    @MainActor
    private func expectNewMatchAlone(_ board: BoardRobot) throws {
        XCTAssertTrue(board.app.buttons["New match"].waitForExistence(timeout: 5))
        for action in ["Next game", "Resign", "Agree draw", "Offer double", "Take", "Decline"] {
            XCTAssertFalse(board.app.buttons[action].exists, action)
        }
        XCTAssertFalse(board.app.staticTexts["stake"].exists)
        board.tap("e7")
        board.expectValue(of: "e7", "")
        board.expectLegalDestinations([])
    }

    // MARK: C14, C12

    @MainActor
    func testWhenDecliningWouldReachFifteenTheResponseNamesTheMatchAndDecliningEndsIt() throws {
        let board = BoardRobot()
        board.launch(seedFile: Self.savedGame(stake: 4, nextDoubler: "black", white: 9, black: 11))
        board.offerDouble.tap()

        board.expectStatus("White, answer the double")
        board.expectText("takeEffect", "Take: play for 8 points.")
        board.expectText("declineEffect", "Decline: Black wins 4 points and the match.")
        board.expectText("matchScore", "White 9 points · Black 11 points · first to 15 points")
        XCTAssertFalse(board.app.buttons["New match"].exists)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C14", to: self)

        board.app.buttons["Decline"].tap()
        board.expectStatus("Black wins · Double declined")
        board.expectText("award", "Black earns 4 points.")
        board.expectText("matchResult", "Black wins the match, 15 to 9")
        try expectNewMatchAlone(board)
        board.attachScreenshot(named: "local-game-C12-decline", to: self)
    }

    @MainActor
    func testWhenDecliningWouldNotReachFifteenTheResponseLeavesTheMatchOut() throws {
        let board = BoardRobot()
        board.launch(seedFile: Self.savedGame(stake: 4, nextDoubler: "black", white: 9, black: 10.5))
        board.offerDouble.tap()
        board.expectText("declineEffect", "Decline: Black wins 4 points.")
        try board.auditAccessibility()
    }

    // MARK: C13

    @MainActor
    func testNewMatchAsksForConfirmationWhileTheMatchIsUnderWayAndIsUnavailableDuringAResponse() throws {
        let board = BoardRobot()
        board.launch(seedFile: Self.savedGame(stake: 2, nextDoubler: "black", white: 4, black: 6.5))
        board.expectStatus("Black to move")
        // Audited before the stock alert opens: the system draws the alert itself.
        try board.auditAccessibility()

        board.app.buttons["New match"].tap()
        let alert = board.app.alerts["Replace this match?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        board.attachScreenshot(named: "local-game-C13", to: self)
        alert.buttons["Cancel"].tap()
        board.expectStatus("Black to move")
        board.expectSquare("e4", "e4, White pawn")
        board.expectText("stake", "Stake: 2 points")
        board.expectText("matchScore",
                         "White 4 points · Black 6 and a half points · first to 15 points")

        // A finished game below the target: the match is still under way.
        board.app.buttons["Resign"].tap()
        board.app.alerts.firstMatch.buttons["Confirm"].tap()
        board.expectStatus("White wins · Resignation")
        board.app.buttons["New match"].tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Cancel"].tap()
        board.expectStatus("White wins · Resignation")
        board.expectText("matchScore",
                         "White 6 points · Black 6 and a half points · first to 15 points")

        board.app.buttons["New match"].tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Confirm"].tap()
        board.expectStatus("White to move")
        board.expectSquare("e4", "e4, Empty")
        board.expectText("stake", "Stake: 1 point")
        board.expectText("matchScore", "White 0 points · Black 0 points · first to 15 points")

        board.offerDouble.tap()
        board.expectStatus("Black, answer the double")
        XCTAssertFalse(board.app.buttons["New match"].exists)
    }

    // MARK: C15

    @MainActor
    func testGamesSavedBeforeMatchesOpenAsTheFirstGameOfAMatch() throws {
        let board = BoardRobot()

        // Ongoing: 0 to 0, played on, and Next game once it has finished.
        board.launch(seedFile: #"{"version": 1, "position": "\#(Self.afterE4)", "result": null}"#)
        board.expectStatus("Black to move")
        board.expectText("matchScore", "White 0 points · Black 0 points · first to 15 points")
        try board.auditAccessibility()
        board.app.buttons["Resign"].tap()
        board.app.alerts.firstMatch.buttons["Confirm"].tap()
        board.expectText("matchScore", "White 1 point · Black 0 points · first to 15 points")
        XCTAssertTrue(board.app.buttons["Next game"].exists)

        // Finished with a stake: its award is the match score.
        board.launch(seedFile: #"{"version": 2, "position": "\#(Self.afterE4)", "result": {"winner": "white", "reason": "resignation"}, "stake": 4, "nextDoubler": "white", "doublePending": false}"#)
        board.expectStatus("White wins · Resignation")
        board.expectText("matchScore", "White 4 points · Black 0 points · first to 15 points")
        XCTAssertTrue(board.app.buttons["Next game"].exists)
        board.attachScreenshot(named: "local-game-C15-finished", to: self)

        // Finished with a stake over 15: the match is over.
        board.launch(seedFile: #"{"version": 2, "position": "\#(Self.afterE4)", "result": {"winner": "black", "reason": "doubleDeclined"}, "stake": 16, "nextDoubler": "black", "doublePending": false}"#)
        board.expectStatus("Black wins · Double declined")
        board.expectText("matchResult", "Black wins the match, 16 to 0")
        try expectNewMatchAlone(board)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C15-over", to: self)

        // Finished before the cube: no award, 0 to 0, and Next game.
        board.launch(seedFile: #"{"version": 1, "position": "4k3/8/8/8/8/8/8/R3K3 w - -", "result": {"winner": "black", "reason": "resignation"}}"#)
        board.expectStatus("Black wins · Resignation")
        XCTAssertFalse(board.app.staticTexts["award"].exists)
        board.expectText("matchScore", "White 0 points · Black 0 points · first to 15 points")
        XCTAssertTrue(board.app.buttons["Next game"].exists)
    }

    // MARK: C5

    @MainActor
    func testAnEndingThatCannotBeSavedKeepsTheLastSavedGameAndTotals() throws {
        let board = BoardRobot()
        board.launch(seedFile: Self.savedGame(stake: 2, nextDoubler: "black", white: 13, black: 9), fault: "write")
        board.app.buttons["Resign"].tap()
        board.app.alerts.firstMatch.buttons["Confirm"].tap()

        XCTAssertTrue(board.app.staticTexts["Change not saved."].waitForExistence(timeout: 5))
        XCTAssertTrue(board.app.buttons["retrySave"].exists)
        board.expectStatus("Black to move")
        board.expectText("matchScore", "White 13 points · Black 9 points · first to 15 points")
        XCTAssertFalse(board.app.staticTexts["matchResult"].exists)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C5-ending", to: self)

        board.app.buttons["retrySave"].tap()
        XCTAssertTrue(board.app.staticTexts["Change not saved."].exists)
        board.expectText("matchScore", "White 13 points · Black 9 points · first to 15 points")

        // With access restored, reopening shows the last saved game and totals.
        board.launch()
        XCTAssertFalse(board.app.staticTexts["Change not saved."].exists)
        board.expectStatus("Black to move")
        board.expectText("matchScore", "White 13 points · Black 9 points · first to 15 points")
    }
}
