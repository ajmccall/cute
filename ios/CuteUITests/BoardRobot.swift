import XCTest

/// Drives the running board the way a player does, in a scenario with its own current-game file.
@MainActor
struct BoardRobot {
    let app = XCUIApplication()
    /// The scenario's own current-game file, kept across relaunches within the scenario.
    let gameFile = "uitest-\(UUID().uuidString).json"

    /// Launches the app on this scenario's game, optionally seeding a position or failing one store operation.
    func launch(seed fen: String? = nil, fault: String? = nil) {
        app.terminate()
        app.launchEnvironment = ["CUTE_UITEST_GAME_FILE": gameFile]
        if let fen { app.launchEnvironment["CUTE_UITEST_SEED_FEN"] = fen }
        if let fault { app.launchEnvironment["CUTE_UITEST_FAULT"] = fault }
        app.launch()
    }

    func square(_ coordinate: String) -> XCUIElement {
        app.buttons["square-\(coordinate)"]
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
        try app.performAccessibilityAudit { issue in
            // Stock bordered buttons are reported as "partially" supporting Dynamic Type, though their labels
            // grow and wrap up to the largest accessibility size (checked by screenshot at
            // accessibility-extra-extra-extra-large). Every other issue fails the test.
            let ignored = issue.auditType == .dynamicType
                && issue.compactDescription.contains("partially")
                && issue.element?.elementType == .button
                && Self.gameActions.contains(issue.element?.label ?? "")
            if !ignored {
                print("Accessibility audit issue: \(issue.compactDescription) on \(issue.element?.debugDescription ?? "no element")")
            }
            return ignored
        }
    }

    static let gameActions: Set<String> = ["New game", "Resign", "Agree draw"]
}
