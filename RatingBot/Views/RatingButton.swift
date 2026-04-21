import SwiftUI

struct RatingButton: View {
    let rating: Int
    let isBusy: Bool
    let isAssigned: Bool
    let action: () -> Void

    private var stars: String {
        String(repeating: "★", count: rating)
    }

    var body: some View {
        Button(action: action) {
            Text(stars)
                .font(.system(size: 48))
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .tracking(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .background(buttonColor)
        .foregroundStyle(isAssigned ? .black : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isAssigned ? .clear : .white.opacity(0.18),
                    lineWidth: isAssigned ? 0 : 1
                )
        }
        .opacity(isBusy ? 0.58 : 1)
        .accessibilityLabel("\(rating) star\(rating == 1 ? "" : "s")")
    }

    private var buttonColor: Color {
        if isAssigned {
            return .yellow
        }

        switch rating {
        case 5:
            return Color(red: 10 / 255, green: 95 / 255, blue: 207 / 255)
        case 4:
            return Color(red: 53 / 255, green: 74 / 255, blue: 157 / 255)
        case 3:
            return Color(red: 96 / 255, green: 52 / 255, blue: 108 / 255)
        case 2:
            return Color(red: 138 / 255, green: 31 / 255, blue: 58 / 255)
        default:
            return Color(red: 181 / 255, green: 9 / 255, blue: 9 / 255)
        }
    }
}
