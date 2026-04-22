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
}

final class ConfettiEmitterView: UIView {
    private let confettiLayer = CAEmitterLayer()
    private var lastTrigger = 0
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

        confettiLayer.emitterShape = .point
        confettiLayer.emitterMode = .points
        confettiLayer.renderMode = .unordered
        layer.addSublayer(confettiLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        confettiLayer.frame = bounds
    }

    func update(trigger: Int, origin: CGPoint) {
        confettiLayer.frame = bounds

        guard trigger > lastTrigger, origin != .zero else {
            lastTrigger = max(lastTrigger, trigger)
            return
        }

        lastTrigger = trigger
        emit(from: origin)
    }

    private func emit(from origin: CGPoint) {
        confettiLayer.emitterPosition = origin
        confettiLayer.emitterCells = colors.enumerated().map { index, color in
            makeCell(color: color, seed: index)
        }

        confettiLayer.beginTime = CACurrentMediaTime()
        confettiLayer.birthRate = 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.confettiLayer.birthRate = 0
            self?.confettiLayer.emitterCells = nil
        }
    }

    private func makeCell(color: UIColor, seed: Int) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = starImage(color: color).cgImage
        cell.birthRate = 4
        cell.lifetime = 6.8
        cell.lifetimeRange = 1.2
        cell.velocity = 335
        cell.velocityRange = 125
        cell.emissionLongitude = -.pi / 2
        cell.emissionRange = .pi / 1.9
        cell.yAcceleration = 285
        cell.xAcceleration = 0
        cell.spin = 2.6
        cell.spinRange = 4.8
        cell.scale = 0.36
        cell.scaleRange = 0.08
        cell.alphaSpeed = -0.08
        cell.name = "star-\(seed)"
        return cell
    }

    private func starImage(color: UIColor) -> UIImage {
        let config = UIImage.SymbolConfiguration(pointSize: 42, weight: .black)
        let baseImage = UIImage(systemName: "star.fill", withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal)

        return baseImage ?? UIImage()
    }
}
