import XCTest

/// Drives the running board the way a player does, in a scenario with its own current-game file.
@MainActor
struct BoardRobot {
    let app = XCUIApplication()
    /// The scenario's own current-game file, kept across relaunches within the scenario.
    let gameFile = "uitest-\(UUID().uuidString).json"

    /// Launches the app on this scenario's game, optionally seeding a position or a whole saved file,
    /// or failing one store operation.
    func launch(seed fen: String? = nil, seedFile: String? = nil, fault: String? = nil) {
        app.terminate()
        app.launchEnvironment = ["CUTE_UITEST_GAME_FILE": gameFile]
        if let fen { app.launchEnvironment["CUTE_UITEST_SEED_FEN"] = fen }
        if let seedFile { app.launchEnvironment["CUTE_UITEST_SEED_FILE"] = seedFile }
        if let fault { app.launchEnvironment["CUTE_UITEST_FAULT"] = fault }
        app.launch()
    }

    func square(_ coordinate: String) -> XCUIElement {
        app.buttons["square-\(coordinate)"]
    }

    var offerDouble: XCUIElement { app.buttons["Offer double"] }

    /// The label of the text with this identifier, such as "stake" or "award", once it appears.
    func text(_ identifier: String) -> String {
        let element = app.staticTexts[identifier]
        XCTAssertTrue(element.waitForExistence(timeout: 5), identifier)
        return element.label
    }

    func tap(_ coordinates: String...) {
        for coordinate in coordinates {
            square(coordinate).tap()
        }
    }

    var status: String {
        let element = app.staticTexts["status"]
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        return element.label
    }

    func value(of coordinate: String) -> String {
        (square(coordinate).value as? String) ?? ""
    }

    /// Squares currently marked as legal destinations, in coordinate order.
    var legalDestinations: [String] {
        app.buttons.matching(NSPredicate(format: "value == %@", "Legal destination")).allElementsBoundByIndex
            .map { $0.identifier.replacingOccurrences(of: "square-", with: "") }
            .sorted()
    }

    /// Whether the given colour's back rank is drawn at the bottom of the board.
    func isAtBottom(_ color: String) -> Bool {
        square("e1").frame.minY > square("e8").frame.minY ? color == "White" : color == "Black"
    }

    func attachScreenshot(named name: String, to testCase: XCTestCase) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        testCase.add(attachment)
    }

    func auditAccessibility() throws {
        let window = app.windows.firstMatch.frame
        try app.performAccessibilityAudit { issue in
            // Stock bordered buttons are reported as "partially" supporting Dynamic Type, though their labels
            // grow and wrap up to the largest accessibility size (checked by screenshot at
            // accessibility-extra-extra-extra-large).
            // A game action dimmed because it can't be used now, such as Offer double for a side not entitled
            // to it, keeps the stock disabled look; WCAG 1.4.3 sets no contrast for inactive controls.
            // A half is shown as ½ and spoken in words, "half a point" or "and a half" (local-game Interface text);
            // the audit measures the longer spoken label against the shown text and reports it clipped.
            // The material lead is shown as +N and spoken in words, "{side} ahead by {N} in material", and is
            // reported clipped in the same way.
            // A game action cut off by the bottom of the screen, which the player scrolls to (as when "Change not
            // saved." and both colours' captures push the actions down), is measured against what the edge cuts off
            // and reported as nearly passing contrast; scrolled into view, the audit reports nothing on it. Only that
            // near miss is ignored: a contrast failure on a cut-off action still fails the test.
            // Every other issue fails the test.
            let isGameAction = issue.element?.elementType == .button
                && Self.gameActions.contains(issue.element?.label ?? "")
            let isSpokenHalfPoint = issue.auditType == .textClipped
                && Self.textsWithHalves.contains(issue.element?.identifier ?? "")
                && issue.element?.label.contains("half") == true
            let isSpokenLead = issue.auditType == .textClipped
                && issue.element?.identifier == "advantage"
                && issue.element?.label.hasSuffix(" in material") == true
            let ignored = isSpokenHalfPoint || isSpokenLead || isGameAction && (
                (issue.auditType == .dynamicType && issue.compactDescription.contains("partially"))
                || (issue.auditType == .contrast && issue.element?.isEnabled == false)
                || (issue.auditType == .contrast && issue.compactDescription.contains("nearly passed")
                    && (issue.element?.frame.maxY ?? 0) > window.maxY))
            if !ignored {
                print("Accessibility audit issue: \(issue.compactDescription) on \(issue.element?.debugDescription ?? "no element")")
            }
            return ignored
        }
    }

    static let gameActions: Set<String> = [
        "New match", "Next game", "Resign", "Agree draw", "Offer double", "Take", "Decline",
    ]
    /// Texts that can show half a point.
    static let textsWithHalves: Set<String> = ["award", "matchScore", "matchResult"]
}
