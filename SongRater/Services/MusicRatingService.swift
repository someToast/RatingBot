import Combine
import Foundation
import MediaPlayer

enum MusicRatingError: LocalizedError {
    case accessDenied
    case noSongPlaying
    case invalidRating
    case playlistUnavailable(Int)
    case addFailed(String)

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
        case .addFailed(let message):
            return message
        }
    }
}

@MainActor
final class MusicRatingService: ObservableObject {
    static let shared = MusicRatingService()

    @Published private(set) var currentTrack: NowPlayingTrack = .empty
    @Published private(set) var authorizationStatus = MPMediaLibrary.authorizationStatus()
    @Published private(set) var assignedRating: Int?
    @Published var statusMessage = "Ready"

    private let player = MPMusicPlayerController.systemMusicPlayer
    private let playlistIDs: [Int: UUID] = [
        1: UUID(uuidString: "D7367315-AD09-4938-B26C-3A28B8D38001")!,
        2: UUID(uuidString: "D7367315-AD09-4938-B26C-3A28B8D38002")!,
        3: UUID(uuidString: "D7367315-AD09-4938-B26C-3A28B8D38003")!,
        4: UUID(uuidString: "D7367315-AD09-4938-B26C-3A28B8D38004")!,
        5: UUID(uuidString: "D7367315-AD09-4938-B26C-3A28B8D38005")!
    ]
    private var hasPreparedRatingPlaylists = false
    private var currentTrackIdentifier: String?

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
        if authorizationStatus == .authorized && !hasPreparedRatingPlaylists {
            await prepareRatingPlaylists()
        }
    }

    func refreshNowPlaying() {
        let latestIdentifier = player.nowPlayingItem.flatMap(trackIdentifier(for:))
        if latestIdentifier != currentTrackIdentifier {
            assignedRating = nil
        }
        currentTrackIdentifier = latestIdentifier
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
        try await add(item, to: playlist)

        let track = item.songRaterTrack
        assignedRating = rating
        currentTrackIdentifier = trackIdentifier(for: item)
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

    private func prepareRatingPlaylists() async {
        do {
            for rating in 1...5 {
                _ = try await playlist(for: rating)
            }
            hasPreparedRatingPlaylists = true
            if statusMessage == "Ready" {
                statusMessage = "Rating playlists ready"
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func playlist(for rating: Int) async throws -> MPMediaPlaylist {
        guard let uuid = playlistIDs[rating] else {
            throw MusicRatingError.invalidRating
        }

        let metadata = MPMediaPlaylistCreationMetadata(name: playlistName(for: rating))
        metadata.authorDisplayName = "Song Rater"
        metadata.descriptionText = "Songs rated \(rating) star\(rating == 1 ? "" : "s") in Song Rater."

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MPMediaPlaylist, Error>) in
            MPMediaLibrary.default().getPlaylist(with: uuid, creationMetadata: metadata) { playlist, error in
                if let error {
                    continuation.resume(throwing: MusicRatingError.addFailed(error.localizedDescription))
                } else if let playlist {
                    continuation.resume(returning: playlist)
                } else {
                    continuation.resume(throwing: MusicRatingError.playlistUnavailable(rating))
                }
            }
        }
    }

    private func add(_ item: MPMediaItem, to playlist: MPMediaPlaylist) async throws {
        if let storeID = item.playbackStoreID.nilIfBlank, storeID != "0" {
            try await addStoreItem(storeID, to: playlist)
        } else {
            try await addMediaItem(item, to: playlist)
        }
    }

    private func addStoreItem(_ storeID: String, to playlist: MPMediaPlaylist) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            playlist.addItem(withProductID: storeID) { error in
                if let error {
                    continuation.resume(throwing: MusicRatingError.addFailed(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func addMediaItem(_ item: MPMediaItem, to playlist: MPMediaPlaylist) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            playlist.add([item]) { error in
                if let error {
                    continuation.resume(throwing: MusicRatingError.addFailed(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func playlistName(for rating: Int) -> String {
        "Rate \(rating)"
    }

    private func trackIdentifier(for item: MPMediaItem) -> String {
        if let storeID = item.playbackStoreID.nilIfBlank {
            return "store:\(storeID)"
        }
        if item.persistentID != 0 {
            return "persistent:\(item.persistentID)"
        }
        return "fallback:\(item.songRaterTrack.title)|\(item.songRaterTrack.artist)"
    }
}
