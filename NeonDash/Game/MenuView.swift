import SwiftUI

struct MenuView: View {
    @ObservedObject var state: GameState
    let onPlay: () -> Void
    let onShop: () -> Void

    @State private var titlePulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.03, blue: 0.24),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                titleBlock

                Spacer()

                buttonStack
                    .padding(.horizontal, 36)

                Spacer()

                coinBadge
                    .padding(.bottom, 40)
            }
            .padding(.top, 80)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                titlePulse = 1.04
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 14) {
            Text("NEONDASH")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .tracking(10)
                .foregroundStyle(.white)
                .shadow(color: Color(red: 1.0, green: 0.17, blue: 0.84).opacity(0.75), radius: 18)
                .scaleEffect(titlePulse)

            if state.best > 0 {
                Text("BEST  \(state.best)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var buttonStack: some View {
        VStack(spacing: 14) {
            MenuButton(
                title: "PLAY",
                isPrimary: true,
                accent: Color(red: 1.0, green: 0.17, blue: 0.84),
                action: onPlay
            )
            MenuButton(
                title: "SHOP",
                isPrimary: false,
                accent: Color(red: 0.12, green: 0.96, blue: 1.00),
                action: onShop
            )
        }
    }

    private var coinBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(red: 1.0, green: 0.85, blue: 0.25))
                .frame(width: 12, height: 12)
                .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.25).opacity(0.8), radius: 6)
            Text("\(state.coins)")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(Color.white.opacity(0.06))
        )
        .overlay(
            Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct MenuButton: View {
    let title: String
    let isPrimary: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: isPrimary ? 22 : 16, weight: .heavy, design: .rounded))
                .tracking(isPrimary ? 6 : 4)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, isPrimary ? 18 : 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isPrimary ? accent : Color.white.opacity(0.05))
                        .shadow(color: isPrimary ? accent.opacity(0.6) : .clear, radius: 16)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(accent.opacity(isPrimary ? 0 : 0.6), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MenuView(
        state: {
            let s = GameState()
            s.addCoins(127)
            for _ in 0..<8 { s.addPoint() }
            return s
        }(),
        onPlay: {},
        onShop: {}
    )
}
