import SwiftUI

struct StarConfettiBurst: View {
    let trigger: Int
    let origin: CGPoint

    @State private var lastTrigger = 0
    @State private var startDate = Date.distantPast

    private let duration: TimeInterval = 2.2
    private let particleCount = 28
    private let colors: [Color] = [
        .yellow, .orange, .pink, .purple, .blue, .green, .white, .red
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)
            let isActive = trigger > 0 && elapsed >= 0 && elapsed <= duration && origin != .zero
            let opacity = max(0, 1 - (elapsed / duration))

            ZStack {
                if isActive {
                    ForEach(0..<particleCount, id: \.self) { index in
                        let particle = particle(for: index, trigger: trigger)
                        let position = particle.position(at: elapsed, from: origin)

                        Image(systemName: "star.fill")
                            .font(.system(size: particle.size, weight: .black))
                            .foregroundStyle(colors[particle.colorIndex % colors.count])
                            .position(position)
                            .rotationEffect(.degrees(particle.rotation * elapsed))
                            .opacity(opacity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            guard newValue != lastTrigger else { return }
            lastTrigger = newValue
            startDate = .now
        }
    }

    private func particle(for index: Int, trigger: Int) -> ConfettiParticle {
        let base = Double((index * 37) + (trigger * 53))
        let spread = pseudoRandom(base + 1)
        let direction = (spread * 2) - 1
        let xVelocity = direction * (90 + (pseudoRandom(base + 2) * 120))
        let yVelocity = -(220 + (pseudoRandom(base + 3) * 140))
        let gravity = 270 + (pseudoRandom(base + 4) * 120)
        let rotation = ((pseudoRandom(base + 5) * 360) - 180)
        let size = 10 + (pseudoRandom(base + 6) * 10)
        let colorIndex = Int(pseudoRandom(base + 7) * Double(colors.count))

        return ConfettiParticle(
            xVelocity: xVelocity,
            yVelocity: yVelocity,
            gravity: gravity,
            rotation: rotation,
            size: size,
            colorIndex: colorIndex
        )
    }

    private func pseudoRandom(_ input: Double) -> Double {
        let value = sin(input * 12.9898) * 43758.5453
        return value - floor(value)
    }
}

private struct ConfettiParticle {
    let xVelocity: Double
    let yVelocity: Double
    let gravity: Double
    let rotation: Double
    let size: Double
    let colorIndex: Int

    func position(at elapsed: TimeInterval, from origin: CGPoint) -> CGPoint {
        let x = origin.x + (xVelocity * elapsed)
        let y = origin.y + (yVelocity * elapsed) + (0.5 * gravity * elapsed * elapsed)
        return CGPoint(x: x, y: y)
    }
}
