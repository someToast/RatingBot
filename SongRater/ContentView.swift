import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var musicService: MusicRatingService
    @State private var pendingRating: Int?

    var body: some View {
        VStack(spacing: 12) {
            nowPlayingHeader

            VStack(spacing: 10) {
                ForEach((1...5).reversed(), id: \.self) { rating in
                    RatingButton(rating: rating, isBusy: pendingRating != nil) {
                        Task {
                            await rate(rating)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
        .background(Color(red: 0.06, green: 0.07, blue: 0.08))
        .foregroundStyle(.white)
        .task {
            await musicService.requestAccessIfNeeded()
        }
    }

    private var nowPlayingHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Now Playing")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            Text(musicService.currentTrack.title)
                .font(.system(.title, design: .rounded, weight: .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.65)

            Text(musicService.currentTrack.artist)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.white.opacity(0.78))

            Text(statusText)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }

    private var statusText: String {
        if let pendingRating {
            return "Adding to Rate \(pendingRating)..."
        }
        return musicService.statusMessage
    }

    private func rate(_ rating: Int) async {
        pendingRating = rating
        defer { pendingRating = nil }

        do {
            _ = try await musicService.rateCurrentSong(rating)
        } catch {
            musicService.statusMessage = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MusicRatingService.shared)
}
