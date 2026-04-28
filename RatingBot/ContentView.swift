import Foundation
import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var musicService: MusicRatingService
    @State private var pendingRating: Int?
    @State private var fiveStarButtonFrame: CGRect = .zero
    @State private var confettiTrigger = 0
    @State private var isSpeedModeEnabled = false

    var body: some View {
        ZStack {
            VStack(spacing: 22) {
                nowPlayingHeader
                if isSpeedModeEnabled {
                    speedModeBanner
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                }
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
                            startRating(rating)
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
            try? await Task.sleep(nanoseconds: 150_000_000)
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
                .frame(height: 36)

            Text(musicService.currentTrack.artist)
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Color(red: 199 / 255, green: 199 / 255, blue: 204 / 255))
                .tracking(-0.25)
                .frame(height: 25)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 68)
    }

    private var transportControls: some View {
        GeometryReader { geometry in
            let outerButtonSize: CGFloat = 72
            let seekButtonWidth: CGFloat = 64
            let seekButtonOffset = outerButtonSize + 6

            ZStack {
                transportButton(systemName: "backward.fill", size: outerButtonSize, action: musicService.skipToPreviousTrack)
                    .position(x: outerButtonSize / 2, y: geometry.size.height / 2)
                transportButton(
                    systemName: "30.arrow.trianglehead.counterclockwise",
                    size: seekButtonWidth,
                    weight: .light,
                    showsRing: false,
                    action: musicService.skipBackward30Seconds
                )
                .position(x: seekButtonOffset + seekButtonWidth / 2, y: geometry.size.height / 2)

                Text(remainingTimeText)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .tracking(-0.43)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(width: 116, height: 48)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.smooth(duration: 0.28)) {
                            isSpeedModeEnabled.toggle()
                        }
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                transportButton(
                    systemName: "30.arrow.trianglehead.clockwise",
                    size: seekButtonWidth,
                    weight: .light,
                    showsRing: false,
                    action: musicService.skipForward30Seconds
                )
                .position(x: geometry.size.width - seekButtonOffset - seekButtonWidth / 2, y: geometry.size.height / 2)
                transportButton(systemName: "forward.fill", size: outerButtonSize, action: musicService.skipToNextTrack)
                    .position(x: geometry.size.width - outerButtonSize / 2, y: geometry.size.height / 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 80)
    }

    private var speedModeBanner: some View {
        HStack(spacing: 10) {
            SpeedModeStripe()
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: .white, location: 0.68),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .frame(height: 12)

            Text("SPEED MODE")
                .font(.system(size: 15, weight: .medium))
                .tracking(6)
                .foregroundStyle(.yellow)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            SpeedModeStripe()
                .scaleEffect(x: -1, y: 1)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white, location: 0.32),
                            .init(color: .white, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .frame(height: 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 22)
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

    private func startRating(_ rating: Int) {
        triggerButtonHaptic()
        pendingRating = rating

        Task {
            let speedModeWasEnabled = isSpeedModeEnabled
            let speechTask = Task { @MainActor in
                await speakRatingConfirmation(rating, ratingOnly: speedModeWasEnabled)
            }

            try? await Task.sleep(nanoseconds: 350_000_000)
            await rate(rating)
            await speechTask.value

            if speedModeWasEnabled {
                musicService.skipToNextTrackAndPlay()
            }
        }
    }

    private func rate(_ rating: Int) async {
        defer { pendingRating = nil }

        do {
            _ = try await musicService.rateCurrentSong(rating, shouldSpeak: false)
            if rating == 5 {
                confettiTrigger += 1
            }
        } catch {
            musicService.statusMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private func transportButton(
        systemName: String,
        size: CGFloat,
        weight: Font.Weight = .bold,
        showsRing: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.39, weight: weight))
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .overlay {
            if showsRing {
                Circle()
                    .strokeBorder(.white, lineWidth: 2)
            }
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

    private func speakRatingConfirmation(_ rating: Int, ratingOnly: Bool) async {
        guard musicService.currentTrack != .empty else { return }
        await RatingSpeaker.shared.speakAndWait(rating: rating, track: musicService.currentTrack, ratingOnly: ratingOnly)
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

private struct SpeedModeStripe: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let stripeWidth: CGFloat = 7
                let gap: CGFloat = 9
                var x: CGFloat = -size.height

                while x < size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: size.height))
                    path.addLine(to: CGPoint(x: x + stripeWidth, y: size.height))
                    path.addLine(to: CGPoint(x: x + stripeWidth + size.height, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height, y: 0))
                    path.closeSubpath()
                    context.fill(path, with: .color(.yellow))
                    x += stripeWidth + gap
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(.black)
            .clipped()
        }
    }
}
