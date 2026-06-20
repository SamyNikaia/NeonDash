import SwiftUI

struct HUDOverlay: View {
    @ObservedObject var state: GameState

    var body: some View {
        ZStack(alignment: .top) {
            HStack(alignment: .top) {
                heartsRow
                    .padding(.leading, 18)
                    .padding(.top, 14)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.85, blue: 0.25))
                        .frame(width: 10, height: 10)
                        .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.25).opacity(0.8), radius: 4)
                    Text("\(state.coins)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .padding(.trailing, 18)
                .padding(.top, 14)
            }

            scoreStack
        }
        .allowsHitTesting(false)
    }

    private var heartsRow: some View {
        HStack(spacing: 4) {
            ForEach(0..<GameState.maxLives, id: \.self) { i in
                Image(systemName: i < state.lives ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(
                        i < state.lives
                            ? Color(red: 1, green: 0.28, blue: 0.42)
                            : Color.white.opacity(0.22)
                    )
                    .shadow(
                        color: i < state.lives
                            ? Color(red: 1, green: 0.28, blue: 0.42).opacity(0.7)
                            : .clear,
                        radius: 5
                    )
            }
        }
        .animation(.easeOut(duration: 0.25), value: state.lives)
    }

    private var scoreStack: some View {
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

            if state.isRocketActive {
                StatusPill(text: "ROCKET", color: Color(red: 0.55, green: 0.95, blue: 1.00))
                    .transition(.scale.combined(with: .opacity))
            } else if state.isOnFire {
                StatusPill(text: "ON FIRE", color: Color(red: 1.0, green: 0.38, blue: 0.10))
                    .transition(.scale.combined(with: .opacity))
            }

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
        .animation(.easeOut(duration: 0.25), value: state.isOnFire)
        .animation(.easeOut(duration: 0.25), value: state.isRocketActive)
    }

    private struct StatusPill: View {
        let text: String
        let color: Color
        @State private var pulse: CGFloat = 1.0
        var body: some View {
            Text(text)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .tracking(5)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(color)
                        .shadow(color: color.opacity(0.8), radius: 10)
                )
                .scaleEffect(pulse)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        pulse = 1.08
                    }
                }
        }
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
