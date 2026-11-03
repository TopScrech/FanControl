import SwiftUI
import QuartzCore

final class FanRotorHostingView: NSView {
    private let rotor = CALayer()
    private var symbolSize = CGSize.zero
    private var selected: Bool?
    private var rotationSpeed: Float = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.addSublayer(rotor)
        rotor.speed = 0
        setAccessibilityElement(false)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        rotor.bounds = CGRect(origin: .zero, size: symbolSize)
        rotor.position = CGPoint(x: bounds.midX, y: bounds.midY)
        CATransaction.commit()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateSymbol()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        updateSymbol()
    }

    func update(rpm: Double, isSelected: Bool) {
        if selected != isSelected {
            selected = isSelected
            updateSymbol()
        }

        let speed = Float(min(max(rpm, 0) * 0.11, 480) / 360)
        guard rotationSpeed != speed else { return }

        if speed > 0, rotor.animation(forKey: "rotation") == nil {
            let animation = CABasicAnimation(keyPath: "transform.rotation.z")
            animation.fromValue = 0
            animation.toValue = Double.pi * 2
            animation.duration = 1
            animation.repeatCount = .infinity
            rotor.add(animation, forKey: "rotation")
        }

        // Preserve the current angle when changing speed or pausing
        let parentTime = layer?.convertTime(CACurrentMediaTime(), from: nil) ?? CACurrentMediaTime()
        let localTime = rotor.convertTime(CACurrentMediaTime(), from: nil)
        rotor.speed = speed
        rotor.timeOffset = speed == 0 ? localTime : 0
        rotor.beginTime = speed == 0 ? 0 : parentTime - localTime / Double(speed)
        rotationSpeed = speed
    }

    func stop() {
        rotor.removeAllAnimations()
    }

    private func updateSymbol() {
        let color: NSColor = selected == true ? .white : .labelColor
        let configuration = NSImage.SymbolConfiguration(textStyle: .title2)
            .applying(.init(paletteColors: [color]))
        guard let image = NSImage(systemSymbolName: "fanblades.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration) else { return }

        symbolSize = image.size
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        rotor.contentsScale = window?.backingScaleFactor ?? 2
        rotor.contents = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        CATransaction.commit()
        needsLayout = true
    }
}
