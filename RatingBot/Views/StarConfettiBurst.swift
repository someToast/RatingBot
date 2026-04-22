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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.confettiLayer.birthRate = 0
            self?.confettiLayer.emitterCells = nil
        }
    }

    private func makeCell(color: UIColor, seed: Int) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = starImage().cgImage
        cell.birthRate = 14
        cell.lifetime = 3.6
        cell.lifetimeRange = 0.6
        cell.velocity = 285
        cell.velocityRange = 70
        cell.emissionLongitude = -.pi / 2
        cell.emissionRange = .pi / 2.8
        cell.yAcceleration = 320
        cell.xAcceleration = 8
        cell.spin = 3.4
        cell.spinRange = 5.5
        cell.scale = 0.12
        cell.scaleRange = 0.06
        cell.alphaSpeed = -0.28
        cell.color = color.cgColor
        cell.name = "star-\(seed)"
        return cell
    }

    private func starImage() -> UIImage {
        let config = UIImage.SymbolConfiguration(pointSize: 42, weight: .black)
        let baseImage = UIImage(systemName: "star.fill", withConfiguration: config)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)

        return baseImage ?? UIImage()
    }
}
