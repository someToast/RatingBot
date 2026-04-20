import AppIntents
import Foundation

struct RateSongIntent: AppIntent {
    static var title: LocalizedStringResource = "Rate Current Song"
    static var description = IntentDescription("Adds the current Music song to a Rate n playlist.")
    static var openAppWhenRun = false

    @Parameter(title: "Stars", requestValueDialog: "How many stars?")
    var rating: Int

    init() {}

    init(rating: Int) {
        self.rating = rating
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard (1...5).contains(rating) else {
            throw MusicRatingError.invalidRating
        }

        let track = try await MusicRatingService.shared.rateCurrentSong(rating, shouldSpeak: false)
        return .result(dialog: "\(rating) stars, \(track.title) by \(track.artist)")
    }
}

struct SongRaterShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RateSongIntent(rating: 5),
            phrases: [
                "Give this song five with \(.applicationName)",
                "Give this song 5 with \(.applicationName)"
            ],
            shortTitle: "Give This Song Five",
            systemImageName: "star.fill"
        )
        AppShortcut(
            intent: RateSongIntent(rating: 4),
            phrases: [
                "Give this song four with \(.applicationName)",
                "Give this song 4 with \(.applicationName)"
            ],
            shortTitle: "Give This Song Four",
            systemImageName: "star.fill"
        )
        AppShortcut(
            intent: RateSongIntent(rating: 3),
            phrases: [
                "Give this song three with \(.applicationName)",
                "Give this song 3 with \(.applicationName)"
            ],
            shortTitle: "Give This Song Three",
            systemImageName: "star.leadinghalf.filled"
        )
        AppShortcut(
            intent: RateSongIntent(rating: 2),
            phrases: [
                "Give this song two with \(.applicationName)",
                "Give this song 2 with \(.applicationName)"
            ],
            shortTitle: "Give This Song Two",
            systemImageName: "star"
        )
        AppShortcut(
            intent: RateSongIntent(rating: 1),
            phrases: [
                "Give this song one with \(.applicationName)",
                "Give this song 1 with \(.applicationName)"
            ],
            shortTitle: "Give This Song One",
            systemImageName: "star"
        )
    }
}
