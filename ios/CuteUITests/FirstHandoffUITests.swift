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
        XCTAssertEqual(board.status, "White to move")
        XCTAssertTrue(board.isAtBottom("White"))
        XCTAssertEqual(board.square("e2").label, "e2, White pawn")
        XCTAssertEqual(board.square("e4").label, "e4, Empty")
        XCTAssertEqual(board.square("d8").label, "d8, Black queen")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C1", to: self)

        // C2: select, reselect, and only legal destinations.
        board.tap("e2")
        XCTAssertEqual(board.value(of: "e2"), "Selected")
        XCTAssertEqual(board.legalDestinations, ["e3", "e4"])
        board.tap("g1")
        XCTAssertEqual(board.value(of: "g1"), "Selected")
        XCTAssertEqual(board.value(of: "e2"), "")
        XCTAssertEqual(board.legalDestinations, ["f3", "h3"])
        board.attachScreenshot(named: "local-game-C2", to: self)

        // An illegal destination leaves position and turn unchanged.
        board.tap("g3")
        XCTAssertEqual(board.status, "White to move")
        XCTAssertEqual(board.square("g1").label, "g1, White knight")
        XCTAssertEqual(board.square("g3").label, "g3, Empty")

        // C3: the move commits at once and Black's pieces come to the bottom.
        board.tap("g1", "f3")
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertEqual(board.square("f3").label, "f3, White knight")
        XCTAssertEqual(board.square("g1").label, "g1, Empty")
        XCTAssertTrue(board.isAtBottom("Black"))
        XCTAssertFalse(board.app.alerts.firstMatch.exists)
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C3", to: self)

        // Leave and return.
        XCUIDevice.shared.press(.home)
        board.app.activate()
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertEqual(board.square("f3").label, "f3, White knight")

        // C1: relaunch shows the last committed position and turn, with the same legal continuations.
        board.launch()
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertTrue(board.isAtBottom("Black"))
        XCTAssertEqual(board.square("f3").label, "f3, White knight")
        board.tap("e7")
        XCTAssertEqual(board.legalDestinations, ["e5", "e6"])
        board.tap("e5")
        XCTAssertEqual(board.status, "White to move")
        XCTAssertEqual(board.square("e5").label, "e5, Black pawn")
        XCTAssertTrue(board.isAtBottom("White"))
    }
}
