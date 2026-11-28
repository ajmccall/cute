import Foundation
import SwiftUI

@main
struct CuteApp: App {
    @State private var game: LocalGame
    private let defaults: UserDefaults

    init() {
        #if DEBUG
        let defaults = ProcessInfo.processInfo.environment["CUTE_UITEST_GAME_FILE"]
            .flatMap { UserDefaults(suiteName: $0) } ?? .standard
        #else
        let defaults = UserDefaults.standard
        #endif
        self.defaults = defaults
        let game = LocalGame(store: Self.makeStore(), automaticDoublesEnabled: { defaults.bool(forKey: "automaticDoubles") })
        game.open()
        _game = State(initialValue: game)
    }

    var body: some Scene {
        WindowGroup {
            BoardScreen(game: game)
                .defaultAppStorage(defaults)
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
