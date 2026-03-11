import SwiftUI

struct GoalRingView<Content: View>: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color
    @ViewBuilder let content: () -> Content

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            content()
        }
        .onAppear {
            withAnimation(AppAnimation.cardAppear.delay(0.3)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(AppAnimation.cardAppear) {
                animatedProgress = newValue
            }
        }
    }
}
