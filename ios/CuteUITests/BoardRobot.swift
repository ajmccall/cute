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

    func tap(_ coordinates: String...) {
        for coordinate in coordinates {
            square(coordinate).tap()
        }
    }

    // MARK: Expectations
    //
    // Each waits, up to `settleTimeout`, for what the player sees or hears to become the expected text, and returns
    // as soon as it has. An element that already exists keeps its old label until the app has redrawn, and on a
    // stalled machine a read straight after a tap can come before that; so nothing here reads once and compares.

    /// How long an expectation waits for the app to catch up before it fails.
    static let settleTimeout: TimeInterval = 10

    func expectStatus(_ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        expectLabel(of: app.staticTexts["status"], expected, "status", file: file, line: line)
    }

    /// The label of the text with this identifier, such as "stake" or "award".
    func expectText(_ identifier: String, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        expectLabel(of: app.staticTexts[identifier], expected, identifier, file: file, line: line)
    }

    /// The label of a square, "{coordinate}, {occupant}".
    func expectSquare(_ coordinate: String, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        expectLabel(of: square(coordinate), expected, "square-\(coordinate)", file: file, line: line)
    }

    /// The value of a square: "Selected", "Legal destination" or nothing.
    func expectValue(of coordinate: String, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        let square = square(coordinate)
        expectEventually(expected, "value of square-\(coordinate)", file: file, line: line) {
            square.exists ? (square.value as? String) ?? "" : Self.missing
        }
    }

    /// The squares marked as legal destinations, in coordinate order.
    func expectLegalDestinations(_ expected: [String], file: StaticString = #filePath, line: UInt = #line) {
        expectEventually(expected, "legal destinations", file: file, line: line) { legalDestinations }
    }

    func expectLabel(of element: XCUIElement, _ expected: String, _ name: String,
                     file: StaticString = #filePath, line: UInt = #line) {
        expectEventually(expected, name, file: file, line: line) { element.exists ? element.label : Self.missing }
    }

    /// Reads until the value is the expected one or the timeout passes, then fails with both values if it isn't.
    private func expectEventually<Value: Equatable>(_ expected: Value, _ name: String, file: StaticString, line: UInt,
                                                    read: () -> Value) {
        let deadline = Date(timeIntervalSinceNow: Self.settleTimeout)
        var actual = read()
        while actual != expected, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
            actual = read()
        }
        XCTAssertEqual(actual, expected, name, file: file, line: line)
    }

    /// Stands in for the label or value of an element that isn't on screen, which can't be read.
    private static let missing = "(no such element)"

    /// Squares marked as legal destinations at this moment, in coordinate order.
    private var legalDestinations: [String] {
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
            // the audit measures the longer spoken label against the shown text and reports it clipped. Only a
            // label that is, from start to end, one of the spoken forms with a half in it is ignored
            // (`spokenHalves`): any other text on these lines reported clipped still fails the test.
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
                && Self.isSpokenHalf(issue.element?.label ?? "", in: issue.element?.identifier ?? "")
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
    /// Whether the label is, from start to end, a spoken form of the text with this identifier that says a half.
    static func isSpokenHalf(_ label: String, in identifier: String) -> Bool {
        guard label.contains("half"), let pattern = spokenHalves[identifier] else { return false }
        return label.range(of: "^(?:\(pattern))$", options: .regularExpression) != nil
    }

    /// The spoken forms of each text that can say a half, as regular expressions (local-game Interface text).
    static let spokenHalves: [String: String] = [
        "award": #"Each player earns half a point\."#,
        "matchResult": #"(?:White|Black) wins the match, \#(bareTotal) to \#(bareTotal)|Match drawn, \#(bareTotal) to \#(bareTotal)"#,
    ]
    /// A spoken total without its unit: "16", "16 and a half", "a half".
    static let bareTotal = #"(?:\d+|\d+ and a half|a half)"#
}
