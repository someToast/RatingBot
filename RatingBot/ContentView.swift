import Foundation
import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var musicService: MusicRatingService
    @State private var pendingRating: Int?
    @State private var fiveStarButtonFrame: CGRect = .zero
    @State private var confettiTrigger = 0

    var body: some View {
        ZStack {
            VStack(spacing: 22) {
                nowPlayingHeader
                transportControls
                progressIndicator

                VStack(spacing: 10) {
                    ForEach((1...5).reversed(), id: \.self) { rating in
                        RatingButton(
                            rating: rating,
                            isPending: pendingRating == rating,
                            isDisabled: pendingRating != nil,
                            isAssigned: musicService.assignedRating == rating
                        ) {
                            triggerButtonHaptic()
                            Task {
                                await rate(rating)
                            }
                        }
                        .background {
                            if rating == 5 {
                                GeometryReader { proxy in
                                    Color.clear
                                        .preference(
                                            key: FiveStarButtonFrameKey.self,
                                            value: proxy.frame(in: .named("ContentViewSpace"))
                                        )
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.top, 34)
            .padding(.bottom, 16)

            StarConfettiBurst(
                trigger: confettiTrigger,
                origin: CGPoint(x: fiveStarButtonFrame.midX, y: fiveStarButtonFrame.midY),
                configuration: .default
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
        }
        .coordinateSpace(name: "ContentViewSpace")
        .background(Color(red: 0.06, green: 0.07, blue: 0.08))
        .foregroundStyle(.white)
        .task {
            await musicService.requestAccessIfNeeded()
        }
        .onPreferenceChange(FiveStarButtonFrameKey.self) { fiveStarButtonFrame = $0 }
    }

    private var nowPlayingHeader: some View {
        VStack(spacing: 7) {
            Text(musicService.currentTrack.title)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .tracking(-0.43)

            Text(musicService.currentTrack.artist)
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Color(red: 199 / 255, green: 199 / 255, blue: 204 / 255))
                .tracking(-0.25)

            Text(statusText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(red: 174 / 255, green: 174 / 255, blue: 178 / 255))
                .lineLimit(1)
                .frame(height: 16, alignment: .top)
                .opacity(statusText.isEmpty ? 0 : 1)
        }
        .frame(maxWidth: .infinity)
    }

    private var transportControls: some View {
        HStack(spacing: 0) {
            transportButton(systemName: "backward.fill", action: musicService.skipToPreviousTrack)

            Spacer(minLength: 18)

            Text(remainingTimeText)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .tracking(-0.43)
                .monospacedDigit()
                .frame(maxWidth: .infinity)

            Spacer(minLength: 18)

            transportButton(systemName: "forward.fill", action: musicService.skipToNextTrack)
        }
        .frame(height: 80)
    }

    private var progressIndicator: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255))

                Capsule()
                    .fill(Color(red: 1.0, green: 141 / 255, blue: 40 / 255))
                    .frame(width: geometry.size.width * remainingFraction)
                    .offset(x: geometry.size.width * elapsedFraction)
            }
        }
        .frame(height: 6)
    }

    private var statusText: String {
        if let pendingRating {
            return "Adding to RatingBot \(pendingRating)..."
        }
        return musicService.statusMessage
    }

    private var remainingTimeText: String {
        let remaining = max(musicService.playbackDuration - musicService.currentPlaybackTime, 0)
        return format(timeInterval: remaining)
    }

    private var elapsedFraction: CGFloat {
        guard musicService.playbackDuration > 0 else { return 0 }
        return CGFloat(musicService.currentPlaybackTime / musicService.playbackDuration)
    }

    private var remainingFraction: CGFloat {
        guard musicService.playbackDuration > 0 else { return 0 }
        return CGFloat(max(musicService.playbackDuration - musicService.currentPlaybackTime, 0) / musicService.playbackDuration)
    }

    private func rate(_ rating: Int) async {
        pendingRating = rating
        defer { pendingRating = nil }

        do {
            _ = try await musicService.rateCurrentSong(rating)
            if rating == 5 {
                confettiTrigger += 1
            }
        } catch {
            musicService.statusMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private func transportButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 31, weight: .bold))
                .frame(width: 80, height: 80)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .overlay {
            Circle()
                .strokeBorder(.white, lineWidth: 2)
        }
        .disabled(musicService.currentTrack == .empty)
    }

    private func format(timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval.rounded(.down))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):" + String(format: "%02d", seconds)
    }

    private func triggerButtonHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: 0.9)
    }
}

#Preview {
    ContentView()
        .environmentObject(MusicRatingService.shared)
}

private struct FiveStarButtonFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}
