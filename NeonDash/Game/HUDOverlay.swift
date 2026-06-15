import SwiftUI

struct HUDOverlay: View {
    @ObservedObject var state: GameState

    var body: some View {
        VStack(spacing: 4) {
            Text("BEST  \(state.best)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.45))

            Text("\(state.score)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.4), radius: 8)

            if state.combo > 0 {
                HStack(spacing: 8) {
                    Text("×\(state.multiplier)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(multiplierColor(state.multiplier))
                        .shadow(color: multiplierColor(state.multiplier).opacity(0.7), radius: 6)
                    Text("·")
                        .foregroundStyle(.white.opacity(0.4))
                    Text("COMBO \(state.combo)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.7))
                        .monospacedDigit()
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.multiplier)
        .allowsHitTesting(false)
    }

    private func multiplierColor(_ m: Int) -> Color {
        switch m {
        case 2: return Color(red: 0.45, green: 0.95, blue: 1.0)
        case 3: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case 5...: return Color(red: 1.0, green: 0.2, blue: 0.5)
        default: return .white
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HUDOverlay(state: {
            let s = GameState()
            for _ in 0..<7 { s.addPoint() }
            return s
        }())
    }
}
