import UIKit

enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)

    static func prepare() {
        light.prepare()
        heavy.prepare()
    }

    static func tap() {
        light.impactOccurred(intensity: 0.6)
        light.prepare()
    }

    static func crash() {
        heavy.impactOccurred(intensity: 1.0)
        heavy.prepare()
    }
}
