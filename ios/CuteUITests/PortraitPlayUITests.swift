import XCTest

/// local-game C18: device rotation is independent of the pass-and-play board orientation.
final class PortraitPlayUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testRotatedPhoneStaysPortraitWhilePlayersMoveAndAnswerADouble() throws {
        let board = BoardRobot()
        board.launch()
        board.expectStatus("White to move")
        XCTAssertTrue(board.isAtBottom("White"))
        assertPortrait(board.app)

        XCUIDevice.shared.orientation = .landscapeLeft
        assertPortrait(board.app)
        board.tap("e2", "e4")
        XCTAssertEqual(board.square("e4").label, "e4, White pawn")
        board.expectStatus("Black to move")
        XCTAssertTrue(board.isAtBottom("Black"))
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C18-move", to: self)

        XCUIDevice.shared.orientation = .landscapeRight
        assertPortrait(board.app)
        board.offerDouble.tap()
        board.expectStatus("White, answer the double")
        XCTAssertTrue(board.isAtBottom("White"))
        XCTAssertEqual(board.square("e4").label, "e4, White pawn")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C18-response", to: self)

        board.app.buttons["Take"].tap()
        board.expectStatus("Black to move")
        XCTAssertTrue(board.isAtBottom("Black"))
        assertPortrait(board.app)
        board.tap("e7", "e5")
        board.expectStatus("White to move")
        XCTAssertEqual(board.square("e5").label, "e5, Black pawn")
        XCTAssertTrue(board.isAtBottom("White"))
        assertPortrait(board.app)
    }

    @MainActor
    private func assertPortrait(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertLessThan(window.frame.width, window.frame.height, file: file, line: line)
    }
}
