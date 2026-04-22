import SwiftUI
import UIKit

struct StarConfettiBurst: UIViewRepresentable {
    let trigger: Int
    let origin: CGPoint

    func makeUIView(context: Context) -> ConfettiBurstView {
        ConfettiBurstView()
    }

    func updateUIView(_ uiView: ConfettiBurstView, context: Context) {
        uiView.update(trigger: trigger, origin: origin)
    }

    static func dismantleUIView(_ uiView: ConfettiBurstView, coordinator: ()) {
        uiView.reset()
    }
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(trigger: Int, origin: CGPoint) {
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
            particleLayer.bounds = CGRect(x: 0, y: 0, width: 42, height: 42)
            particleLayer.position = origin
            particleLayer.opacity = 1
            particleLayer.contentsScale = UIScreen.main.scale

            layer.addSublayer(particleLayer)

            let xVelocity = ((pseudoRandom(base + 1) * 2) - 1) * (240 + pseudoRandom(base + 2) * 260)
            let initialYVelocity = -(670 + pseudoRandom(base + 3) * 280)
            let gravity = 570 + pseudoRandom(base + 4) * 140
            let drift = ((pseudoRandom(base + 5) * 2) - 1) * 30
            let rotationAmount = ((pseudoRandom(base + 6) * 2) - 1) * CGFloat.pi * (3 + pseudoRandom(base + 7) * 4)
            let scale = 0.9 + pseudoRandom(base + 8) * 0.35

            let start = CGPoint(x: origin.x, y: origin.y)
            let peak = CGPoint(
                x: origin.x + (xVelocity * 0.35),
                y: origin.y + (initialYVelocity * 0.35) + (0.5 * gravity * 0.35 * 0.35)
            )
            let end = CGPoint(
                x: origin.x + (xVelocity * burstDuration) + drift,
                y: origin.y + (initialYVelocity * burstDuration) + (0.5 * gravity * burstDuration * burstDuration)
            )

            let path = UIBezierPath()
            path.move(to: start)
            path.addQuadCurve(to: end, controlPoint: peak)

            let positionAnimation = CAKeyframeAnimation(keyPath: "position")
            positionAnimation.path = path.cgPath
            positionAnimation.calculationMode = .paced
            positionAnimation.duration = burstDuration
            positionAnimation.timingFunctions = [CAMediaTimingFunction(name: .easeOut)]

            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnimation.fromValue = 0
            rotationAnimation.toValue = rotationAmount
            rotationAnimation.duration = burstDuration

            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = scale * 0.92
            scaleAnimation.toValue = scale
            scaleAnimation.duration = 0.18
            scaleAnimation.autoreverses = true

            let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
            fadeAnimation.values = [1, 1, 0.92, 0]
            fadeAnimation.keyTimes = [0, 0.55, 0.82, 1]
            fadeAnimation.duration = burstDuration

            let animationGroup = CAAnimationGroup()
            animationGroup.animations = [positionAnimation, rotationAnimation, scaleAnimation, fadeAnimation]
            animationGroup.duration = burstDuration
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
