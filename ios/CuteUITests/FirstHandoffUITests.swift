import XCTest

/// docs/testing.md, First handoff: local-game C1, C2 and C3 on the running board.
final class FirstHandoffUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testFirstHandoff() throws {
        let board = BoardRobot()
        board.launch()

        // C1: the opening position, White at the bottom and White to move.
        board.expectStatus("White to move")
        XCTAssertTrue(board.isAtBottom("White"))
        board.expectSquare("e2", "e2, White pawn")
        board.expectSquare("e4", "e4, Empty")
        board.expectSquare("d8", "d8, Black queen")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C1", to: self)

        // C2: select, reselect, and only legal destinations.
        board.tap("e2")
        board.expectValue(of: "e2", "Selected")
        board.expectLegalDestinations(["e3", "e4"])
        board.tap("g1")
        board.expectValue(of: "g1", "Selected")
        board.expectValue(of: "e2", "")
        board.expectLegalDestinations(["f3", "h3"])
        board.attachScreenshot(named: "local-game-C2", to: self)

        // An illegal destination leaves position and turn unchanged.
        board.tap("g3")
        board.expectStatus("White to move")
        board.expectSquare("g1", "g1, White knight")
        board.expectSquare("g3", "g3, Empty")

        // C3: the move commits at once and Black's pieces come to the bottom.
        board.tap("g1", "f3")
        board.expectStatus("Black to move")
        board.expectSquare("f3", "f3, White knight")
        board.expectSquare("g1", "g1, Empty")
        XCTAssertTrue(board.isAtBottom("Black"))
        XCTAssertFalse(board.app.alerts.firstMatch.exists)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C3", to: self)

        // Leave and return.
        XCUIDevice.shared.press(.home)
        board.app.activate()
        board.expectStatus("Black to move")
        board.expectSquare("f3", "f3, White knight")

        // C1: relaunch shows the last committed position and turn, with the same legal continuations.
        board.launch()
        board.expectStatus("Black to move")
        XCTAssertTrue(board.isAtBottom("Black"))
        board.expectSquare("f3", "f3, White knight")
        board.tap("e7")
        board.expectLegalDestinations(["e5", "e6"])
        board.tap("e5")
        board.expectStatus("White to move")
        board.expectSquare("e5", "e5, Black pawn")
        XCTAssertTrue(board.isAtBottom("White"))
    }
}
