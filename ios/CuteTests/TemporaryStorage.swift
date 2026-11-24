import Foundation
@testable import Cute

/// A current-game file in its own new temporary folder, away from the app's real data.
final class TemporaryStorage {
    let folder: URL
    let fileURL: URL
    let store: FileGameStore

    init() throws {
        folder = FileManager.default.temporaryDirectory
            .appending(path: "CuteTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appending(path: "CurrentGame.json")
        store = FileGameStore(fileURL: fileURL)
    }

    deinit {
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder.path)
        try? FileManager.default.removeItem(at: folder)
    }
}
