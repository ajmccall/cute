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
        XCTAssertTrue(board.app.buttons["retrySave"].exists)
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertEqual(board.square("e7").label, "e7, Black pawn")
        XCTAssertEqual(board.square("e5").label, "e5, Empty")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C5-save", to: self)

        // Retrying while saving still fails keeps the notice and the saved position.
        board.app.buttons["retrySave"].tap()
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
        XCTAssertTrue(board.app.buttons["retryRead"].exists)
        XCTAssertFalse(board.app.buttons["square-e2"].exists)
        XCTAssertFalse(board.app.staticTexts["status"].exists)
        XCTAssertTrue(board.app.buttons["New game"].exists)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C5-read", to: self)

        board.app.buttons["retryRead"].tap()
        XCTAssertTrue(board.app.staticTexts["Couldn’t open the saved game."].exists)

        board.launch()
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertEqual(board.square("f3").label, "f3, White knight")
    }

    @MainActor
    func testAfterAFailedReadNewGameReplacesTheSavedGameOnlyOnConfirmation() throws {
        let board = BoardRobot()
        board.launch(seed: Self.saved)
        board.launch(fault: "read")
        let notice = board.app.staticTexts["Couldn’t open the saved game."]
        XCTAssertTrue(notice.waitForExistence(timeout: 5))

        board.app.buttons["New game"].tap()
        let alert = board.app.alerts["Replace this game?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Cancel"].tap()
        XCTAssertTrue(notice.exists)

        board.app.buttons["New game"].tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Confirm"].tap()
        XCTAssertEqual(board.status, "White to move")
        XCTAssertEqual(board.square("g1").label, "g1, White knight")
        try board.auditAccessibility()

        board.launch()
        XCTAssertEqual(board.status, "White to move")
        XCTAssertEqual(board.square("f3").label, "f3, Empty")
    }

    @MainActor
    func testWhenNewGameCannotBeSavedAfterAFailedReadNoBoardIsShownAndBothFailuresAreIdentified() throws {
        let board = BoardRobot()
        board.launch(seed: Self.saved)
        board.launch(fault: "read,write")
        let readNotice = board.app.staticTexts["Couldn’t open the saved game."]
        XCTAssertTrue(readNotice.waitForExistence(timeout: 5))

        board.app.buttons["New game"].tap()
        let alert = board.app.alerts["Replace this game?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Confirm"].tap()

        let writeNotice = board.app.staticTexts["Change not saved."]
        XCTAssertTrue(writeNotice.waitForExistence(timeout: 5))
        XCTAssertTrue(readNotice.exists)
        XCTAssertTrue(board.app.buttons["retrySave"].exists)
        XCTAssertTrue(board.app.buttons["retryRead"].exists)
        XCTAssertFalse(board.app.buttons["square-e2"].exists)
        XCTAssertFalse(board.app.staticTexts["status"].exists)
        XCTAssertFalse(board.app.buttons["Resign"].exists)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C5-read-then-save", to: self)

        board.app.buttons["retrySave"].tap()
        XCTAssertTrue(writeNotice.exists)
        XCTAssertTrue(readNotice.exists)
        XCTAssertFalse(board.app.buttons["square-e2"].exists)

        // With access restored, the saved game was never replaced.
        board.launch()
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertEqual(board.square("f3").label, "f3, White knight")
    }
}
