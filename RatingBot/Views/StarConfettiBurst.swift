import SwiftUI
import UIKit

struct StarConfettiBurst: UIViewRepresentable {
    let trigger: Int
    let origin: CGPoint

    func makeUIView(context: Context) -> ConfettiEmitterView {
        ConfettiEmitterView()
    }

    func updateUIView(_ uiView: ConfettiEmitterView, context: Context) {
        uiView.update(trigger: trigger, origin: origin)
    }

    static func dismantleUIView(_ uiView: ConfettiEmitterView, coordinator: ()) {
        uiView.reset()
    }
}

final class ConfettiEmitterView: UIView {
    private var lastTrigger = 0
    private var particleImages: [UIColor: CGImage] = [:]
    private var stopEmissionWorkItem: DispatchWorkItem?
    private var cleanupWorkItem: DispatchWorkItem?
    private var activeEmitterLayer: CAEmitterLayer?
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        activeEmitterLayer?.frame = bounds
    }

    func update(trigger: Int, origin: CGPoint) {
        print("[RatingBot][Confetti] update trigger=\(trigger) origin=\(origin) bounds=\(bounds)")
        guard trigger > lastTrigger, origin != .zero else {
            lastTrigger = max(lastTrigger, trigger)
            return
        }

        lastTrigger = trigger
        emit(from: clamped(origin: origin))
    }

    private func emit(from origin: CGPoint) {
        print("[RatingBot][Confetti] emit origin=\(origin) bounds=\(bounds)")
        stopEmissionWorkItem?.cancel()
        cleanupWorkItem?.cancel()
        activeEmitterLayer?.removeFromSuperlayer()

        let emitterLayer = CAEmitterLayer()
        emitterLayer.frame = bounds
        emitterLayer.emitterShape = .point
        emitterLayer.emitterMode = .points
        emitterLayer.renderMode = .unordered
        emitterLayer.seed = UInt32.random(in: 1...UInt32.max)
        emitterLayer.emitterPosition = origin
        emitterLayer.emitterCells = colors.enumerated().map { index, color in
            makeCell(color: color, seed: index)
        }
        emitterLayer.birthRate = 0
        layer.addSublayer(emitterLayer)
        activeEmitterLayer = emitterLayer

        let startTime = emitterLayer.convertTime(CACurrentMediaTime(), from: nil)
        emitterLayer.beginTime = startTime

        DispatchQueue.main.async { [weak emitterLayer] in
            emitterLayer?.birthRate = 1
        }

        let workItem = DispatchWorkItem { [weak emitterLayer] in
            emitterLayer?.birthRate = 0
        }
        stopEmissionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: workItem)

        let cleanupWorkItem = DispatchWorkItem { [weak self, weak emitterLayer] in
            guard let self, let emitterLayer else { return }
            emitterLayer.removeFromSuperlayer()
            if self.activeEmitterLayer === emitterLayer {
                self.activeEmitterLayer = nil
            }
        }
        self.cleanupWorkItem = cleanupWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.5, execute: cleanupWorkItem)
    }

    func reset() {
        stopEmissionWorkItem?.cancel()
        cleanupWorkItem?.cancel()
        activeEmitterLayer?.birthRate = 0
        activeEmitterLayer?.removeFromSuperlayer()
        activeEmitterLayer = nil
        lastTrigger = 0
    }

    private func makeCell(color: UIColor, seed: Int) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = particleImage(for: color)
        cell.birthRate = 6
        cell.lifetime = 8.5
        cell.lifetimeRange = 1.4
        cell.velocity = 670
        cell.velocityRange = 250
        cell.emissionLongitude = -.pi / 2
        cell.emissionRange = .pi / 1.9
        cell.yAcceleration = 570
        cell.xAcceleration = 0
        cell.spin = 2.6
        cell.spinRange = 4.8
        cell.scale = 0.36
        cell.scaleRange = 0.08
        cell.alphaSpeed = -0.03
        cell.name = "star-\(seed)"
        return cell
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

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            reset()
        }
    }

    private func clamped(origin: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(origin.x, 0), bounds.width),
            y: min(max(origin.y, 0), bounds.height)
        )
    }
}
