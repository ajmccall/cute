import XCTest

final class AutomaticDoublesUITests: XCTestCase {
    @MainActor func testPreAutomaticV4PendingOfferAndSubsequentDecision() throws {
        let board = BoardRobot()
        let seed = #"{"version":4,"position":"4k2r/8/8/8/8/8/4P3/R3K3 w - -","result":null,"stake":2,"nextDoubler":"white","doublePending":true,"whiteTotal":3,"blackTotal":2,"captures":{"white":[],"black":[]}}"#
        board.launch(seedFile: seed)
        board.expectStatus("Black, answer the double")
        board.expectText("stake", "Stake: 2 points")
        board.app.buttons["Take"].tap()
        board.expectStatus("White to move")
        board.expectText("stake", "Stake: 4 points")
        board.expectText("doubleRight", "Only Black can offer")
        board.app.switches["Automatic doubles"].tap()
        board.tap("e2", "e4")
        board.expectStatus("White, continue at 8 points?")
        board.launch()
        board.expectStatus("White, continue at 8 points?")
        try board.auditAccessibility()
    }

    @MainActor func testOpeningThenEndgameInSameGame() throws {
        let board = BoardRobot()
        board.launch(seed: "r3k2r/8/8/8/8/8/4P3/R2QK2R w - -")
        board.app.switches["Automatic doubles"].tap()
        board.tap("e2", "e4")
        board.expectStatus("White, continue at 2 points?")
        board.app.buttons["Continue"].tap(); board.app.buttons["Continue"].tap()
        board.tap("a8", "a1")
        board.expectStatus("Black, continue at 4 points?")
        board.expectSquare("a1", "a1, Black rook")
        board.app.buttons["Continue"].tap(); board.app.buttons["Continue"].tap()
        board.expectText("stake", "Stake: 4 points")
        try board.auditAccessibility()
    }

    @MainActor func testPromotionTriggersAutomaticDecision() throws {
        let board = BoardRobot()
        board.launch(seed: "4k2r/P7/8/8/8/8/8/R3K3 w - -")
        board.app.switches["Automatic doubles"].tap()
        board.tap("a7", "a8")
        board.app.buttons["Knight"].tap()
        board.expectSquare("a8", "a8, White knight")
        board.expectStatus("White, continue at 2 points?")
        try board.auditAccessibility()
    }

    @MainActor func testSwitchOffAfterAwardKeepsScore() throws {
        let board = BoardRobot()
        board.launch(seed: "4k2r/8/8/8/8/8/4P3/R3K3 w - -")
        board.app.switches["Automatic doubles"].tap()
        board.tap("e2", "e4")
        board.app.buttons["Continue"].tap(); board.app.buttons["Stop"].tap()
        board.expectText("award", "White earns 1 point.")
        board.app.switches["Automatic doubles"].tap()
        board.expectText("award", "White earns 1 point.")
        board.launch()
        XCTAssertEqual(board.app.switches["Automatic doubles"].value as? String, "0")
        board.expectText("award", "White earns 1 point.")
        try board.auditAccessibility()
    }

    @MainActor func testEndgameRetiresOpeningAndPreservesVoluntaryOfferRights() throws {
        let board = BoardRobot()
        let fen = "4k2r/8/8/8/8/8/4P3/R3K3 w - -"
        board.launch(seedFile: DoublingUITests.savedGame(fen, stake: 2, nextDoubler: "white"))
        board.app.switches["Automatic doubles"].tap()
        board.tap("e2", "e4")
        board.expectStatus("White, continue at 4 points?")
        try board.auditAccessibility()
        board.app.buttons["Continue"].tap(); board.app.buttons["Continue"].tap()
        board.expectStatus("Black to move")
        board.expectText("doubleRight", "Only White can offer")
        XCTAssertFalse(board.offerDouble.isEnabled)
        board.tap("h8", "h7")
        board.expectStatus("White to move")
        XCTAssertTrue(board.offerDouble.isEnabled)
        board.expectText("stake", "Stake: 4 points")
    }

    @MainActor func testCheckmatePrecedesAutomaticPromptAndBothStopCanDrawTheMatch() throws {
        let board = BoardRobot()
        board.launch(seed: "7k/8/5KQ1/8/8/8/8/8 w - -")
        board.app.switches["Automatic doubles"].tap()
        board.tap("g6", "g7")
        board.expectStatus("White wins · Checkmate")
        XCTAssertFalse(board.app.buttons["Continue"].exists)
        try board.auditAccessibility()

        let seed = #"{"version": 3, "position": "4k2r/8/8/8/8/8/4P3/R3K3 w - -", "result": null, "stake": 2, "nextDoubler": "white", "doublePending": false, "whiteTotal": 14, "blackTotal": 14}"#
        board.launch(seedFile: seed)
        board.tap("e2", "e4")
        board.expectStatus("White, continue at 4 points?")
        board.app.buttons["Stop"].tap(); board.app.buttons["Stop"].tap()
        board.expectStatus("Draw · Both stopped at automatic double")
        board.expectText("award", "Each player earns 1 point.")
        board.expectText("matchResult", "Match drawn, 15 to 15")
        XCTAssertFalse(board.app.switches["Automatic doubles"].exists)
        try board.auditAccessibility()
        board.launch()
        board.expectText("matchResult", "Match drawn, 15 to 15")
        XCTAssertFalse(board.app.switches["Automatic doubles"].exists)
    }

    @MainActor func testOpeningMilestoneAndStakeCapOnRealBoard() throws {
        let board = BoardRobot()
        board.launch(seed: "r2qk2r/pppppppp/2n2n2/8/8/2N2N2/PPPPPPPP/R1BQKB1R w KQkq -")
        board.app.switches["Automatic doubles"].tap()
        board.tap("g2", "g3")
        board.expectStatus("White, continue at 2 points?")
        try board.auditAccessibility()
        board.app.buttons["Continue"].tap(); board.app.buttons["Continue"].tap()
        board.tap("g7", "g6")
        board.expectStatus("White to move")
        board.expectText("stake", "Stake: 2 points")

        let fen = "4k2r/8/8/8/8/8/4P3/R3K3 w - -"
        board.launch(seedFile: DoublingUITests.savedGame(fen, stake: 32, nextDoubler: "white"))
        board.tap("e2", "e4")
        board.expectStatus("White, continue at 64 points?")
        board.app.buttons["Continue"].tap(); board.app.buttons["Continue"].tap()
        board.expectStatus("Black to move")
        board.expectText("stake", "Stake: 64 points")
        XCTAssertFalse(board.offerDouble.isEnabled)
        try board.auditAccessibility()

        board.launch(seedFile: DoublingUITests.savedGame(fen, stake: 64, nextDoubler: "white"))
        board.tap("e2", "e4")
        board.expectStatus("Black to move")
        board.expectText("stake", "Stake: 64 points")
        XCTAssertFalse(board.app.buttons["Continue"].exists)
        try board.auditAccessibility()
    }

    @MainActor func testFailedSaveRestoresEachLastCommittedAutomaticStep() throws {
        for step in 0...2 {
            let board = BoardRobot()
            board.launch(seed: "4k2r/8/8/8/8/8/4P3/R3K3 w - -")
            board.app.switches["Automatic doubles"].tap()
            if step > 0 { board.tap("e2", "e4") }
            if step > 1 { board.app.buttons["Continue"].tap() }
            board.launch(fault: "write")
            if step == 0 { board.tap("e2", "e4") }
            else { board.app.buttons["Continue"].tap() }
            XCTAssertTrue(board.app.staticTexts["Change not saved."].waitForExistence(timeout: 5))
            let status = step == 0 ? "White to move" : (step == 1 ? "White, continue at 2 points?" : "Black, continue at 2 points?")
            board.expectStatus(status)
            board.launch()
            board.expectStatus(status)
            if step > 0 { XCTAssertTrue(board.isAtBottom(step == 1 ? "White" : "Black")) }
            try board.auditAccessibility()
        }
    }

    @MainActor func testSwitchCanBeEnabledDuringExistingGameAfterVoluntaryTake() throws {
        let board = BoardRobot()
        board.launch(seed: "4k2r/8/8/8/8/8/4P3/R3K3 w - -")
        let toggle = board.app.switches["Automatic doubles"]
        XCTAssertEqual(toggle.value as? String, "0")
        board.offerDouble.tap()
        XCTAssertFalse(toggle.isEnabled)
        board.app.buttons["Take"].tap()
        board.tap("e2", "e4")
        board.expectStatus("Black to move")
        board.expectText("stake", "Stake: 2 points")
        toggle.tap()
        board.tap("h8", "h7")
        board.expectStatus("Black, continue at 4 points?")
        board.expectText("stake", "Stake: 2 points")
        try board.auditAccessibility()
    }

    @MainActor func testStoppingOutcomesOnRealBoard() throws {
        for (first, second, status, award) in [
            ("Continue", "Stop", "White wins · Opponent stopped at automatic double", "White earns 1 point."),
            ("Stop", "Continue", "Black wins · Opponent stopped at automatic double", "Black earns 1 point."),
            ("Stop", "Stop", "Draw · Both stopped at automatic double", "Each player earns half a point.")
        ] {
            let board = BoardRobot()
            board.launch(seed: "4k2r/8/8/8/8/8/4P3/R3K3 w - -")
            board.app.switches["Automatic doubles"].tap()
            board.tap("e2", "e4")
            board.expectStatus("White, continue at 2 points?")
            board.app.buttons[first].tap()
            board.expectStatus("Black, continue at 2 points?")
            board.app.buttons[second].tap()
            board.expectStatus(status)
            board.expectText("award", award)
            board.launch()
            board.expectStatus(status)
            board.expectText("award", award)
            try board.auditAccessibility()
        }
    }

    @MainActor func testSwitchEnablesDecisionOnRealBoard() throws {
        let board = BoardRobot()
        board.launch(seed: "4k2r/8/8/8/8/8/4P3/R3K3 w - -")
        let toggle = board.app.switches["Automatic doubles"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        XCTAssertEqual(toggle.value as? String, "0")
        toggle.tap()
        board.tap("e2", "e4")
        board.expectStatus("White, continue at 2 points?")
        board.expectText("automaticEffects", "If both continue, play for 2 points. If only one continues, they win 1 point. If both stop, it’s a draw and each earns half a point.")
        board.attachScreenshot(named: "automatic-first-prompt", to: self)
        XCTAssertTrue(board.isAtBottom("White"))
        XCTAssertFalse(toggle.isEnabled)
        for action in ["Offer double", "Resign", "Agree draw", "New match"] {
            XCTAssertFalse(board.app.buttons[action].exists, action)
        }
        board.tap("h8", "h7")
        board.expectSquare("h8", "h8, Black rook")
        try board.auditAccessibility()
        board.launch()
        XCTAssertEqual(toggle.value as? String, "1")
        board.expectStatus("White, continue at 2 points?")
        board.app.buttons["Continue"].tap()
        board.expectStatus("Black, continue at 2 points?")
        board.expectText("automaticEffects", "If both continue, play for 2 points. If only one continues, they win 1 point. If both stop, it’s a draw and each earns half a point.")
        XCTAssertFalse(board.app.staticTexts["White chose Continue"].exists)
        XCTAssertTrue(board.isAtBottom("Black"))
        board.launch()
        board.expectStatus("Black, continue at 2 points?")
        board.app.buttons["Continue"].tap()
        board.expectStatus("Black to move")
        board.expectText("stake", "Stake: 2 points")
        board.launch()
        board.expectStatus("Black to move")
        board.expectText("stake", "Stake: 2 points")
        board.attachScreenshot(named: "automatic-continued", to: self)
    }
}
