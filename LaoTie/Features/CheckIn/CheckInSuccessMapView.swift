import SwiftUI
import MapKit

struct CheckInSuccessMapView: View {
    let scenic: Scenic
    let checkedInIds: Set<String>
    let allScenics: [Scenic]
    let authenticity: ScenicCheckIn.Authenticity?
    var onDismiss: () -> Void
    
    // MARK: - Animation States
    @State private var showOverlay = false
    @State private var showMap = false
    @State private var region: MKCoordinateRegion
    @State private var hasZoomed = false
    @State private var showLightUp = false
    @State private var showPulse = false
    @State private var showInfo = false
    @State private var showHint = false
    
    // Particle animation
    @State private var particles: [Particle] = []
    @State private var animationStartTime: Date = .now
    
    // Pulse wave states
    @State private var pulseScales: [CGFloat] = [0.5, 0.5, 0.5, 0.5]
    @State private var pulseOpacities: [Double] = [0.8, 0.8, 0.8, 0.8]
    
    // XP bounce
    @State private var xpScale: CGFloat = 0.1
    @State private var xpRotation: Double = -15
    
    // MARK: - Constants
    private let dongbeiCenter = CLLocationCoordinate2D(latitude: 44, longitude: 127)
    private let dongbeiSpan = MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    private let zoomedSpan = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    
    init(
        scenic: Scenic,
        checkedInIds: Set<String>,
        allScenics: [Scenic],
        authenticity: ScenicCheckIn.Authenticity? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.scenic = scenic
        self.checkedInIds = checkedInIds
        self.allScenics = allScenics
        self.authenticity = authenticity
        self.onDismiss = onDismiss
        
        // Initial region: Northeast China overview
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 44, longitude: 127),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        ))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Phase 1: Dark overlay
                Color.black.opacity(showOverlay ? 0.75 : 0)
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: Theme.spacingLG) {
                    Spacer()
                    
                    // Map container with effects
                    ZStack {
                        // The map
                        mapView
                            .frame(width: geometry.size.width * 0.85, height: 350)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusXL))
                            .allowsHitTesting(false)
                        
                        // Pulse waves overlay
                        if showPulse {
                            pulseWavesOverlay
                        }
                        
                        // Radial glow
                        if showLightUp {
                            radialGlowOverlay
                        }
                        
                        // Particle effects
                        if showPulse {
                            particleOverlay
                        }
                    }
                    .scaleEffect(showMap ? 1 : 0.3)
                    .opacity(showMap ? 1 : 0)
                    
                    // Phase 5: Info section
                    VStack(spacing: Theme.spacingSM) {
                        // Success title
                        Text("打卡成功!")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(DongbeiColors.jinhuang)
                            .opacity(showInfo ? 1 : 0)
                            .offset(y: showInfo ? 0 : 20)
                        
                        // Scenic name
                        Text(scenic.name)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(showInfo ? 1 : 0)
                            .offset(y: showInfo ? 0 : 30)
                        
                        // XP reward with bounce
                        Text("+100 XP")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(DongbeiColors.jinhuang)
                            .scaleEffect(xpScale)
                            .rotationEffect(.degrees(xpRotation))
                            .shadow(color: DongbeiColors.jinhuang.opacity(0.5), radius: 10)

                        if let authenticity {
                            VStack(spacing: 6) {
                                Text("可信度：\(authenticity.level.label)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(authenticityBadgeColor(authenticity.level), in: Capsule())
                                Text(authenticity.summary)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, Theme.spacingLG)
                            }
                            .opacity(showInfo ? 1 : 0)
                            .offset(y: showInfo ? 0 : 20)
                        }
                    }
                    .padding(.top, Theme.spacingMD)
                    
                    Spacer()
                    
                    // Phase 6: Dismiss hint
                    Text("点击任意处关闭")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .opacity(showHint ? 1 : 0)
                        .padding(.bottom, Theme.spacingXL)
                }
            }
            .onTapGesture {
                onDismiss()
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    private func authenticityBadgeColor(_ level: ScenicCheckIn.Authenticity.Level) -> Color {
        switch level {
        case .high: return DongbeiColors.cuilu
        case .medium: return DongbeiColors.jinhuang
        case .low: return DongbeiColors.dahong
        }
    }
    
    // MARK: - Map View
    private var mapView: some View {
        let checkedInScenics = allScenics.filter { $0.latitude != nil && $0.longitude != nil && (checkedInIds.contains($0.id) || $0.id == scenic.id) }
        return Map(coordinateRegion: $region, annotationItems: checkedInScenics) { spot in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: spot.latitude ?? 0, longitude: spot.longitude ?? 0)) {
                if spot.id == scenic.id {
                    // Current check-in: highlighted red flag
                    VStack(spacing: 0) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(DongbeiColors.dahong)
                            .shadow(color: DongbeiColors.dahong.opacity(0.6), radius: 5, x: 0, y: 1)
                            .scaleEffect(showLightUp ? 1.3 : 0.8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: showLightUp)
                        
                        Rectangle()
                            .fill(Color(red: 0.35, green: 0.25, blue: 0.2))
                            .frame(width: 1.5, height: 10)
                        
                        Text(spot.name)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.55))
                            )
                            .lineLimit(1)
                    }
                } else {
                    // Other checked-in spots: smaller red flag
                    VStack(spacing: 0) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(DongbeiColors.dahong.opacity(0.7))
                        
                        Rectangle()
                            .fill(Color(red: 0.35, green: 0.25, blue: 0.2))
                            .frame(width: 1.5, height: 6)
                    }
                }
            }
        }
    }
    
    // MARK: - Pulse Waves Overlay
    private var pulseWavesOverlay: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .stroke(scenic.province.color.opacity(pulseOpacities[index]), lineWidth: 2)
                    .scaleEffect(pulseScales[index])
                    .frame(width: 40, height: 40)
            }
        }
    }
    
    // MARK: - Radial Glow Overlay
    private var radialGlowOverlay: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        scenic.province.color.opacity(0.6),
                        scenic.province.color.opacity(0.2),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 10,
                    endRadius: 80
                )
            )
            .frame(width: 160, height: 160)
            .blur(radius: 5)
    }
    
    // MARK: - Particle Overlay
    private var particleOverlay: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(animationStartTime)
                let centerX = size.width / 2
                let centerY = size.height / 2
                
                for particle in particles {
                    let progress = min(1, elapsed / particle.lifetime)
                    let x = centerX + particle.direction.dx * particle.speed * CGFloat(elapsed) * 60
                    let y = centerY + particle.direction.dy * particle.speed * CGFloat(elapsed) * 60
                    let opacity = 1.0 - progress
                    let scale = 1.0 - progress * 0.5
                    
                    if opacity > 0 {
                        context.opacity = opacity
                        context.draw(
                            Text(particle.symbol)
                                .font(.system(size: 12 * scale))
                                .foregroundColor(particle.color),
                            at: CGPoint(x: x, y: y)
                        )
                    }
                }
            }
        }
        .frame(width: 300, height: 300)
    }
    
    // MARK: - Animation Sequence
    private func startAnimationSequence() {
        // Generate particles for later use
        generateParticles()
        
        Task {
            // Phase 1: Background fade in (0s - 0.3s)
            withAnimation(.easeIn(duration: 0.3)) {
                showOverlay = true
            }
            try? await Task.sleep(for: .milliseconds(300))
            
            // Phase 2: Map pop in (0.3s - 0.8s)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showMap = true
            }
            try? await Task.sleep(for: .milliseconds(500))
            
            // Phase 3: Zoom to scenic location (0.8s - 1.5s)
            if let lat = scenic.latitude, let lon = scenic.longitude {
                withAnimation(.easeInOut(duration: 0.7)) {
                    region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        span: zoomedSpan
                    )
                    hasZoomed = true
                }
            }
            try? await Task.sleep(for: .milliseconds(700))
            
            // Phase 4: Light up effects (1.5s - 3.5s)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                showLightUp = true
            }
            
            // Start pulse waves
            showPulse = true
            animationStartTime = .now
            startPulseAnimation()
            
            try? await Task.sleep(for: .milliseconds(500))
            
            // Phase 5: Info appear (2.0s - 3.0s)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showInfo = true
            }
            
            // XP bounce animation
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                xpScale = 1.2
                xpRotation = 5
            }
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                xpScale = 1.0
                xpRotation = 0
            }
            
            // Phase 6: Show dismiss hint
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.easeIn(duration: 0.3)) {
                showHint = true
            }
            
            // Auto dismiss after 5 seconds
            try? await Task.sleep(for: .seconds(5))
            onDismiss()
        }
    }
    
    // MARK: - Pulse Animation
    private func startPulseAnimation() {
        // Stagger pulse waves
        for i in 0..<4 {
            let delay = Double(i) * 0.25
            
            Task {
                try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
                
                withAnimation(.easeOut(duration: 1.5)) {
                    pulseScales[i] = 3.0
                    pulseOpacities[i] = 0
                }
            }
        }
    }
    
    // MARK: - Generate Particles
    private func generateParticles() {
        particles = (0..<25).map { _ in
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 0.3...1.2)
            let symbols = ["✦", "★", "✧", "·"]
            let colors = [DongbeiColors.jinhuang, scenic.province.color, Color.white]
            
            return Particle(
                direction: CGVector(dx: cos(angle), dy: sin(angle)),
                speed: speed,
                lifetime: Double.random(in: 1.5...2.5),
                symbol: symbols.randomElement() ?? "✨",
                color: colors.randomElement() ?? .blue
            )
        }
    }
}

// MARK: - Particle Model
private struct Particle: Identifiable {
    let id = UUID()
    let direction: CGVector
    let speed: CGFloat
    let lifetime: Double
    let symbol: String
    let color: Color
}

// MARK: - Preview
struct CheckInSuccessMapView_Previews: PreviewProvider {
    static var previews: some View {
        CheckInSuccessMapView(
            scenic: Scenic(
                id: "changbaishan",
                name: "长白山天池",
                province: .jilin,
                city: "延边",
                description: "长白山天池是中国最大的火山口湖",
                location: "延边朝鲜族自治州安图县",
                category: .mountain,
                highlight: "天池",
                latitude: 42.0089,
                longitude: 128.0656
            ),
            checkedInIds: Set(["changbaishan", "jingpo"]),
            allScenics: [
                Scenic(id: "changbaishan", name: "长白山天池", province: .jilin, city: "延边",
                       description: "", location: "", category: .mountain, highlight: "",
                       latitude: 42.0089, longitude: 128.0656),
                Scenic(id: "jingpo", name: "镜泊湖", province: .heilongjiang, city: "牡丹江",
                       description: "", location: "", category: .lake, highlight: "",
                       latitude: 43.85, longitude: 129.0),
                Scenic(id: "shenyang", name: "沈阳故宫", province: .liaoning, city: "沈阳",
                       description: "", location: "", category: .culture, highlight: "",
                       latitude: 41.7967, longitude: 123.4550)
            ],
            onDismiss: {}
        )
    }
}
