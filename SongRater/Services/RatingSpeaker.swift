import AVFoundation
import Foundation

@MainActor
final class RatingSpeaker {
    static let shared = RatingSpeaker()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    func speak(rating: Int, track: NowPlayingTrack) {
        let phrase = "\(rating) stars, \(track.title) by \(track.artist)"
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        synthesizer.speak(utterance)
    }
}
