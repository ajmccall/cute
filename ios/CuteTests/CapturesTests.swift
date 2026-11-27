import Foundation
import Testing
@testable import Cute

/// Captures and material through the local-game boundary, on the real file store in its own temporary folder:
/// local-game C16 and C17, and C5 for a capture that can't be saved.
@Suite struct CapturesTests {
    // MARK: C16

    @Test func anOrdinaryCaptureJoinsTheMoversCapturesSavedWithTheMoveAndReopened() throws {
        let storage = try TemporaryStorage()
        let game = LocalGame(store: storage.store)
        game.open()
        #expect(game.captures == .empty)

        game.tap("e2"); game.tap("e4")
        game.tap("d7"); game.tap("d5")
        game.tap("e4"); game.tap("d5")

        #expect(game.captures == Captures(white: [.pawn], black: []))
        #expect(try storage.store.load()?.captures == Captures(white: [.pawn], black: []))

        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.captures == Captures(white: [.pawn], black: []))
    }

    @Test func anEnPassantCaptureJoinsTheMoversCapturesAsAPawn() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: "4k3/8/8/8/3p4/8/4P3/4K3 w - -", in: storage)

        game.tap("e2"); game.tap("e4")
        game.tap("d4"); game.tap("e3")

        #expect(game.position.fen == "4k3/8/8/8/8/4p3/8/4K3 w - -")
        #expect(game.captures == Captures(white: [], black: [.pawn]))
        #expect(try storage.store.load()?.captures == Captures(white: [], black: [.pawn]))
    }

    /// Black to move after 1. e4 d5 2. exd5, and White has resigned: White captured a pawn and leads by 1.
    nonisolated static let afterExd5 = "rnbqkbnr/ppp1pppp/8/3P4/8/8/PPPP1PPP/RNBQKBNR b KQkq -"

    @Test(arguments: ["nextGame", "newMatch"])
    func aFreshGameStartsWithNothingCapturedSavedWithTheFreshGame(action: String) throws {
        let storage = try TemporaryStorage()
        try storage.store.save(SavedGame(position: try #require(Position(fen: Self.afterExd5)),
                                         result: .win(.white, .resignation), matchScore: MatchScore(white: 1, black: 0),
                                         captures: Captures(white: [.pawn], black: [])))
        let game = LocalGame(store: storage.store)
        game.open()
        #expect(game.captures == Captures(white: [.pawn], black: []))
        #expect(game.materialLead == MaterialLead(side: .white, amount: 1))

        if action == "nextGame" { game.nextGame() } else { game.newMatch() }

        #expect(game.captures == .empty)
        #expect(game.materialLead == nil)
        #expect(try storage.store.load()?.captures == .empty)
    }

    @Test func aGameSavedBeforeCapturesOpensWithNothingCapturedAndOtherwiseUnchanged() throws {
        let storage = try TemporaryStorage()
        try Data(#"{"version": 3, "position": "\#(Self.afterExd5)", "result": null, "stake": 2, "nextDoubler": "white", "doublePending": false, "whiteTotal": 4.5, "blackTotal": 3}"#.utf8)
            .write(to: storage.fileURL)

        let game = LocalGame(store: storage.store)
        game.open()

        #expect(game.hasNoFailure)
        #expect(game.captures == .empty)
        #expect(game.position.fen == Self.afterExd5)
        #expect(game.stake == 2)
        #expect(game.nextDoubler == .white)
        #expect(game.matchScore == MatchScore(white: 4.5, black: 3))
        // Material is counted from the board, so the lead shows without the capture that made it.
        #expect(game.materialLead == MaterialLead(side: .white, amount: 1))

        // Its next capture is the first.
        game.tap("d8"); game.tap("d5")
        #expect(game.captures == Captures(white: [], black: [.pawn]))
        #expect(try storage.store.load()?.captures == Captures(white: [], black: [.pawn]))
    }

    /// Games saved before the cube (version 1) and before matches (version 2) were also saved before captures.
    @Test(arguments: [
        #"{"version": 1, "position": "\#(afterExd5)", "result": null}"#,
        #"{"version": 2, "position": "\#(afterExd5)", "result": null, "stake": 2, "nextDoubler": "white", "doublePending": false}"#,
    ])
    func gamesSavedBeforeTheCubeOrMatchesAlsoOpenWithNothingCaptured(contents: String) throws {
        let storage = try TemporaryStorage()
        try Data(contents.utf8).write(to: storage.fileURL)

        let game = LocalGame(store: storage.store)
        game.open()

        #expect(game.hasNoFailure)
        #expect(game.captures == .empty)
        #expect(game.position.fen == Self.afterExd5)
        #expect(game.materialLead == MaterialLead(side: .white, amount: 1))
    }

    // MARK: C5, C16

    @Test func aCaptureThatCannotBeSavedLeavesTheCapturesAsLastSavedUntilRetrySavesIt() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: "rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -", in: storage)

        try storage.makeReadOnly()
        game.tap("e4"); game.tap("d5")

        #expect(game.hasUnsavedChange)
        #expect(game.captures == .empty)
        #expect(game.materialLead == nil)
        #expect(try storage.store.load()?.captures == .empty)

        try storage.makeWritable()
        game.retrySave()

        #expect(game.hasNoFailure)
        #expect(game.captures == Captures(white: [.pawn], black: []))
        #expect(game.materialLead == MaterialLead(side: .white, amount: 1))
        #expect(try storage.store.load()?.captures == Captures(white: [.pawn], black: []))
    }

    // MARK: Saved format

    @Test(arguments: [
        (#"{"white": [], "black": []}"#, Captures.empty),
        (#"{"white": ["pawn", "queen", "knight"], "black": ["bishop", "rook"]}"#,
         Captures(white: [.pawn, .queen, .knight], black: [.bishop, .rook])),
    ])
    func savedCapturesOpenInTheOrderTakenAndAreSavedAgainWithTheNextMove(json: String, captures: Captures) throws {
        let storage = try TemporaryStorage()
        // Black to move, with few pieces left on either side.
        try Data(#"{"version": 4, "position": "r3k3/p7/8/8/8/8/P7/4K3 b - -", "result": null, "stake": 1, "nextDoubler": null, "doublePending": false, "whiteTotal": 0, "blackTotal": 0, "captures": \#(json)}"#.utf8)
            .write(to: storage.fileURL)

        let game = LocalGame(store: storage.store)
        game.open()
        #expect(game.hasNoFailure)
        #expect(game.captures == captures)

        game.tap("a7"); game.tap("a6")
        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.captures == captures)
    }

    /// Version 4 files whose captures are missing, malformed or ones that no game can reach.
    @Test(arguments: [
        #""#,                                                                    // no captures
        #", "captures": null"#,                                                  // null captures
        #", "captures": {"white": []}"#,                                         // no Black captures
        #", "captures": {"white": ["pawn"], "black": "none"}"#,                  // not a list
        #", "captures": {"white": ["dragon"], "black": []}"#,                    // no such piece
        #", "captures": {"white": ["king"], "black": []}"#,                      // a captured king
        #", "captures": {"white": ["pawn", "pawn"], "black": []}"#,              // more pawns than Black had
        #", "captures": {"white": [], "black": ["queen", "queen", "queen", "queen", "queen", "queen", "queen", "queen", "queen", "queen", "queen", "queen", "queen", "queen", "queen", "queen"]}"#,  // more pieces than White had
    ])
    func impossibleCapturesAreReportedAsUnreadable(fields: String) throws {
        let storage = try TemporaryStorage()
        // Every piece on the board, but one White pawn taken: Black has all eight pawns.
        let contents = Data(#"{"version": 4, "position": "rnbqkbnr/pppppppp/8/8/8/8/PPPP1PPP/RNBQKBNR w KQkq -", "result": null, "stake": 1, "nextDoubler": null, "doublePending": false, "whiteTotal": 0, "blackTotal": 0\#(fields)}"#.utf8)
        try contents.write(to: storage.fileURL)

        let game = LocalGame(store: storage.store)
        game.open()

        #expect(game.couldNotReadSavedGame)
        #expect(try Data(contentsOf: storage.fileURL) == contents)
    }

    // MARK: C16, C17

    /// White promotes on e8 without capturing, giving check, and Black's rook takes the new queen.
    @Test func aPromotionChangesMaterialOnceCommittedAndACapturedPromotedPieceIsItsPromotedKind() throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: "3r3k/4P3/8/8/8/8/8/K7 w - -", in: storage)
        #expect(game.materialLead == MaterialLead(side: .black, amount: 4))

        game.tap("e7"); game.tap("e8")
        // Still being chosen, the promotion changes nothing.
        try #require(game.isChoosingPromotion)
        #expect(game.materialLead == MaterialLead(side: .black, amount: 4))

        game.choosePromotion(.queen)
        #expect(game.captures == .empty)
        #expect(game.materialLead == MaterialLead(side: .white, amount: 4))

        game.tap("d8"); game.tap("e8")
        #expect(game.captures == Captures(white: [], black: [.queen]))
        #expect(game.materialLead == MaterialLead(side: .black, amount: 5))

        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.captures == Captures(white: [], black: [.queen]))
        #expect(reopened.materialLead == MaterialLead(side: .black, amount: 5))
    }

    // MARK: C17

    @Test(arguments: [
        ("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -", nil),
        // A knight for a bishop is even.
        ("r1bqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RN1QKBNR w KQkq -", nil),
        // Kings aren't counted.
        ("4k3/8/8/8/8/8/8/4K3 w - -", nil),
        ("4k3/8/8/8/8/8/8/3QK3 b - -", MaterialLead(side: .white, amount: 9)),
        // Rook and two pawns (7) against a knight and a bishop (6).
        ("2b1k3/8/5n2/8/8/8/PP6/R3K3 w - -", MaterialLead(side: .white, amount: 1)),
        ("rnbqk3/pppppppp/8/8/8/8/8/4K3 w - -", MaterialLead(side: .black, amount: 28)),
    ] as [(String, MaterialLead?)])
    func theLeadIsTheDifferenceInMaterialOnTheBoardAndNoneWhenEqual(fen: String, lead: MaterialLead?) throws {
        let storage = try TemporaryStorage()
        let game = try openGame(at: fen, in: storage)

        #expect(game.materialLead == lead)
    }

    // MARK: Interface text

    /// Shown as +N and spoken by colour and amount, never in points. XCUITest reads only the spoken text, which
    /// CapturesUITests checks on the board; the screenshots show +N.
    @Test(arguments: [
        (MaterialLead(side: .white, amount: 1), "+1", "White ahead by 1 in material"),
        (MaterialLead(side: .black, amount: 28), "+28", "Black ahead by 28 in material"),
    ])
    func theLeadIsShownAsPlusNAndSpokenByColourAndAmount(lead: MaterialLead, shown: String, spoken: String) {
        #expect(BoardText.advantage(lead, spoken: false) == shown)
        #expect(BoardText.advantage(lead, spoken: true) == spoken)
    }
}
