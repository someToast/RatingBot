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

    var musicAssignedRating: Int? {
        guard let rating = value(forProperty: MPMediaItemPropertyRating) as? NSNumber else {
            return nil
        }

        let stars = rating.intValue
        return (1...5).contains(stars) ? stars : nil
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
