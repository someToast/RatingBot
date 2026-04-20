import SwiftUI

@main
struct SongRaterApp: App {
    @StateObject private var musicService = MusicRatingService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(musicService)
        }
    }
}
