import XCTest

/// docs/testing.md, Failed save/read: local-game C5 on the running board, with failures injected by launch setup.
final class FailedSaveReadUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    static let saved = "rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R b KQkq -"

    @MainActor
    func testAFailedSaveKeepsTheLastSavedGame() throws {
        let board = BoardRobot()
        board.launch(seed: Self.saved, fault: "write")

        board.tap("e7", "e5")
        XCTAssertTrue(board.app.staticTexts["Change not saved."].waitForExistence(timeout: 5))
        XCTAssertTrue(board.app.buttons["Retry"].exists)
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertEqual(board.square("e7").label, "e7, Black pawn")
        XCTAssertEqual(board.square("e5").label, "e5, Empty")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C5-save", to: self)

        // Retrying while saving still fails keeps the notice and the saved position.
        board.app.buttons["Retry"].tap()
        XCTAssertTrue(board.app.staticTexts["Change not saved."].exists)
        XCTAssertEqual(board.square("e5").label, "e5, Empty")

        // With access restored, reopening shows the last saved position.
        board.launch()
        XCTAssertFalse(board.app.staticTexts["Change not saved."].exists)
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertEqual(board.square("f3").label, "f3, White knight")
        XCTAssertEqual(board.square("e7").label, "e7, Black pawn")
    }

    @MainActor
    func testAFailedReadShowsNoFreshGameUntilTheSavedGameOpens() throws {
        let board = BoardRobot()
        board.launch(seed: Self.saved)
        board.launch(fault: "read")

        XCTAssertTrue(board.app.staticTexts["Couldn’t open the saved game."].waitForExistence(timeout: 5))
        XCTAssertTrue(board.app.buttons["Retry"].exists)
        XCTAssertFalse(board.app.buttons["square-e2"].exists)
        XCTAssertFalse(board.app.staticTexts["status"].exists)
        XCTAssertFalse(board.app.buttons["New game"].exists)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C5-read", to: self)

        board.app.buttons["Retry"].tap()
        XCTAssertTrue(board.app.staticTexts["Couldn’t open the saved game."].exists)

        board.launch()
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertEqual(board.square("f3").label, "f3, White knight")
    }
}
