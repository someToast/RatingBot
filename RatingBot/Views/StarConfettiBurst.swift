import SwiftUI
import UIKit

struct StarConfettiBurst: UIViewRepresentable {
    let trigger: Int
    let origin: CGPoint
    let configuration: ConfettiConfiguration

    func makeUIView(context: Context) -> ConfettiBurstView {
        ConfettiBurstView()
    }

    func updateUIView(_ uiView: ConfettiBurstView, context: Context) {
        uiView.update(trigger: trigger, origin: origin, configuration: configuration)
    }

    static func dismantleUIView(_ uiView: ConfettiBurstView, coordinator: ()) {
        uiView.reset()
    }
}

struct ConfettiConfiguration: Equatable {
    var particleSize: CGFloat
    var velocityScale: CGFloat
    var gravityScale: CGFloat

    static let `default` = ConfettiConfiguration(
        particleSize: 63,
        velocityScale: 1,
        gravityScale: 0.5
    )
}

final class ConfettiBurstView: UIView {
    private var lastTrigger = 0
    private var particleImages: [UIColor: CGImage] = [:]
    private let colors: [UIColor] = [
        .systemYellow,
        .systemOrange,
        .systemPink,
        .systemPurple,
        .systemBlue,
        .systemGreen,
        .white,
        .systemRed
    ]
    private let particleCount = 48
    private let burstDuration: CFTimeInterval = 8.5
    private var configuration = ConfettiConfiguration.default

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(trigger: Int, origin: CGPoint, configuration: ConfettiConfiguration) {
        self.configuration = configuration
        guard trigger > lastTrigger, origin != .zero, bounds.width > 0, bounds.height > 0 else {
            lastTrigger = max(lastTrigger, trigger)
            return
        }

        lastTrigger = trigger
        burst(from: clamped(origin: origin), seed: trigger)
    }

    func reset() {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        lastTrigger = 0
    }

    private func burst(from origin: CGPoint, seed: Int) {
        for index in 0..<particleCount {
            let base = Double(seed * 97 + index * 37)
            let color = colors[index % colors.count]
            let particleLayer = CALayer()
            particleLayer.contents = particleImage(for: color)
            particleLayer.bounds = CGRect(x: 0, y: 0, width: configuration.particleSize, height: configuration.particleSize)
            particleLayer.position = origin
            particleLayer.opacity = 1
            particleLayer.contentsScale = UIScreen.main.scale

            layer.addSublayer(particleLayer)

            let horizontalDirection = ((pseudoRandom(base + 1) * 2) - 1)
            let xVelocity = horizontalDirection * (165 + pseudoRandom(base + 2) * 185) * configuration.velocityScale
            let initialYVelocity = -(517.5 + pseudoRandom(base + 3) * 187.5) * configuration.velocityScale
            let gravity = (545 + pseudoRandom(base + 4) * 90) * configuration.gravityScale
            let rotationAmount = ((pseudoRandom(base + 5) * 2) - 1) * CGFloat.pi * (3.6 + pseudoRandom(base + 6) * 2.8)
            let scale = 0.9 + pseudoRandom(base + 7) * 0.35
            let durationJitter = 0.88 + pseudoRandom(base + 8) * 0.28
            let particleDuration = burstDuration * durationJitter
            let path = ballisticPath(
                origin: origin,
                xVelocity: xVelocity,
                initialYVelocity: initialYVelocity,
                gravity: gravity,
                duration: particleDuration
            )

            let positionAnimation = CAKeyframeAnimation(keyPath: "position")
            positionAnimation.path = path.cgPath
            positionAnimation.calculationMode = .paced
            positionAnimation.duration = particleDuration

            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnimation.fromValue = 0
            rotationAnimation.toValue = rotationAmount
            rotationAnimation.duration = particleDuration

            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = scale * 0.92
            scaleAnimation.toValue = scale
            scaleAnimation.duration = 0.18
            scaleAnimation.autoreverses = true

            let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
            fadeAnimation.values = [1, 1, 0.92, 0]
            fadeAnimation.keyTimes = [0, 0.55, 0.82, 1]
            fadeAnimation.duration = particleDuration

            let animationGroup = CAAnimationGroup()
            animationGroup.animations = [positionAnimation, rotationAnimation, scaleAnimation, fadeAnimation]
            animationGroup.duration = particleDuration
            animationGroup.isRemovedOnCompletion = false
            animationGroup.fillMode = .forwards

            CATransaction.begin()
            CATransaction.setCompletionBlock {
                particleLayer.removeFromSuperlayer()
            }
            particleLayer.add(animationGroup, forKey: "confettiBurst")
            CATransaction.commit()
        }
    }

    private func ballisticPath(
        origin: CGPoint,
        xVelocity: CGFloat,
        initialYVelocity: CGFloat,
        gravity: CGFloat,
        duration: CFTimeInterval
    ) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: origin)

        let steps = 72
        for step in 1...steps {
            let t = CGFloat(duration) * CGFloat(step) / CGFloat(steps)
            let x = origin.x + (xVelocity * t)
            let y = origin.y + (initialYVelocity * t) + (0.5 * gravity * t * t)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }

    private func particleImage(for color: UIColor) -> CGImage? {
        if let cached = particleImages[color] {
            return cached
        }

        let image = starImage(color: color).cgImage
        if let image {
            particleImages[color] = image
        }
        return image
    }

    private func starImage(color: UIColor) -> UIImage {
        let config = UIImage.SymbolConfiguration(pointSize: 42, weight: .black)
        let symbolImage = UIImage(systemName: "star.fill", withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal)

        guard let symbolImage else { return UIImage() }

        let renderer = UIGraphicsImageRenderer(size: symbolImage.size)
        return renderer.image { _ in
            symbolImage.draw(in: CGRect(origin: .zero, size: symbolImage.size))
        }
    }

    private func clamped(origin: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(origin.x, 0), bounds.width),
            y: min(max(origin.y, 0), bounds.height)
        )
    }

    private func pseudoRandom(_ input: Double) -> CGFloat {
        let value = sin(input * 12.9898) * 43758.5453
        return CGFloat(value - floor(value))
    }
}
