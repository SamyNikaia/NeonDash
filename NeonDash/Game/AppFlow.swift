import SwiftUI

final class AppFlow: ObservableObject {
    enum Screen {
        case menu
        case playing
        case shop
    }

    @Published var screen: Screen = .menu

    func play() { screen = .playing }
    func openShop() { screen = .shop }
    func backToMenu() { screen = .menu }
}
