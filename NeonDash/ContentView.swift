import SwiftUI

struct ContentView: View {
    @StateObject private var flow = AppFlow()
    @StateObject private var state = GameState()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch flow.screen {
            case .menu:
                MenuView(state: state, onPlay: flow.play, onShop: flow.openShop)
                    .transition(.opacity)
            case .playing:
                GameView(state: state, onExit: flow.backToMenu)
                    .transition(.opacity)
            case .shop:
                ShopView(state: state, onBack: flow.backToMenu)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: flow.screen)
    }
}

#Preview {
    ContentView()
}
