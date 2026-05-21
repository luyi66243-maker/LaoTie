import SwiftUI

struct DongbeiButton: View {
    let title: String
    var icon: String?
    var style: ButtonStyle = .primary
    let action: () -> Void

    enum ButtonStyle {
        case primary, secondary, outline
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.spacingSM) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body.bold())
                }
                Text(title)
                    .font(.body.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacingMD - 2)
            .padding(.horizontal, Theme.spacingLG)
            .background(backgroundView)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            .overlay(overlayView)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            DongbeiColors.dahong
        case .secondary:
            DongbeiColors.jinhuang
        case .outline:
            Color.clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .secondary:
            .white
        case .outline:
            DongbeiColors.dahong
        }
    }

    @ViewBuilder
    private var overlayView: some View {
        if style == .outline {
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .stroke(DongbeiColors.dahong, lineWidth: 2)
        }
    }
}

struct FlowerPatternBackground: View {
    var opacity: Double = 0.06

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let flowerSize: CGFloat = 40
                let cols = Int(size.width / flowerSize) + 1
                let rows = Int(size.height / flowerSize) + 1

                for row in 0..<rows {
                    for col in 0..<cols {
                        let x = CGFloat(col) * flowerSize + (row.isMultiple(of: 2) ? flowerSize / 2 : 0)
                        let y = CGFloat(row) * flowerSize
                        let center = CGPoint(x: x, y: y)

                        for i in 0..<6 {
                            let angle = Double(i) * .pi / 3
                            let petalX = center.x + cos(angle) * 8
                            let petalY = center.y + sin(angle) * 8
                            let rect = CGRect(x: petalX - 4, y: petalY - 4, width: 8, height: 8)
                            context.fill(Ellipse().path(in: rect), with: .color(DongbeiColors.dahong))
                        }
                    }
                }
            }
            .opacity(opacity)
        }
        .ignoresSafeArea()
    }
}

struct TanghluProgressBar: View {
    let progress: Double
    var totalBalls: Int = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalBalls, id: \.self) { index in
                let filled = Double(index) / Double(totalBalls) < progress
                Circle()
                    .fill(filled ? DongbeiColors.dahong : DongbeiColors.binglan.opacity(0.3))
                    .frame(width: ballSize(for: index), height: ballSize(for: index))
                    .overlay {
                        if filled {
                            Circle()
                                .fill(.white.opacity(0.3))
                                .frame(width: ballSize(for: index) * 0.3, height: ballSize(for: index) * 0.3)
                                .offset(x: -2, y: -2)
                        }
                    }
                if index < totalBalls - 1 {
                    Rectangle()
                        .fill(filled ? DongbeiColors.jinhuang : Color.gray.opacity(0.2))
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func ballSize(for index: Int) -> CGFloat {
        let sizes: [CGFloat] = [20, 22, 24, 22, 20]
        guard index < sizes.count else { return 20 }
        return sizes[index]
    }
}

struct SnowflakeEffect: View {
    @State private var flakes: [Snowflake] = (0..<20).map { _ in Snowflake.random() }
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { context, size in
                    for flake in flakes {
                        let symbol = context.resolve(Text("❄").font(.system(size: flake.size)))
                        context.opacity = flake.opacity
                        context.draw(symbol, at: CGPoint(x: flake.x * size.width, y: flake.y * size.height))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { startAnimation() }
        .onDisappear { stopAnimation() }
    }

    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            Task { @MainActor in
                for i in self.flakes.indices {
                    self.flakes[i].y += self.flakes[i].speed
                    self.flakes[i].x += sin(self.flakes[i].y * 3) * 0.002
                    if self.flakes[i].y > 1.1 {
                        self.flakes[i] = Snowflake.random()
                        self.flakes[i].y = -0.1
                    }
                }
            }
        }
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}

private struct Snowflake {
    var x: Double
    var y: Double
    var size: CGFloat
    var speed: Double
    var opacity: Double

    static func random() -> Snowflake {
        Snowflake(
            x: Double.random(in: 0...1),
            y: Double.random(in: -0.1...1),
            size: CGFloat.random(in: 8...16),
            speed: Double.random(in: 0.001...0.004),
            opacity: Double.random(in: 0.2...0.6)
        )
    }
}

// MARK: - iOS 16 Compatibility for symbolEffect (iOS 17+)

extension View {
    @ViewBuilder
    func symbolEffectCompat(isActive: Bool) -> some View {
        if #available(iOS 17.0, *) {
            self.symbolEffect(.variableColor, isActive: isActive)
        } else {
            self.opacity(isActive ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: isActive)
        }
    }

    @ViewBuilder
    func symbolBounceCompat<V: Equatable>(value: V) -> some View {
        if #available(iOS 17.0, *) {
            self.symbolEffect(.bounce, value: value)
        } else {
            self
        }
    }
}

// MARK: - Card Style Modifier

struct DongbeiCardStyle: ViewModifier {
    var padding: CGFloat = Theme.spacingMD

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
            .shadow(color: Theme.cardShadowColor, radius: Theme.cardShadowRadius, y: Theme.cardShadowY)
    }
}

extension View {
    func dongbeiCard(padding: CGFloat = Theme.spacingMD) -> some View {
        modifier(DongbeiCardStyle(padding: padding))
    }
}
