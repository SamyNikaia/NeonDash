import SpriteKit

struct BallSkin: Identifiable, Equatable {
    let id: String
    let name: String
    let color: SKColor
    let cost: Int
}

struct BackgroundSkin: Identifiable, Equatable {
    let id: String
    let name: String
    let palettes: [Theme.BackgroundPalette]
    let cost: Int

    static func == (lhs: BackgroundSkin, rhs: BackgroundSkin) -> Bool {
        lhs.id == rhs.id
    }
}

enum SkinCatalog {
    static let ballSkins: [BallSkin] = [
        BallSkin(id: "magenta",  name: "MAGENTA",  color: SKColor(red: 1.00, green: 0.17, blue: 0.84, alpha: 1), cost: 0),
        BallSkin(id: "cyan",     name: "CYAN",     color: SKColor(red: 0.12, green: 0.96, blue: 1.00, alpha: 1), cost: 40),
        BallSkin(id: "solar",    name: "SOLAR",    color: SKColor(red: 1.00, green: 0.78, blue: 0.20, alpha: 1), cost: 75),
        BallSkin(id: "frost",    name: "FROST",    color: SKColor(red: 0.82, green: 0.94, blue: 1.00, alpha: 1), cost: 100),
        BallSkin(id: "crimson",  name: "CRIMSON",  color: SKColor(red: 0.95, green: 0.15, blue: 0.30, alpha: 1), cost: 150),
        BallSkin(id: "phantom",  name: "PHANTOM",  color: SKColor(red: 0.40, green: 0.20, blue: 0.95, alpha: 1), cost: 220),
    ]

    static let backgroundSkins: [BackgroundSkin] = [
        BackgroundSkin(
            id: "indigo",
            name: "INDIGO",
            palettes: Theme.palettes,
            cost: 0
        ),
        BackgroundSkin(
            id: "sunset",
            name: "SUNSET",
            palettes: [
                Theme.BackgroundPalette(top: SKColor(red: 0.45, green: 0.08, blue: 0.12, alpha: 1), bottom: SKColor(red: 0.08, green: 0.00, blue: 0.02, alpha: 1)),
                Theme.BackgroundPalette(top: SKColor(red: 0.65, green: 0.18, blue: 0.10, alpha: 1), bottom: SKColor(red: 0.12, green: 0.02, blue: 0.00, alpha: 1)),
                Theme.BackgroundPalette(top: SKColor(red: 0.85, green: 0.30, blue: 0.05, alpha: 1), bottom: SKColor(red: 0.20, green: 0.04, blue: 0.00, alpha: 1)),
                Theme.BackgroundPalette(top: SKColor(red: 0.95, green: 0.45, blue: 0.20, alpha: 1), bottom: SKColor(red: 0.30, green: 0.08, blue: 0.02, alpha: 1)),
                Theme.BackgroundPalette(top: SKColor(red: 1.00, green: 0.60, blue: 0.30, alpha: 1), bottom: SKColor(red: 0.40, green: 0.10, blue: 0.04, alpha: 1)),
            ],
            cost: 80
        ),
        BackgroundSkin(
            id: "ocean",
            name: "OCEAN",
            palettes: [
                Theme.BackgroundPalette(top: SKColor(red: 0.02, green: 0.10, blue: 0.22, alpha: 1), bottom: SKColor(red: 0.00, green: 0.02, blue: 0.06, alpha: 1)),
                Theme.BackgroundPalette(top: SKColor(red: 0.04, green: 0.18, blue: 0.32, alpha: 1), bottom: SKColor(red: 0.00, green: 0.04, blue: 0.10, alpha: 1)),
                Theme.BackgroundPalette(top: SKColor(red: 0.06, green: 0.28, blue: 0.42, alpha: 1), bottom: SKColor(red: 0.00, green: 0.06, blue: 0.14, alpha: 1)),
                Theme.BackgroundPalette(top: SKColor(red: 0.10, green: 0.40, blue: 0.55, alpha: 1), bottom: SKColor(red: 0.02, green: 0.10, blue: 0.20, alpha: 1)),
                Theme.BackgroundPalette(top: SKColor(red: 0.14, green: 0.55, blue: 0.68, alpha: 1), bottom: SKColor(red: 0.04, green: 0.14, blue: 0.26, alpha: 1)),
            ],
            cost: 80
        ),
        BackgroundSkin(
            id: "verdant",
            name: "VERDANT",
            palettes: [
                Theme.BackgroundPalette(top: SKColor(red: 0.04, green: 0.18, blue: 0.10, alpha: 1), bottom: SKColor(red: 0.00, green: 0.04, blue: 0.02, alpha: 1)),
                Theme.BackgroundPalette(top: SKColor(red: 0.08, green: 0.30, blue: 0.16, alpha: 1), bottom: SKColor(red: 0.00, green: 0.08, blue: 0.04, alpha: 1)),
                Theme.BackgroundPalette(top: SKColor(red: 0.16, green: 0.40, blue: 0.20, alpha: 1), bottom: SKColor(red: 0.02, green: 0.10, blue: 0.06, alpha: 1)),
                Theme.BackgroundPalette(top: SKColor(red: 0.24, green: 0.52, blue: 0.18, alpha: 1), bottom: SKColor(red: 0.06, green: 0.16, blue: 0.06, alpha: 1)),
                Theme.BackgroundPalette(top: SKColor(red: 0.40, green: 0.65, blue: 0.20, alpha: 1), bottom: SKColor(red: 0.10, green: 0.22, blue: 0.08, alpha: 1)),
            ],
            cost: 100
        ),
        BackgroundSkin(
            id: "void",
            name: "VOID",
            palettes: [
                Theme.BackgroundPalette(top: SKColor(red: 0.02, green: 0.02, blue: 0.06, alpha: 1), bottom: SKColor.black),
                Theme.BackgroundPalette(top: SKColor(red: 0.06, green: 0.04, blue: 0.14, alpha: 1), bottom: SKColor.black),
                Theme.BackgroundPalette(top: SKColor(red: 0.10, green: 0.06, blue: 0.22, alpha: 1), bottom: SKColor.black),
                Theme.BackgroundPalette(top: SKColor(red: 0.14, green: 0.08, blue: 0.32, alpha: 1), bottom: SKColor.black),
                Theme.BackgroundPalette(top: SKColor(red: 0.20, green: 0.10, blue: 0.42, alpha: 1), bottom: SKColor.black),
            ],
            cost: 180
        ),
    ]
}
