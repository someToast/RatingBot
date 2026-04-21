import SwiftUI

@main
struct RatingBotApp: App {
    @StateObject private var musicService = MusicRatingService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(musicService)
        }
    }
}
