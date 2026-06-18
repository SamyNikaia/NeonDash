import Foundation
import Combine

final class GameState: ObservableObject {
    @Published private(set) var score: Int = 0
    @Published private(set) var best: Int
    @Published private(set) var combo: Int = 0
    @Published private(set) var coins: Int
    @Published private(set) var isGameOver: Bool = false
    @Published private(set) var isNewBest: Bool = false

    @Published private(set) var unlockedBalls: Set<String>
    @Published private(set) var unlockedBackgrounds: Set<String>
    @Published private(set) var equippedBallId: String
    @Published private(set) var equippedBackgroundId: String

    private let defaults: UserDefaults
    private let bestKey = "neondash.bestScore"
    private let coinsKey = "neondash.coins"
    private let unlockedBallsKey = "neondash.unlockedBalls"
    private let unlockedBackgroundsKey = "neondash.unlockedBackgrounds"
    private let equippedBallKey = "neondash.equippedBall"
    private let equippedBackgroundKey = "neondash.equippedBackground"
    private var bestAtRunStart: Int

    static let fireComboThreshold = 10

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedBest = defaults.integer(forKey: bestKey)
        self.best = storedBest
        self.bestAtRunStart = storedBest
        self.coins = defaults.integer(forKey: coinsKey)

        let storedBalls = Set(defaults.stringArray(forKey: unlockedBallsKey) ?? [])
        let defaultBallId = SkinCatalog.ballSkins.first?.id ?? "magenta"
        self.unlockedBalls = storedBalls.union([defaultBallId])

        let storedBgs = Set(defaults.stringArray(forKey: unlockedBackgroundsKey) ?? [])
        let defaultBgId = SkinCatalog.backgroundSkins.first?.id ?? "indigo"
        self.unlockedBackgrounds = storedBgs.union([defaultBgId])

        self.equippedBallId = defaults.string(forKey: equippedBallKey) ?? defaultBallId
        self.equippedBackgroundId = defaults.string(forKey: equippedBackgroundKey) ?? defaultBgId
    }

    var multiplier: Int {
        switch combo {
        case 0..<5: return 1
        case 5..<15: return 2
        case 15..<30: return 3
        default: return 5
        }
    }

    var isOnFire: Bool { combo >= Self.fireComboThreshold }

    var equippedBall: BallSkin {
        SkinCatalog.ballSkins.first { $0.id == equippedBallId } ?? SkinCatalog.ballSkins[0]
    }

    var equippedBackground: BackgroundSkin {
        SkinCatalog.backgroundSkins.first { $0.id == equippedBackgroundId } ?? SkinCatalog.backgroundSkins[0]
    }

    func reset() {
        score = 0
        combo = 0
        isGameOver = false
        isNewBest = false
        bestAtRunStart = best
    }

    func addPoint() {
        combo += 1
        score += multiplier
        if score > best {
            best = score
            defaults.set(best, forKey: bestKey)
        }
    }

    func endGame() {
        isGameOver = true
        isNewBest = score > 0 && score > bestAtRunStart
    }

    func addCoins(_ amount: Int) {
        guard amount > 0 else { return }
        coins += amount
        defaults.set(coins, forKey: coinsKey)
    }

    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard amount > 0, coins >= amount else { return false }
        coins -= amount
        defaults.set(coins, forKey: coinsKey)
        return true
    }

    // MARK: - Skins

    @discardableResult
    func purchaseBall(_ id: String) -> Bool {
        guard !unlockedBalls.contains(id),
              let skin = SkinCatalog.ballSkins.first(where: { $0.id == id }),
              spendCoins(skin.cost) else { return false }
        unlockedBalls.insert(id)
        persistUnlockedBalls()
        equipBall(id)
        return true
    }

    func equipBall(_ id: String) {
        guard unlockedBalls.contains(id) else { return }
        equippedBallId = id
        defaults.set(id, forKey: equippedBallKey)
    }

    @discardableResult
    func purchaseBackground(_ id: String) -> Bool {
        guard !unlockedBackgrounds.contains(id),
              let skin = SkinCatalog.backgroundSkins.first(where: { $0.id == id }),
              spendCoins(skin.cost) else { return false }
        unlockedBackgrounds.insert(id)
        persistUnlockedBackgrounds()
        equipBackground(id)
        return true
    }

    func equipBackground(_ id: String) {
        guard unlockedBackgrounds.contains(id) else { return }
        equippedBackgroundId = id
        defaults.set(id, forKey: equippedBackgroundKey)
    }

    private func persistUnlockedBalls() {
        defaults.set(Array(unlockedBalls), forKey: unlockedBallsKey)
    }

    private func persistUnlockedBackgrounds() {
        defaults.set(Array(unlockedBackgrounds), forKey: unlockedBackgroundsKey)
    }
}
