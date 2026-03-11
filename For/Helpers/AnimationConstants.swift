import SwiftUI

enum AppAnimation {
    static let cardAppear: Animation = .spring(response: 0.5, dampingFraction: 0.8)
    static let quickSpring: Animation = .spring(response: 0.35, dampingFraction: 0.7)
    static let gentleBounce: Animation = .spring(response: 0.4, dampingFraction: 0.6)
    static let smooth: Animation = .easeInOut(duration: 0.3)
    static let cardFlip: Animation = .spring(response: 0.6, dampingFraction: 0.8)
    static let counter: Animation = .spring(response: 0.4, dampingFraction: 0.8)

    static func staggerDelay(index: Int) -> Double {
        Double(index) * 0.06
    }
}

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .scaleEffect(appeared ? 1 : 0.95)
            .animation(
                AppAnimation.cardAppear.delay(AppAnimation.staggerDelay(index: index)),
                value: appeared
            )
            .onAppear { appeared = true }
    }
}

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppAnimation.quickSpring, value: configuration.isPressed)
    }
}

struct AnimatedCounter: View {
    let value: Int
    let font: Font
    let color: Color

    init(value: Int, font: Font = .title.bold(), color: Color = .purple) {
        self.value = value
        self.font = font
        self.color = color
    }

    var body: some View {
        Text("\(value)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .animation(AppAnimation.counter, value: value)
    }
}

struct BounceModifier: ViewModifier {
    let trigger: Bool

    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { _, _ in
                withAnimation(AppAnimation.gentleBounce) {
                    scale = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(AppAnimation.gentleBounce) {
                        scale = 1.0
                    }
                }
            }
    }
}

extension View {
    func bounce(trigger: Bool) -> some View {
        modifier(BounceModifier(trigger: trigger))
    }
}
