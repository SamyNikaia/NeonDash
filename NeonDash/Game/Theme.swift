import SpriteKit
import UIKit

enum Theme {
    struct BackgroundPalette {
        let top: SKColor
        let bottom: SKColor
    }

    static let palettes: [BackgroundPalette] = [
        BackgroundPalette(
            top:    SKColor(red: 0.06, green: 0.02, blue: 0.18, alpha: 1),
            bottom: SKColor(red: 0.00, green: 0.00, blue: 0.02, alpha: 1)
        ),
        BackgroundPalette(
            top:    SKColor(red: 0.22, green: 0.05, blue: 0.32, alpha: 1),
            bottom: SKColor(red: 0.04, green: 0.00, blue: 0.10, alpha: 1)
        ),
        BackgroundPalette(
            top:    SKColor(red: 0.38, green: 0.04, blue: 0.26, alpha: 1),
            bottom: SKColor(red: 0.10, green: 0.00, blue: 0.08, alpha: 1)
        ),
        BackgroundPalette(
            top:    SKColor(red: 0.02, green: 0.20, blue: 0.30, alpha: 1),
            bottom: SKColor(red: 0.00, green: 0.04, blue: 0.10, alpha: 1)
        ),
        BackgroundPalette(
            top:    SKColor(red: 0.04, green: 0.24, blue: 0.10, alpha: 1),
            bottom: SKColor(red: 0.00, green: 0.06, blue: 0.02, alpha: 1)
        )
    ]

    static let paletteThresholds: [Int] = [0, 25, 50, 100, 200]

    static let player = SKColor(red: 1.00, green: 0.17, blue: 0.84, alpha: 1)
    static let obstacle = SKColor(red: 0.12, green: 0.96, blue: 1.00, alpha: 1)
    static let obstacleFast = SKColor(red: 1.00, green: 0.42, blue: 0.16, alpha: 1)
    static let rail = SKColor(red: 0.50, green: 0.30, blue: 0.80, alpha: 1)
    static let coin = SKColor(red: 1.00, green: 0.85, blue: 0.25, alpha: 1)

    /// Layered halo + solid core for a cheap neon glow.
    static func glowingCircle(radius: CGFloat, color: SKColor) -> SKNode {
        let container = SKNode()
        let halos: [(CGFloat, CGFloat)] = [(2.6, 0.10), (1.9, 0.20), (1.35, 0.40)]
        for (mult, alpha) in halos {
            let halo = SKShapeNode(circleOfRadius: radius * mult)
            halo.fillColor = color.withAlphaComponent(alpha)
            halo.strokeColor = .clear
            halo.blendMode = .add
            container.addChild(halo)
        }
        let core = SKShapeNode(circleOfRadius: radius)
        core.fillColor = color
        core.strokeColor = .clear
        container.addChild(core)
        return container
    }

    static func glowingBar(size: CGSize, color: SKColor, cornerRadius: CGFloat = 4) -> SKNode {
        let container = SKNode()
        let halos: [(CGFloat, CGFloat)] = [(2.2, 0.10), (1.6, 0.20), (1.2, 0.40)]
        for (mult, alpha) in halos {
            let scaled = CGSize(width: size.width * mult, height: size.height * mult)
            let halo = SKShapeNode(rectOf: scaled, cornerRadius: cornerRadius * mult)
            halo.fillColor = color.withAlphaComponent(alpha)
            halo.strokeColor = .clear
            halo.blendMode = .add
            container.addChild(halo)
        }
        let core = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        core.fillColor = color
        core.strokeColor = .clear
        container.addChild(core)
        return container
    }
}

extension SKTexture {
    /// Vertical linear gradient baked into a texture.
    static func verticalGradient(top: SKColor, bottom: SKColor, size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) else { return }
            cg.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
        return SKTexture(image: image)
    }

    static func radialDot(radius: CGFloat, color: SKColor) -> SKTexture {
        let side = max(1, radius * 2)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        let image = renderer.image { _ in
            let rect = CGRect(x: 0, y: 0, width: side, height: side)
            color.setFill()
            UIBezierPath(ovalIn: rect).fill()
        }
        return SKTexture(image: image)
    }
}
