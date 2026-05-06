import SwiftUI

struct FlipCardView: View {
    let front: String
    let back: String
    let hint: String?

    @Binding var isFlipped: Bool
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            cardFace(text: back, isBack: true)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(rotation > 90 ? 1 : 0)

            cardFace(text: front, isBack: false)
                .opacity(rotation <= 90 ? 1 : 0)
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        .onTapGesture {
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                isFlipped.toggle()
                rotation = isFlipped ? 180 : 0
            }
        }
        .onChange(of: isFlipped) { _, newValue in
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                rotation = newValue ? 180 : 0
            }
        }
    }

    private func cardFace(text: String, isBack: Bool) -> some View {
        VStack(spacing: 16) {
            Text(isBack ? "ANSWER" : "QUESTION")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .tracking(2)

            Spacer()

            Text(text)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if !isBack, let hint, !hint.isEmpty {
                Text("💡 \(hint)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            Spacer()

            Text(isBack ? "" : "Tap to reveal answer")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 300)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isBack ? Color.green.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal, 20)
    }
}

#Preview("Front") {
    FlipCardView(
        front: "What is the capital of France?",
        back: "Paris",
        hint: "City of Light",
        isFlipped: .constant(false)
    )
    .padding()
}

#Preview("Flipped") {
    FlipCardView(
        front: "What is the capital of France?",
        back: "Paris",
        hint: "City of Light",
        isFlipped: .constant(true)
    )
    .padding()
}
