import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("NEONDASH")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .tracking(8)
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    ContentView()
}
