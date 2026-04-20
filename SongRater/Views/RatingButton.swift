import SwiftUI

struct RatingButton: View {
    let rating: Int
    let isBusy: Bool
    let action: () -> Void

    private var stars: String {
        String(repeating: "⭐️", count: rating)
    }

    var body: some View {
        Button(action: action) {
            Text(stars)
                .font(.system(size: 48, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .background(buttonColor)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .opacity(isBusy ? 0.58 : 1)
        .accessibilityLabel("\(rating) star\(rating == 1 ? "" : "s")")
    }

    private var buttonColor: Color {
        switch rating {
        case 5:
            return Color(red: 0.08, green: 0.46, blue: 0.30)
        case 4:
            return Color(red: 0.14, green: 0.43, blue: 0.62)
        case 3:
            return Color(red: 0.49, green: 0.38, blue: 0.16)
        case 2:
            return Color(red: 0.62, green: 0.25, blue: 0.27)
        default:
            return Color(red: 0.37, green: 0.33, blue: 0.40)
        }
    }
}
