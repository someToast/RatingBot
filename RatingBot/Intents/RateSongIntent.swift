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

struct RatingBotShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RateSongIntent(rating: 5),
            phrases: [
                "Give this song five with \(.applicationName)",
                "Give this song 5 with \(.applicationName)",
                "Give this song five stars with \(.applicationName)",
                "Give this song 5 stars with \(.applicationName)",
                "Give this song five using \(.applicationName)",
                "Give this song 5 using \(.applicationName)",
                "Give this song five stars using \(.applicationName)",
                "Give this song 5 stars using \(.applicationName)",
                "Give this track five with \(.applicationName)",
                "Give this track 5 with \(.applicationName)",
                "Give this track five stars with \(.applicationName)",
                "Give this track 5 stars with \(.applicationName)",
                "Give this track five using \(.applicationName)",
                "Give this track 5 using \(.applicationName)",
                "Give this track five stars using \(.applicationName)",
                "Give this track 5 stars using \(.applicationName)"
            ],
            shortTitle: "Give This Song Five",
            systemImageName: "star.fill"
        )
        AppShortcut(
            intent: RateSongIntent(rating: 4),
            phrases: [
                "Give this song four with \(.applicationName)",
                "Give this song 4 with \(.applicationName)",
                "Give this song four stars with \(.applicationName)",
                "Give this song 4 stars with \(.applicationName)",
                "Give this song four using \(.applicationName)",
                "Give this song 4 using \(.applicationName)",
                "Give this song four stars using \(.applicationName)",
                "Give this song 4 stars using \(.applicationName)",
                "Give this track four with \(.applicationName)",
                "Give this track 4 with \(.applicationName)",
                "Give this track four stars with \(.applicationName)",
                "Give this track 4 stars with \(.applicationName)",
                "Give this track four using \(.applicationName)",
                "Give this track 4 using \(.applicationName)",
                "Give this track four stars using \(.applicationName)",
                "Give this track 4 stars using \(.applicationName)"
            ],
            shortTitle: "Give This Song Four",
            systemImageName: "star.fill"
        )
        AppShortcut(
            intent: RateSongIntent(rating: 3),
            phrases: [
                "Give this song three with \(.applicationName)",
                "Give this song 3 with \(.applicationName)",
                "Give this song three stars with \(.applicationName)",
                "Give this song 3 stars with \(.applicationName)",
                "Give this song three using \(.applicationName)",
                "Give this song 3 using \(.applicationName)",
                "Give this song three stars using \(.applicationName)",
                "Give this song 3 stars using \(.applicationName)",
                "Give this track three with \(.applicationName)",
                "Give this track 3 with \(.applicationName)",
                "Give this track three stars with \(.applicationName)",
                "Give this track 3 stars with \(.applicationName)",
                "Give this track three using \(.applicationName)",
                "Give this track 3 using \(.applicationName)",
                "Give this track three stars using \(.applicationName)",
                "Give this track 3 stars using \(.applicationName)"
            ],
            shortTitle: "Give This Song Three",
            systemImageName: "star.leadinghalf.filled"
        )
        AppShortcut(
            intent: RateSongIntent(rating: 2),
            phrases: [
                "Give this song two with \(.applicationName)",
                "Give this song 2 with \(.applicationName)",
                "Give this song two stars with \(.applicationName)",
                "Give this song 2 stars with \(.applicationName)",
                "Give this song two using \(.applicationName)",
                "Give this song 2 using \(.applicationName)",
                "Give this song two stars using \(.applicationName)",
                "Give this song 2 stars using \(.applicationName)",
                "Give this track two with \(.applicationName)",
                "Give this track 2 with \(.applicationName)",
                "Give this track two stars with \(.applicationName)",
                "Give this track 2 stars with \(.applicationName)",
                "Give this track two using \(.applicationName)",
                "Give this track 2 using \(.applicationName)",
                "Give this track two stars using \(.applicationName)",
                "Give this track 2 stars using \(.applicationName)"
            ],
            shortTitle: "Give This Song Two",
            systemImageName: "star"
        )
        AppShortcut(
            intent: RateSongIntent(rating: 1),
            phrases: [
                "Give this song one with \(.applicationName)",
                "Give this song 1 with \(.applicationName)",
                "Give this song one star with \(.applicationName)",
                "Give this song 1 star with \(.applicationName)",
                "Give this song one using \(.applicationName)",
                "Give this song 1 using \(.applicationName)",
                "Give this song one star using \(.applicationName)",
                "Give this song 1 star using \(.applicationName)",
                "Give this track one with \(.applicationName)",
                "Give this track 1 with \(.applicationName)",
                "Give this track one star with \(.applicationName)",
                "Give this track 1 star with \(.applicationName)",
                "Give this track one using \(.applicationName)",
                "Give this track 1 using \(.applicationName)",
                "Give this track one star using \(.applicationName)",
                "Give this track 1 star using \(.applicationName)"
            ],
            shortTitle: "Give This Song One",
            systemImageName: "star"
        )
    }
}
