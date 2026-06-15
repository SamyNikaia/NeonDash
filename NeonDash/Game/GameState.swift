import Foundation
import Combine

final class GameState: ObservableObject {
    @Published private(set) var score: Int = 0
    @Published private(set) var best: Int
    @Published private(set) var combo: Int = 0
    @Published private(set) var isGameOver: Bool = false
    @Published private(set) var isNewBest: Bool = false

    private let defaults: UserDefaults
    private let bestKey = "neondash.bestScore"
    private var bestAtRunStart: Int

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.integer(forKey: bestKey)
        self.best = stored
        self.bestAtRunStart = stored
    }

    var multiplier: Int {
        switch combo {
        case 0..<5: return 1
        case 5..<15: return 2
        case 15..<30: return 3
        default: return 5
        }
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
}
