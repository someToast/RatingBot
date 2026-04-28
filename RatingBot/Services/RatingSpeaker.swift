@preconcurrency import AVFoundation
import Foundation

@MainActor
final class RatingSpeaker: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = RatingSpeaker()

    nonisolated(unsafe) private let synthesizer = AVSpeechSynthesizer()
    private var completion: (() -> Void)?

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(rating: Int, track: NowPlayingTrack, ratingOnly: Bool = false, completion: (() -> Void)? = nil) {
        let ratingText = Self.ratingText(for: rating)
        let phrase = ratingOnly ? "\(ratingText) stars" : "\(ratingText) stars, \(track.title) by \(track.artist)"
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        self.completion = completion
        synthesizer.speak(utterance)
    }

    func speakAndWait(rating: Int, track: NowPlayingTrack, ratingOnly: Bool = false) async {
        await withCheckedContinuation { continuation in
            speak(rating: rating, track: track, ratingOnly: ratingOnly) {
                continuation.resume()
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            let completion = self.completion
            self.completion = nil
            completion?()
            RatingSpeaker.releaseAudioSession()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.completion = nil
            RatingSpeaker.releaseAudioSession()
        }
    }

    private static func releaseAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private static func ratingText(for rating: Int) -> String {
        switch rating {
        case 1:
            return "One"
        case 2:
            return "Two"
        case 3:
            return "Three"
        case 4:
            return "Four"
        case 5:
            return "Five"
        default:
            return "\(rating)"
        }
    }
}
