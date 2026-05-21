import SwiftUI

// MARK: - Splash Screen View

struct SplashView: View {
    let onFinished: () -> Void

    // Animation states
    @State private var showBackground = false
    @State private var showSnow = false
    @State private var showDongbei = false
    @State private var showComma = false
    @State private var showZheng = false
    @State private var showMingbai = false
    @State private var showBang = false
    @State private var showSeal = false
    @State private var showSubtitle = false
    @State private var showSlogan = false
    @State private var dismissAll = false

    // Snow particles
    @State private var snowflakes: [SplashSnowflake] = (0..<20).map { _ in SplashSnowflake() }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: 0xC41E24),
                    Color(hex: 0xD62828),
                    Color(hex: 0xE63946),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(showBackground ? 1 : 0)

            // Festive pattern background (subtle)
            festivePattern
                .opacity(showBackground ? 0.08 : 0)

            // Snowflakes
            if showSnow {
                ForEach(snowflakes) { flake in
                    SplashSnowflakeView(flake: flake)
                }
            }

            // Main content
            VStack(spacing: 0) {
                Spacer()

                // "东北话" - big bouncy entrance
                HStack(spacing: 0) {
                    AnimatedChar("东", delay: 0, show: showDongbei)
                    AnimatedChar("北", delay: 0.08, show: showDongbei)
                    AnimatedChar("话", delay: 0.16, show: showDongbei)
                }
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(.white)

                // "，整明白！" - slam in
                HStack(spacing: 0) {
                    Text("，")
                        .opacity(showComma ? 1 : 0)

                    Text("整")
                        .scaleEffect(showZheng ? 1 : 2.5)
                        .opacity(showZheng ? 1 : 0)

                    Text("明")
                        .scaleEffect(showMingbai ? 1 : 0.3)
                        .opacity(showMingbai ? 1 : 0)

                    Text("白")
                        .scaleEffect(showMingbai ? 1 : 0.3)
                        .opacity(showMingbai ? 1 : 0)

                    Text("！")
                        .scaleEffect(showBang ? 1.3 : 0)
                        .opacity(showBang ? 1 : 0)
                        .rotationEffect(.degrees(showBang ? -8 : 0))
                }
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(DongbeiColors.jinhuang)

                // Decorative seal stamp
                if showSeal {
                    sealStamp
                        .transition(.scale.combined(with: .opacity))
                        .padding(.top, 20)
                }

                // Subtitle
                Text("南方小土豆的东北话学习神器")
                    .font(Theme.labelFont)
                    .foregroundStyle(.white.opacity(0.7))
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 10)
                    .padding(.top, 16)

                // Slogan
                Text("一句东北话，走遍全天下")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(DongbeiColors.jinhuang.opacity(0.9))
                    .opacity(showSlogan ? 1 : 0)
                    .offset(y: showSlogan ? 0 : 8)
                    .padding(.top, 8)

                Spacer()

                // Fun decorative elements at bottom
                HStack(spacing: 30) {
                    funEmoji("🥟", delay: 0.0, show: showSeal)
                    funEmoji("🧧", delay: 0.1, show: showSeal)
                    funEmoji("🎉", delay: 0.2, show: showSeal)
                    funEmoji("🧣", delay: 0.3, show: showSeal)
                    funEmoji("❄️", delay: 0.4, show: showSeal)
                }
                .padding(.bottom, 60)
            }
        }
        .opacity(dismissAll ? 0 : 1)
        .scaleEffect(dismissAll ? 1.1 : 1)
        .onAppear {
            runAnimation()
        }
    }

    // MARK: - Animation Sequence

    private func runAnimation() {
        Task { @MainActor in
            // Phase 1: Background (0s)
            withAnimation(.easeIn(duration: 0.3)) {
                showBackground = true
            }

            // Phase 2: Snow starts (0.2s)
            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.easeIn(duration: 0.5)) {
                showSnow = true
            }

            // Phase 3: "东北话" bounces in (0.4s)
            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showDongbei = true
            }

            // Phase 4: Comma (0.9s)
            try? await Task.sleep(nanoseconds: 500_000_000)
            withAnimation(.easeOut(duration: 0.15)) {
                showComma = true
            }

            // Phase 5: "整" slams in (1.0s)
            try? await Task.sleep(nanoseconds: 100_000_000)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                showZheng = true
            }

            // Phase 6: "明白" pops in (1.25s)
            try? await Task.sleep(nanoseconds: 250_000_000)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                showMingbai = true
            }

            // Phase 7: "！" with dramatic effect (1.5s)
            try? await Task.sleep(nanoseconds: 250_000_000)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                showBang = true
            }

            // Phase 8: Seal stamp (1.8s)
            try? await Task.sleep(nanoseconds: 300_000_000)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showSeal = true
            }

            // Phase 9: Subtitle (2.0s)
            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.easeOut(duration: 0.4)) {
                showSubtitle = true
            }

            // Phase 9.5: Slogan (2.3s)
            try? await Task.sleep(nanoseconds: 300_000_000)
            withAnimation(.easeOut(duration: 0.5)) {
                showSlogan = true
            }

            // Phase 10: Dismiss and callback (3.3s)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation(.easeInOut(duration: 0.4)) {
                dismissAll = true
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            onFinished()
        }
    }

    // MARK: - Sub Views

    private var festivePattern: some View {
        Canvas { context, size in
            // Draw simple festive diamond/rhombus pattern
            let spacing: CGFloat = 40
            for row in stride(from: 0, to: size.height, by: spacing) {
                for col in stride(from: 0, to: size.width, by: spacing) {
                    let offset: CGFloat = Int(row / spacing) % 2 == 0 ? 0 : spacing / 2
                    let center = CGPoint(x: col + offset, y: row)
                    var diamond = Path()
                    diamond.move(to: CGPoint(x: center.x, y: center.y - 6))
                    diamond.addLine(to: CGPoint(x: center.x + 6, y: center.y))
                    diamond.addLine(to: CGPoint(x: center.x, y: center.y + 6))
                    diamond.addLine(to: CGPoint(x: center.x - 6, y: center.y))
                    diamond.closeSubpath()
                    context.fill(diamond, with: .color(.white))
                }
            }
        }
        .ignoresSafeArea()
    }

    private var sealStamp: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(.white.opacity(0.6), lineWidth: 3)
                .frame(width: 70, height: 70)

            // Inner text
            VStack(spacing: 0) {
                Text("老铁")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                Text("认证")
                    .font(Theme.labelFont.bold())
            }
            .foregroundStyle(.white.opacity(0.8))
        }
        .rotationEffect(.degrees(-15))
    }

    private func funEmoji(_ emoji: String, delay: Double, show: Bool) -> some View {
        Text(emoji)
            .font(.system(size: 28))
            .scaleEffect(show ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(delay), value: show)
    }
}

// MARK: - Animated Character

struct AnimatedChar: View {
    let character: String
    let delay: Double
    let show: Bool

    init(_ char: String, delay: Double, show: Bool) {
        self.character = char
        self.delay = delay
        self.show = show
    }

    @State private var appeared = false

    var body: some View {
        Text(character)
            .scaleEffect(appeared ? 1 : 0)
            .rotationEffect(.degrees(appeared ? 0 : -30))
            .opacity(appeared ? 1 : 0)
            .onChange(of: show) { _ in
                if show {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.55).delay(delay)) {
                        appeared = true
                    }
                }
            }
    }
}

// MARK: - Snowflake Model & View

struct SplashSnowflake: Identifiable {
    let id = UUID()
    let x: CGFloat = CGFloat.random(in: 0...1)
    let size: CGFloat = CGFloat.random(in: 4...10)
    let speed: Double = Double.random(in: 3...7)
    let delay: Double = Double.random(in: 0...2)
    let drift: CGFloat = CGFloat.random(in: -30...30)
    let opacity: Double = Double.random(in: 0.3...0.8)
}

struct SplashSnowflakeView: View {
    let flake: SplashSnowflake
    @State private var falling = false

    var body: some View {
        GeometryReader { geo in
            Text("❄")
                .font(.system(size: flake.size))
                .opacity(flake.opacity)
                .position(
                    x: flake.x * geo.size.width + (falling ? flake.drift : 0),
                    y: falling ? geo.size.height + 20 : -20
                )
                .onAppear {
                    withAnimation(
                        .linear(duration: flake.speed)
                        .delay(flake.delay)
                        .repeatForever(autoreverses: false)
                    ) {
                        falling = true
                    }
                }
        }
        .allowsHitTesting(false)
    }
}
