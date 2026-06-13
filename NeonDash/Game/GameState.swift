import Foundation
import Combine

final class GameState: ObservableObject {
    @Published private(set) var score: Int = 0
    @Published private(set) var best: Int

    private let defaults: UserDefaults
    private let bestKey = "neondash.bestScore"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.best = defaults.integer(forKey: bestKey)
    }

    func reset() {
        score = 0
    }

    func addPoint() {
        score += 1
        if score > best {
            best = score
            defaults.set(best, forKey: bestKey)
        }
    }
}
