import Testing
@testable import Cute

@Suite struct AutomaticDoublesTests {
    @Test func bothContinueSavesEachAnswerAndDoublesStake() throws {
        let storage = try TemporaryStorage()
        let position = try #require(Position(fen: "4k2r/8/8/8/8/8/4P3/R3K3 w - -"))
        try storage.store.save(SavedGame(position: position, result: nil))
        let game = LocalGame(store: storage.store, automaticDoublesEnabled: { true })
        game.open(); game.tap("e2"); game.tap("e4")
        game.answerAutomatic(continuePlaying: true)
        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.automaticResponder == .black)
        reopened.answerAutomatic(continuePlaying: true)
        #expect(reopened.stake == 2)
        #expect(!reopened.isAwaitingAutomaticResponse)
        #expect(reopened.position.sideToMove == .black)
        let restored = LocalGame(store: storage.store)
        restored.open()
        #expect(!restored.couldNotReadSavedGame)
        #expect(restored.stake == 2)
        #expect(restored.nextDoubler == nil)
    }

    @Test(arguments: [(true, false, PieceColor.white), (false, true, PieceColor.black)])
    func onlyContinuingPlayerWins(first: Bool, second: Bool, winner: PieceColor) throws {
        let storage = try TemporaryStorage()
        let position = try #require(Position(fen: "4k2r/8/8/8/8/8/4P3/R3K3 w - -"))
        try storage.store.save(SavedGame(position: position, result: nil))
        let game = LocalGame(store: storage.store, automaticDoublesEnabled: { true })
        game.open(); game.tap("e2"); game.tap("e4")
        game.answerAutomatic(continuePlaying: first)
        game.answerAutomatic(continuePlaying: second)
        #expect(game.award == .win(winner, 1))
    }

    @Test func bothStopSplitsStakeAndSurvivesReopening() throws {
        let storage = try TemporaryStorage()
        let position = try #require(Position(fen: "4k2r/8/8/8/8/8/4P3/R3K3 w - -"))
        try storage.store.save(SavedGame(position: position, result: nil))
        let game = LocalGame(store: storage.store, automaticDoublesEnabled: { true })
        game.open(); game.tap("e2"); game.tap("e4")
        game.answerAutomatic(continuePlaying: false)
        game.answerAutomatic(continuePlaying: false)
        #expect(game.award == .split(1))
        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.award == .split(1))
    }

    @Test func openingMilestoneTriggersWithSixStartingSquaresCleared() throws {
        let storage = try TemporaryStorage()
        let position = try #require(Position(fen: "r2qk2r/pppppppp/2n2n2/8/8/2N2N2/PPPPPPPP/R1BQKB1R w KQkq -"))
        try storage.store.save(SavedGame(position: position, result: nil))
        let game = LocalGame(store: storage.store, automaticDoublesEnabled: { true })
        game.open(); game.tap("g2"); game.tap("g3")
        #expect(game.isAwaitingAutomaticResponse)
        game.answerAutomatic(continuePlaying: true); game.answerAutomatic(continuePlaying: true)
        game.tap("g7"); game.tap("g6")
        #expect(!game.isAwaitingAutomaticResponse)
        #expect(try storage.store.load()?.openingMilestoneUsed == true)
        #expect(try storage.store.load()?.endgameMilestoneUsed == false)
    }

    @Test func switchIsReadAtEachMoveWithoutReplayingPositions() throws {
        let storage = try TemporaryStorage()
        let position = try #require(Position(fen: "4k2r/8/8/8/8/8/4P3/R3K3 w - -"))
        try storage.store.save(SavedGame(position: position, result: nil))
        var enabled = false
        let game = LocalGame(store: storage.store, automaticDoublesEnabled: { enabled })
        game.open(); game.tap("e2"); game.tap("e4")
        #expect(!game.isAwaitingAutomaticResponse)
        enabled = true
        #expect(!game.isAwaitingAutomaticResponse)
        game.tap("h8"); game.tap("h7")
        #expect(game.isAwaitingAutomaticResponse)
        #expect(game.automaticResponder == .black)
    }

    @Test(arguments: [32, 64])
    func stakeCapConsumesMilestones(stake: Int) throws {
        let storage = try TemporaryStorage()
        let position = try #require(Position(fen: "4k2r/8/8/8/8/8/4P3/R3K3 w - -"))
        try storage.store.save(SavedGame(position: position, result: nil, stake: stake, nextDoubler: .white))
        let game = LocalGame(store: storage.store, automaticDoublesEnabled: { true })
        game.open(); game.tap("e2"); game.tap("e4")
        #expect(game.isAwaitingAutomaticResponse == (stake == 32))
        if stake == 32 {
            game.answerAutomatic(continuePlaying: true)
            game.answerAutomatic(continuePlaying: true)
            #expect(game.stake == 64)
            #expect(game.nextDoubler == .white)
        }
        game.tap("h8"); game.tap("h7")
        #expect(!game.isAwaitingAutomaticResponse)
        #expect(try storage.store.load()?.openingMilestoneUsed == true)
        #expect(try storage.store.load()?.endgameMilestoneUsed == true)
    }

    @Test(arguments: [0, 1, 2])
    func failedSaveRestoresLastCommittedStep(step: Int) throws {
        let storage = try TemporaryStorage()
        let position = try #require(Position(fen: "4k2r/8/8/8/8/8/4P3/R3K3 w - -"))
        try storage.store.save(SavedGame(position: position, result: nil))
        let game = LocalGame(store: storage.store, automaticDoublesEnabled: { true })
        game.open()
        if step > 0 { game.tap("e2"); game.tap("e4") }
        if step > 1 { game.answerAutomatic(continuePlaying: true) }
        let before = try #require(try storage.store.load())
        try storage.makeReadOnly()
        if step == 0 { game.tap("e2"); game.tap("e4") }
        else { game.answerAutomatic(continuePlaying: true) }
        #expect(game.hasUnsavedChange)
        #expect(try storage.store.load() == before)
        try storage.makeWritable()
        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.position == before.position)
        #expect(reopened.isAwaitingAutomaticResponse == before.automaticPending)
        if step > 0 { #expect(reopened.automaticResponder == (step == 1 ? .white : .black)) }
        game.retrySave()
        #expect(!game.hasUnsavedChange)
    }

    @Test func anImpossibleSavedAutomaticDecisionIsNotOpened() throws {
        let storage = try TemporaryStorage()
        var saved = SavedGame.opening
        saved.automaticPending = true
        saved.doublePending = true
        try storage.store.save(saved)
        let game = LocalGame(store: storage.store)
        game.open()
        #expect(game.couldNotReadSavedGame)
    }

    @Test func bothStopAtTwoPointsDrawsMatchAtFifteenAll() throws {
        let storage = try TemporaryStorage()
        let position = try #require(Position(fen: "4k2r/8/8/8/8/8/4P3/R3K3 w - -"))
        try storage.store.save(SavedGame(position: position, result: nil, stake: 2, nextDoubler: .white,
                                         matchScore: MatchScore(white: 14, black: 14)))
        let game = LocalGame(store: storage.store, automaticDoublesEnabled: { true })
        game.open(); game.tap("e2"); game.tap("e4")
        game.answerAutomatic(continuePlaying: false); game.answerAutomatic(continuePlaying: false)
        #expect(game.matchScore == MatchScore(white: 15, black: 15))
        #expect(game.isMatchOver)
        let reopened = LocalGame(store: storage.store)
        reopened.open()
        #expect(reopened.matchScore == MatchScore(white: 15, black: 15))
        #expect(reopened.isMatchOver)
    }

    @Test func checkmateTakesPrecedenceOverAnAutomaticDecision() throws {
        let storage = try TemporaryStorage()
        let position = try #require(Position(fen: "7k/8/5KQ1/8/8/8/8/8 w - -"))
        try storage.store.save(SavedGame(position: position, result: nil))
        let game = LocalGame(store: storage.store, automaticDoublesEnabled: { true })
        game.open(); game.tap("g6"); game.tap("g7")
        #expect(game.result == .win(.white, .checkmate))
        #expect(!game.isAwaitingAutomaticResponse)
    }

    @Test func qualifyingMovePausesForMoverAndSurvivesReopening() throws {
        let storage = try TemporaryStorage()
        let position = try #require(Position(fen: "4k2r/8/8/8/8/8/4P3/R3K3 w - -"))
        try storage.store.save(SavedGame(position: position, result: nil))
        let game = LocalGame(store: storage.store, automaticDoublesEnabled: { true })
        game.open()
        game.tap("e2"); game.tap("e4")
        #expect(game.isAwaitingAutomaticResponse)
        #expect(game.automaticResponder == .white)
        let reopened = LocalGame(store: storage.store, automaticDoublesEnabled: { true })
        reopened.open()
        #expect(reopened.isAwaitingAutomaticResponse)
        #expect(reopened.automaticResponder == .white)
    }
}
