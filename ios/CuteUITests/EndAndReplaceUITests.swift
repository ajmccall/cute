import XCTest

/// docs/testing.md, End and replace: local-game C4 and C13 on the running board.
final class EndAndReplaceUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testFoolsMateFreezesTheBoardThroughRelaunchAndNextGameNeedsNoConfirmation() throws {
        let board = BoardRobot()
        board.launch()

        board.tap("f2", "f3", "e7", "e5", "g2", "g4", "d8", "h4")
        XCTAssertEqual(board.status, "Black wins · Checkmate")
        XCTAssertEqual(board.square("h4").label, "h4, Black queen")
        XCTAssertFalse(board.app.buttons["Resign"].exists)
        XCTAssertFalse(board.app.buttons["Agree draw"].exists)
        board.tap("e2")
        XCTAssertEqual(board.value(of: "e2"), "")
        XCTAssertEqual(board.legalDestinations, [])
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C4-checkmate", to: self)

        board.launch()
        XCTAssertEqual(board.status, "Black wins · Checkmate")
        XCTAssertEqual(board.square("h4").label, "h4, Black queen")

        board.app.buttons["Next game"].tap()
        XCTAssertFalse(board.app.alerts.firstMatch.waitForExistence(timeout: 1))
        XCTAssertEqual(board.status, "White to move")
        XCTAssertEqual(board.square("h4").label, "h4, Empty")
        XCTAssertEqual(board.square("d8").label, "d8, Black queen")
    }

    @MainActor
    func testSeededAutomaticDraws() throws {
        let board = BoardRobot()

        board.launch(seed: "7k/4Q3/6K1/8/8/8/8/8 w - -")
        board.tap("e7", "f7")
        XCTAssertEqual(board.status, "Draw · Stalemate")

        board.launch(seed: "4k3/8/8/8/8/8/8/N2rK3 w - -")
        board.tap("e1", "d1")
        XCTAssertEqual(board.status, "Draw · Insufficient material")
        try board.auditAccessibility()

        // Two knights against a king is not a draw.
        board.launch(seed: "4k3/8/8/8/8/8/8/NN1rK3 w - -")
        board.tap("e1", "d1")
        XCTAssertEqual(board.status, "Black to move")
    }

    @MainActor
    func testResignationCancelThenConfirm() throws {
        let board = BoardRobot()
        board.launch()
        board.tap("e2", "e4")
        // Audited before the stock alert opens: the system draws the alert itself.
        try board.auditAccessibility()

        board.app.buttons["Resign"].tap()
        let alert = board.app.alerts["Resign as Black?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Cancel"].tap()
        XCTAssertEqual(board.status, "Black to move")

        board.app.buttons["Resign"].tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Confirm"].tap()
        XCTAssertEqual(board.status, "White wins · Resignation")
        board.tap("e7")
        XCTAssertEqual(board.value(of: "e7"), "")
        board.attachScreenshot(named: "local-game-C4-resignation", to: self)
    }

    @MainActor
    func testAgreedDrawCancelThenConfirm() throws {
        let board = BoardRobot()
        board.launch()

        board.app.buttons["Agree draw"].tap()
        let alert = board.app.alerts["Do both players agree to a draw?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Cancel"].tap()
        XCTAssertEqual(board.status, "White to move")

        board.app.buttons["Agree draw"].tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Confirm"].tap()
        XCTAssertEqual(board.status, "Draw · Agreement")
        try board.auditAccessibility()
    }

    @MainActor
    func testReplacingAMatchUnderWayNeedsConfirmation() throws {
        let board = BoardRobot()
        board.launch()
        board.tap("e2", "e4")
        // Audited before the stock alert opens: the system draws the alert itself.
        try board.auditAccessibility()

        board.app.buttons["New match"].tap()
        let alert = board.app.alerts["Replace this match?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        board.attachScreenshot(named: "local-game-C4-replace", to: self)
        alert.buttons["Cancel"].tap()
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertEqual(board.square("e4").label, "e4, White pawn")

        board.app.buttons["New match"].tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Confirm"].tap()
        XCTAssertEqual(board.status, "White to move")
        XCTAssertEqual(board.square("e4").label, "e4, Empty")
        XCTAssertEqual(board.square("e2").label, "e2, White pawn")
    }
}
