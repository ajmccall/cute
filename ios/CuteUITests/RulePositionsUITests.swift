import XCTest

/// docs/testing.md, Rule positions: local-game C2 on the running board, from seeded positions.
final class RulePositionsUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testPinnedPieceAndCastling() throws {
        let board = BoardRobot()

        // A pinned bishop has no legal destinations.
        board.launch(seed: "4k3/4r3/8/8/8/8/4B3/4K3 w - -")
        board.tap("e2")
        board.expectValue(of: "e2", "Selected")
        board.expectLegalDestinations([])

        // Castling through check is not offered, and the rights are restored on relaunch;
        // legal castling moves king and rook together.
        board.launch(seed: "4kr2/8/8/8/8/8/8/R3K2R w KQ -")
        board.launch()
        board.tap("e1")
        board.expectLegalDestinations(["c1", "d1", "d2", "e2"])
        board.tap("c1")
        board.expectSquare("c1", "c1, White king")
        board.expectSquare("d1", "d1, White rook")
        board.expectStatus("Black to move")
        try board.auditAccessibility()
    }

    @MainActor
    func testEnPassantRestoredAfterRelaunchAndExpiring() throws {
        let board = BoardRobot()
        board.launch(seed: "4k3/8/8/8/3p4/8/4P3/4K3 w - -")
        board.tap("e2", "e4")

        // The right survives a relaunch.
        board.launch()
        board.tap("d4")
        board.expectLegalDestinations(["d3", "e3"])
        board.attachScreenshot(named: "local-game-C2-en-passant", to: self)
        board.tap("e3")
        board.expectSquare("e4", "e4, Empty")
        board.expectSquare("e3", "e3, Black pawn")

        // Expiry: the right lasts one move only.
        board.launch(seed: "4k3/8/8/8/3p4/8/4P3/4K3 w - -")
        board.tap("e2", "e4", "e8", "f8", "e1", "f1", "d4")
        board.expectLegalDestinations(["d3"])
        try board.auditAccessibility()
    }

    @MainActor
    func testPromotionCancelThenUnderpromotion() throws {
        let board = BoardRobot()
        board.launch(seed: "3r3k/4P2p/8/8/8/8/8/K7 w - -")
        // Audited before the stock alert opens: the system draws the alert itself.
        try board.auditAccessibility()

        board.tap("e7", "e8")
        let choice = board.app.buttons["Knight"]
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        for name in ["Queen", "Rook", "Bishop", "Knight"] {
            XCTAssertTrue(board.app.buttons[name].exists, name)
        }
        board.attachScreenshot(named: "local-game-C2-promotion", to: self)

        // Cancelling changes neither position nor turn, and keeps the pawn selected with its destinations.
        board.app.buttons["Cancel"].tap()
        XCTAssertFalse(choice.waitForExistence(timeout: 1))
        board.expectStatus("White to move")
        board.expectSquare("e7", "e7, White pawn")
        board.expectSquare("e8", "e8, Empty")
        board.expectValue(of: "e7", "Selected")
        board.expectLegalDestinations(["d8", "e8"])

        // Underpromotion to a knight on a capture.
        board.tap("e7", "d8")
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        choice.tap()
        board.expectSquare("d8", "d8, White knight")
        board.expectSquare("e7", "e7, Empty")
        board.expectStatus("Black to move")
    }
}
