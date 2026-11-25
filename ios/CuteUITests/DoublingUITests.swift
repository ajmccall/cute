import XCTest

/// The doubling cube on the running board: local-game C6 to C9, and C5 for a failed offer save.
final class DoublingUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    static let afterE4 = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -"

    /// A version 2 game file with the given cube, for seeding with `launch(seedFile:)`.
    static func savedGame(_ fen: String, stake: Int, nextDoubler: String?, pending: Bool = false,
                          result: String = "null") -> String {
        let doubler = nextDoubler.map { #""\#($0)""# } ?? "null"
        return #"{"version": 2, "position": "\#(fen)", "result": \#(result), "stake": \#(stake), "nextDoubler": \#(doubler), "doublePending": \#(pending)}"#
    }

    // MARK: C6

    @MainActor
    func testAFreshGameShowsOnePointAndEitherPlayerCanOffer() throws {
        let board = BoardRobot()
        board.launch()

        XCTAssertEqual(board.status, "White to move")
        XCTAssertEqual(board.text("stake"), "Stake: 1 point")
        XCTAssertEqual(board.text("doubleRight"), "Either player can offer")
        XCTAssertTrue(board.offerDouble.isEnabled)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C6", to: self)

        // Black, on the next turn, can offer too.
        board.tap("e2", "e4")
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertEqual(board.text("doubleRight"), "Either player can offer")
        XCTAssertTrue(board.offerDouble.isEnabled)
    }

    @MainActor
    func testAnOngoingGameSavedBeforeTheCubeOpensAtOnePoint() throws {
        let board = BoardRobot()
        board.launch(seedFile: #"{"version": 1, "position": "\#(Self.afterE4)", "result": null}"#)

        XCTAssertEqual(board.status, "Black to move")
        XCTAssertEqual(board.square("e4").label, "e4, White pawn")
        XCTAssertTrue(board.isAtBottom("Black"))
        XCTAssertEqual(board.text("stake"), "Stake: 1 point")
        XCTAssertEqual(board.text("doubleRight"), "Either player can offer")
        XCTAssertTrue(board.offerDouble.isEnabled)
        try board.auditAccessibility()
    }

    @MainActor
    func testAnOfferIsAllowedInCheckButNeverAtSixtyFourPoints() throws {
        let board = BoardRobot()
        board.launch(seed: "R3k3/8/8/8/8/8/8/4K3 b - -")
        XCTAssertEqual(board.status, "Black to move · Check")
        XCTAssertTrue(board.offerDouble.isEnabled)

        board.launch(seedFile: Self.savedGame(Self.afterE4, stake: 64, nextDoubler: "black"))
        XCTAssertEqual(board.text("stake"), "Stake: 64 points")
        XCTAssertEqual(board.text("doubleRight"), "Maximum stake reached")
        XCTAssertFalse(board.offerDouble.isEnabled)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C6-maximum", to: self)
        board.offerDouble.tap()
        XCTAssertFalse(board.app.alerts.firstMatch.waitForExistence(timeout: 1))
    }

    // MARK: C7

    @MainActor
    func testOfferDoubleMakesTheOfferAtOnceAndTheResponderAnswersEvenAfterReopening() throws {
        let board = BoardRobot()
        board.launch()
        board.tap("e2")

        // One tap makes the offer: no confirmation, and the selection is cleared.
        let offerFrame = board.offerDouble.frame
        board.offerDouble.tap()
        XCTAssertFalse(board.app.alerts.firstMatch.waitForExistence(timeout: 1))
        try expectBlackToAnswerAnOfferFromWhiteAtOnePoint(board)
        // A second, hurried tap where Offer double was can't answer the offer.
        for answer in ["Take", "Decline"] {
            XCTAssertFalse(board.app.buttons[answer].frame.intersects(offerFrame),
                           "\(answer) \(board.app.buttons[answer].frame) overlaps Offer double \(offerFrame)")
        }
        XCTAssertFalse(board.app.alerts.firstMatch.exists)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C7", to: self)

        // Nothing but Take or Decline: the board takes no move.
        board.tap("e7", "e5")
        XCTAssertEqual(board.value(of: "e7"), "")
        XCTAssertEqual(board.square("e5").label, "e5, Empty")
        board.tap("e2", "e4")
        XCTAssertEqual(board.square("e4").label, "e4, Empty")

        board.launch()
        try expectBlackToAnswerAnOfferFromWhiteAtOnePoint(board)
    }

    @MainActor
    private func expectBlackToAnswerAnOfferFromWhiteAtOnePoint(_ board: BoardRobot) throws {
        XCTAssertEqual(board.status, "Black, answer the double")
        XCTAssertTrue(board.isAtBottom("Black"))
        XCTAssertEqual(board.square("e2").label, "e2, White pawn")
        XCTAssertEqual(board.value(of: "e2"), "")
        // Named once, in the status above the board, not again in the panel (product owner, on #17).
        let responderTexts = board.app.staticTexts.matching(NSPredicate(format: "label == %@", "Black, answer the double"))
        XCTAssertEqual(responderTexts.count, 1)
        XCTAssertEqual(board.text("stake"), "Stake: 1 point")
        XCTAssertEqual(board.text("takeEffect"), "Take: play for 2 points.")
        XCTAssertEqual(board.text("declineEffect"), "Decline: White wins 1 point.")
        XCTAssertTrue(board.app.buttons["Take"].exists)
        XCTAssertTrue(board.app.buttons["Decline"].exists)
        for action in ["New game", "Resign", "Agree draw", "Offer double"] {
            XCTAssertFalse(board.app.buttons[action].exists, action)
        }
    }

    // MARK: C8

    @MainActor
    func testTakingReturnsTheBoardToTheOffererAtTwiceTheStakeAndOnlyTheTakerMayRedouble() throws {
        let board = BoardRobot()
        board.launch(seed: Self.afterE4)
        board.offerDouble.tap()
        XCTAssertEqual(board.status, "White, answer the double")
        XCTAssertTrue(board.isAtBottom("White"))

        board.app.buttons["Take"].tap()
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertTrue(board.isAtBottom("Black"))
        XCTAssertEqual(board.text("stake"), "Stake: 2 points")
        XCTAssertEqual(board.text("doubleRight"), "Only White can offer")
        XCTAssertFalse(board.offerDouble.isEnabled)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C8", to: self)

        // The offerer moves from the same position.
        board.tap("e7", "e5")
        XCTAssertEqual(board.status, "White to move")
        XCTAssertEqual(board.square("e5").label, "e5, Black pawn")
        XCTAssertTrue(board.offerDouble.isEnabled)

        board.offerDouble.tap()
        XCTAssertEqual(board.status, "Black, answer the double")
        XCTAssertEqual(board.text("takeEffect"), "Take: play for 4 points.")
        XCTAssertEqual(board.text("declineEffect"), "Decline: White wins 2 points.")
    }

    // MARK: C9

    @MainActor
    func testDecliningEndsTheGameWithTheOffererWinningTheOldStake() throws {
        let board = BoardRobot()
        board.launch()
        board.offerDouble.tap()
        XCTAssertEqual(board.status, "Black, answer the double")

        board.app.buttons["Decline"].tap()
        XCTAssertEqual(board.status, "White wins · Double declined")
        XCTAssertEqual(board.text("award"), "White earns 1 point.")
        XCTAssertEqual(board.square("e2").label, "e2, White pawn")
        XCTAssertFalse(board.app.buttons["Resign"].exists)
        XCTAssertFalse(board.offerDouble.exists)
        XCTAssertFalse(board.app.staticTexts["stake"].exists)
        board.tap("e2")
        XCTAssertEqual(board.value(of: "e2"), "")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C9", to: self)

        board.launch()
        XCTAssertEqual(board.status, "White wins · Double declined")
        XCTAssertEqual(board.text("award"), "White earns 1 point.")

        // A fresh game starts at one point.
        board.app.buttons["New game"].tap()
        XCTAssertEqual(board.status, "White to move")
        XCTAssertEqual(board.text("stake"), "Stake: 1 point")
        XCTAssertEqual(board.text("doubleRight"), "Either player can offer")
    }

    @MainActor
    func testAFinishedGameAwardsTheStakeOrSplitsItOnADraw() throws {
        let board = BoardRobot()

        // A draw at one point: half a point each, spoken in words.
        board.launch()
        board.app.buttons["Agree draw"].tap()
        board.app.alerts.firstMatch.buttons["Confirm"].tap()
        XCTAssertEqual(board.status, "Draw · Agreement")
        let award = board.app.staticTexts["award"]
        XCTAssertTrue(award.waitForExistence(timeout: 5))
        // Shown as "½ point" (DoublingTests checks the text; the screenshot shows it), spoken in words.
        XCTAssertEqual(award.label, "Each player earns half a point.")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C9-draw", to: self)

        // A draw after a take splits two points.
        board.launch(seedFile: Self.savedGame("4k3/8/8/8/8/8/8/3rK3 w - -", stake: 2, nextDoubler: "black"))
        board.tap("e1", "d1")
        XCTAssertEqual(board.status, "Draw · Insufficient material")
        XCTAssertEqual(board.text("award"), "Each player earns 1 point.")

        // A win after two takes pays four points.
        board.launch(seedFile: Self.savedGame("4k3/8/8/8/8/8/8/R3K3 w - -", stake: 4, nextDoubler: "white"))
        board.app.buttons["Resign"].tap()
        board.app.alerts.firstMatch.buttons["Confirm"].tap()
        XCTAssertEqual(board.status, "Black wins · Resignation")
        XCTAssertEqual(board.text("award"), "Black earns 4 points.")
    }

    @MainActor
    func testAFinishedGameSavedBeforeTheCubeKeepsItsResultWithoutAnAward() throws {
        let board = BoardRobot()
        board.launch(seedFile: #"{"version": 1, "position": "4k3/8/8/8/8/8/8/R3K3 w - -", "result": {"winner": "black", "reason": "resignation"}}"#)

        XCTAssertEqual(board.status, "Black wins · Resignation")
        XCTAssertFalse(board.app.staticTexts["award"].exists)
        XCTAssertFalse(board.app.staticTexts["stake"].exists)
        XCTAssertFalse(board.offerDouble.exists)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C9-before-cube", to: self)
    }

    // MARK: C5

    @MainActor
    func testAnOfferOrAnswerThatCannotBeSavedKeepsTheLastSavedGame() throws {
        let board = BoardRobot()
        board.launch(fault: "write")
        board.offerDouble.tap()
        XCTAssertTrue(board.app.staticTexts["Change not saved."].waitForExistence(timeout: 5))
        XCTAssertEqual(board.status, "White to move")
        XCTAssertTrue(board.isAtBottom("White"))
        XCTAssertEqual(board.text("stake"), "Stake: 1 point")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C5-offer", to: self)

        board.launch(seedFile: Self.savedGame(Self.afterE4, stake: 1, nextDoubler: nil, pending: true), fault: "write")
        XCTAssertEqual(board.status, "White, answer the double")
        board.app.buttons["Take"].tap()
        XCTAssertTrue(board.app.staticTexts["Change not saved."].waitForExistence(timeout: 5))
        XCTAssertEqual(board.status, "White, answer the double")
        XCTAssertEqual(board.text("stake"), "Stake: 1 point")
        board.app.buttons["Decline"].tap()
        XCTAssertTrue(board.app.staticTexts["Change not saved."].exists)
        XCTAssertEqual(board.status, "White, answer the double")

        // With access restored, the offer is still waiting.
        board.launch()
        XCTAssertFalse(board.app.staticTexts["Change not saved."].exists)
        XCTAssertEqual(board.status, "White, answer the double")
        board.app.buttons["Take"].tap()
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertEqual(board.text("stake"), "Stake: 2 points")
    }
}
