import SwiftUI

public struct ContentView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Hello, Kural!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Welcome to the world of Thirukkural")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
