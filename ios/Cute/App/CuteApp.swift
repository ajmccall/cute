import Foundation
import SwiftUI

@main
struct CuteApp: App {
    @State private var game: LocalGame

    init() {
        let game = LocalGame(store: Self.makeStore())
        game.open()
        _game = State(initialValue: game)
    }

    var body: some Scene {
        WindowGroup {
            BoardScreen(game: game)
        }
    }

    /// The current game lives in one file in Application Support.
    private static func makeStore() -> GameStore {
        let folder = URL.applicationSupportDirectory
        #if DEBUG
        if let harness = UITestHarness(environment: ProcessInfo.processInfo.environment, folder: folder) {
            return harness.makeStore()
        }
        #endif
        return FileGameStore(fileURL: folder.appending(path: "CurrentGame.json"))
    }
}
