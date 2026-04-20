import Combine
import Foundation
import MediaPlayer

enum MusicRatingError: LocalizedError {
    case accessDenied
    case noSongPlaying
    case invalidRating
    case playlistUnavailable(Int)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Allow access to Apple Music in Settings to rate songs."
        case .noSongPlaying:
            return "No Music song is currently playing."
        case .invalidRating:
            return "Choose a rating from 1 to 5 stars."
        case .playlistUnavailable(let rating):
            return "Could not create or find the Rate \(rating) playlist."
        }
    }
}

@MainActor
final class MusicRatingService: ObservableObject {
    static let shared = MusicRatingService()

    @Published private(set) var currentTrack: NowPlayingTrack = .empty
    @Published private(set) var authorizationStatus = MPMediaLibrary.authorizationStatus()
    @Published var statusMessage = "Ready"

    private let player = MPMusicPlayerController.systemMusicPlayer
    private let playlistIDs: [Int: UUID] = [
        1: UUID(uuidString: "D7367315-AD09-4938-B26C-3A28B8D38001")!,
        2: UUID(uuidString: "D7367315-AD09-4938-B26C-3A28B8D38002")!,
        3: UUID(uuidString: "D7367315-AD09-4938-B26C-3A28B8D38003")!,
        4: UUID(uuidString: "D7367315-AD09-4938-B26C-3A28B8D38004")!,
        5: UUID(uuidString: "D7367315-AD09-4938-B26C-3A28B8D38005")!
    ]

    private init() {
        refreshNowPlaying()
        player.beginGeneratingPlaybackNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingDidChange),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingDidChange),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: player
        )
    }

    deinit {
        player.endGeneratingPlaybackNotifications()
        NotificationCenter.default.removeObserver(self)
    }

    func requestAccessIfNeeded() async {
        switch MPMediaLibrary.authorizationStatus() {
        case .notDetermined:
            authorizationStatus = await MPMediaLibrary.requestAuthorization()
        default:
            authorizationStatus = MPMediaLibrary.authorizationStatus()
        }
        refreshNowPlaying()
    }

    func refreshNowPlaying() {
        currentTrack = player.nowPlayingItem?.songRaterTrack ?? .empty
    }

    func rateCurrentSong(_ rating: Int, shouldSpeak: Bool = true) async throws -> NowPlayingTrack {
        guard (1...5).contains(rating) else {
            throw MusicRatingError.invalidRating
        }

        try await ensureAuthorized()

        guard let item = player.nowPlayingItem else {
            refreshNowPlaying()
            throw MusicRatingError.noSongPlaying
        }

        let playlist = try await playlist(for: rating)
        try await playlist.add([item])

        let track = item.songRaterTrack
        currentTrack = track
        statusMessage = "Added to Rate \(rating)"

        if shouldSpeak {
            RatingSpeaker.shared.speak(rating: rating, track: track)
        }

        return track
    }

    @objc private func nowPlayingDidChange() {
        refreshNowPlaying()
    }

    private func ensureAuthorized() async throws {
        await requestAccessIfNeeded()
        guard authorizationStatus == .authorized else {
            throw MusicRatingError.accessDenied
        }
    }

    private func playlist(for rating: Int) async throws -> MPMediaPlaylist {
        guard let uuid = playlistIDs[rating] else {
            throw MusicRatingError.invalidRating
        }

        let metadata = MPMediaPlaylistCreationMetadata(name: "Rate \(rating)")
        metadata.authorDisplayName = "Song Rater"
        metadata.descriptionText = "Songs rated \(rating) star\(rating == 1 ? "" : "s") in Song Rater."

        return try await withCheckedThrowingContinuation { continuation in
            MPMediaLibrary.default().getPlaylist(with: uuid, creationMetadata: metadata) { playlist, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let playlist {
                    continuation.resume(returning: playlist)
                } else {
                    continuation.resume(throwing: MusicRatingError.playlistUnavailable(rating))
                }
            }
        }
    }
}
