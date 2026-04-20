import Foundation
import MediaPlayer

struct NowPlayingTrack: Equatable, Sendable {
    let title: String
    let artist: String

    static let empty = NowPlayingTrack(title: "No Song Playing", artist: "Open Music and start a song")
}

extension MPMediaItem {
    var songRaterTrack: NowPlayingTrack {
        NowPlayingTrack(
            title: title?.nilIfBlank ?? "Unknown Song",
            artist: artist?.nilIfBlank ?? albumArtist?.nilIfBlank ?? "Unknown Artist"
        )
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
