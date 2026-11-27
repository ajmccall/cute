import XCTest

/// Captures and material on the running board: local-game C16 and C17, and C5 for a capture that can't be saved.
final class CapturesUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    // MARK: C16, C17

    @MainActor
    func testEachPlayersCapturesSitAtTheirEdgeAndTurnWithTheBoardIncludingDuringAResponse() throws {
        let board = BoardRobot()
        board.launch()
        XCTAssertEqual(board.captures("White"), "Captured by White: none")
        XCTAssertEqual(board.captures("Black"), "Captured by Black: none")
        XCTAssertFalse(board.advantage.exists)
        XCTAssertTrue(board.capturesAreBelowTheBoard("White"))
        XCTAssertTrue(board.capturesAreAboveTheBoard("Black"))

        board.tap("e2", "e4", "d7", "d5", "e4", "d5")
        XCTAssertEqual(board.status, "Black to move")
        XCTAssertEqual(board.captures("White"), "Captured by White: 1 pawn")
        XCTAssertEqual(board.captures("Black"), "Captured by Black: none")
        XCTAssertEqual(board.advantage.label, "White ahead by 1 in material")
        XCTAssertFalse(board.advantage.label.localizedCaseInsensitiveContains("point"))
        // The board has turned to Black: White's captures and the lead beside them are now at the top.
        XCTAssertTrue(board.isAtBottom("Black"))
        XCTAssertTrue(board.capturesAreAboveTheBoard("White"))
        XCTAssertTrue(board.capturesAreBelowTheBoard("Black"))
        XCTAssertTrue(board.isBeside(board.advantage, "White"))
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C16-C17", to: self)

        // Black offers: the board faces White, the responder, and the captures turn with it.
        board.offerDouble.tap()
        XCTAssertEqual(board.status, "White, answer the double")
        XCTAssertTrue(board.isAtBottom("White"))
        XCTAssertTrue(board.capturesAreBelowTheBoard("White"))
        XCTAssertTrue(board.capturesAreAboveTheBoard("Black"))
        XCTAssertTrue(board.isBeside(board.advantage, "White"))
        XCTAssertEqual(board.captures("White"), "Captured by White: 1 pawn")
        XCTAssertEqual(board.advantage.label, "White ahead by 1 in material")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C16-C17-response", to: self)

        // Taken: Black, the offerer, moves again, and the queen's recapture evens the material.
        board.app.buttons["Take"].tap()
        XCTAssertEqual(board.status, "Black to move")
        board.tap("d8", "d5")
        XCTAssertEqual(board.captures("Black"), "Captured by Black: 1 pawn")
        XCTAssertFalse(board.advantage.exists)

        board.launch()
        XCTAssertEqual(board.status, "White to move")
        XCTAssertEqual(board.captures("White"), "Captured by White: 1 pawn")
        XCTAssertEqual(board.captures("Black"), "Captured by Black: 1 pawn")
        XCTAssertFalse(board.advantage.exists)

        // Finished, the final board keeps its captures; the next game starts with none.
        board.tap("b1", "c3", "d5", "a2")
        XCTAssertEqual(board.captures("Black"), "Captured by Black: 2 pawns")
        board.app.buttons["Resign"].tap()
        board.app.alerts.firstMatch.buttons["Confirm"].tap()
        XCTAssertEqual(board.status, "Black wins · Resignation")
        XCTAssertEqual(board.captures("White"), "Captured by White: 1 pawn")
        XCTAssertEqual(board.captures("Black"), "Captured by Black: 2 pawns")
        XCTAssertEqual(board.advantage.label, "Black ahead by 1 in material")
        XCTAssertTrue(board.isBeside(board.advantage, "Black"))
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C16-C17-finished", to: self)

        board.app.buttons["Next game"].tap()
        XCTAssertEqual(board.status, "White to move")
        XCTAssertEqual(board.captures("White"), "Captured by White: none")
        XCTAssertEqual(board.captures("Black"), "Captured by Black: none")
        XCTAssertFalse(board.advantage.exists)
    }

    @MainActor
    func testCapturesAndTheLeadStayOnTheFinalBoardWhenTheMatchIsOver() throws {
        let board = BoardRobot()
        // Black to move, with White's captures of every kind matching what Black has lost, and White one point from
        // the target. Grouped pawn, knight, bishop, rook, queen, whatever order they were taken in.
        let fen = "r1b1k3/pppppp2/8/8/8/8/PPPPPPPP/RNBQKBNR b KQ -"
        board.launch(seedFile: #"{"version": 4, "position": "\#(fen)", "result": null, "stake": 1, "nextDoubler": null, "doublePending": false, "whiteTotal": 14, "blackTotal": 9, "captures": {"white": ["knight", "pawn", "queen", "knight", "rook", "bishop", "pawn"], "black": []}}"#)
        XCTAssertEqual(board.captures("White"), "Captured by White: 2 pawns, 2 knights, 1 bishop, 1 rook, 1 queen")
        XCTAssertEqual(board.captures("Black"), "Captured by Black: none")
        XCTAssertEqual(board.advantage.label, "White ahead by 25 in material")

        board.app.buttons["Resign"].tap()
        board.app.alerts.firstMatch.buttons["Confirm"].tap()
        XCTAssertEqual(board.text("matchResult"), "White wins the match, 15 to 9")
        XCTAssertEqual(board.captures("White"), "Captured by White: 2 pawns, 2 knights, 1 bishop, 1 rook, 1 queen")
        XCTAssertEqual(board.captures("Black"), "Captured by Black: none")
        XCTAssertEqual(board.advantage.label, "White ahead by 25 in material")
        XCTAssertTrue(board.isBeside(board.advantage, "White"))
        // Apart from the stake and the match score, and never in points.
        XCTAssertEqual(board.text("matchScore"), "White 15 points · Black 9 points · first to 15 points")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C16-C17-match-over", to: self)

        board.app.buttons["New match"].tap()
        XCTAssertEqual(board.captures("White"), "Captured by White: none")
        XCTAssertFalse(board.advantage.exists)
    }

    @MainActor
    func testAPromotionMovesTheLeadWithoutACaptureAndACapturedPromotedPieceShowsAsItsPromotedKind() throws {
        let board = BoardRobot()
        board.launch(seed: "3r3k/4P3/8/8/8/8/8/K7 w - -")
        XCTAssertEqual(board.advantage.label, "Black ahead by 4 in material")
        XCTAssertTrue(board.isBeside(board.advantage, "Black"))

        board.tap("e7", "e8")
        board.app.alerts.firstMatch.buttons["Queen"].tap()
        XCTAssertEqual(board.status, "Black to move · Check")
        XCTAssertEqual(board.captures("White"), "Captured by White: none")
        XCTAssertEqual(board.captures("Black"), "Captured by Black: none")
        XCTAssertEqual(board.advantage.label, "White ahead by 4 in material")
        XCTAssertTrue(board.isBeside(board.advantage, "White"))

        board.tap("d8", "e8")
        XCTAssertEqual(board.captures("Black"), "Captured by Black: 1 queen")
        XCTAssertEqual(board.advantage.label, "Black ahead by 5 in material")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C16-C17-promotion", to: self)
    }

    @MainActor
    func testAnEnPassantCaptureShowsAsAPawn() throws {
        let board = BoardRobot()
        board.launch(seed: "4k3/8/8/8/3p4/8/4P3/4K3 w - -")
        board.tap("e2", "e4", "d4", "e3")
        XCTAssertEqual(board.square("e4").label, "e4, Empty")
        XCTAssertEqual(board.captures("Black"), "Captured by Black: 1 pawn")
        XCTAssertEqual(board.advantage.label, "Black ahead by 1 in material")
        // +1 follows Black's one captured pawn in the same row, not at the far edge (product owner, on #39).
        XCTAssertTrue(board.isDirectlyAfterCaptures(board.advantage, "Black"),
                      "\(board.advantage.frame) after \(board.capturesElement("Black").frame)")
        try board.auditAccessibility()
        board.attachScreenshot(named: "local-game-C16-C17-one-capture", to: self)
    }

    // MARK: C5, C16

    @MainActor
    func testACaptureThatCannotBeSavedIsNotShown() throws {
        let board = BoardRobot()
        board.launch(seed: "rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -", fault: "write")
        board.tap("e4", "d5")

        XCTAssertTrue(board.app.staticTexts["Change not saved."].waitForExistence(timeout: 5))
        XCTAssertEqual(board.captures("White"), "Captured by White: none")
        XCTAssertFalse(board.advantage.exists)
        try board.auditAccessibility()
        board.app.buttons["retrySave"].tap()
        XCTAssertEqual(board.captures("White"), "Captured by White: none")

        board.launch()
        XCTAssertEqual(board.square("d5").label, "d5, Black pawn")
        XCTAssertEqual(board.captures("White"), "Captured by White: none")
    }
}

extension BoardRobot {
    /// The spoken text of a colour's captures, "White" or "Black", once it appears.
    func captures(_ side: String) -> String {
        let element = capturesElement(side)
        XCTAssertTrue(element.waitForExistence(timeout: 5), "captures-\(side)")
        return element.label
    }

    func capturesElement(_ side: String) -> XCUIElement {
        app.descendants(matching: .any)["captures-\(side.lowercased())"]
    }

    /// The material lead, shown beside the leading colour's captures.
    var advantage: XCUIElement { app.descendants(matching: .any)["advantage"] }

    var boardFrame: CGRect { app.descendants(matching: .any)["board"].frame }

    func capturesAreAboveTheBoard(_ side: String) -> Bool {
        capturesElement(side).frame.maxY <= boardFrame.minY
    }

    func capturesAreBelowTheBoard(_ side: String) -> Bool {
        capturesElement(side).frame.minY >= boardFrame.maxY
    }

    /// Whether an element follows a colour's captures in the same row, close after them rather than at the far edge:
    /// for captures that fit on one line, such as a single piece.
    func isDirectlyAfterCaptures(_ element: XCUIElement, _ side: String) -> Bool {
        let captures = capturesElement(side).frame
        let frame = element.frame
        let window = app.windows.firstMatch.frame
        return frame.midY > captures.minY && frame.midY < captures.maxY
            && frame.minX > captures.minX
            && frame.maxX < window.minX + window.width * 0.75
    }

    /// Whether an element sits on the same side of the board as a colour's captures.
    func isBeside(_ element: XCUIElement, _ side: String) -> Bool {
        let captures = capturesElement(side).frame
        let frame = element.frame
        return (frame.midY < boardFrame.minY) == (captures.midY < boardFrame.minY)
            && frame.minY < captures.maxY && frame.maxY > captures.minY
    }
}
