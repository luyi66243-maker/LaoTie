import SwiftUI

struct CityMapPoint: Identifiable {
    let id: String
    let name: String
    let x: CGFloat
    let y: CGFloat
}

struct FloatingSnowflake: View {
    let delay: Double
    let size: CGFloat
    let xPosition: CGFloat
    
    @State private var offset: CGFloat = -50
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "snowflake")
            .font(.system(size: size))
            .foregroundStyle(.white.opacity(0.4))
            .rotationEffect(.degrees(rotation))
            .offset(x: xPosition, y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 8)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    offset = 400
                    rotation = 360
                }
                withAnimation(
                    Animation.easeIn(duration: 2).delay(delay)
                ) {
                    opacity = 0.6
                }
            }
    }
}

struct CityMarkerView: View {
    let city: CityMapPoint
    let isCompleted: Bool
    let isPartial: Bool
    let markerNumber: Int
    let provinceColor: Color
    
    @State private var isPulsing = false
    @State private var isPressed = false
    
    private var markerSize: CGFloat {
        isCompleted ? 56 : isPartial ? 48 : 42
    }
    
    var body: some View {
        ZStack {
            if isCompleted {
                Circle()
                    .stroke(provinceColor.opacity(0.3), lineWidth: 2)
                    .frame(width: markerSize + 20, height: markerSize + 20)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0 : 0.6)
                    .animation(
                        Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false),
                        value: isPulsing
                    )
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [provinceColor.opacity(0.4), provinceColor.opacity(0)]),
                            center: .center,
                            startRadius: 0,
                            endRadius: markerSize / 2
                        )
                    )
                    .frame(width: markerSize + 12, height: markerSize + 12)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0.3 : 0.6)
                    .animation(
                        Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }
            
            if isPartial {
                Circle()
                    .stroke(provinceColor.opacity(0.4), lineWidth: 3)
                    .frame(width: markerSize + 10, height: markerSize + 10)
                    .scaleEffect(isPulsing ? 1.15 : 1.0)
                    .opacity(isPulsing ? 0.2 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                provinceColor.opacity(0.3),
                                provinceColor.opacity(0.1)
                            ]),
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: markerSize / 2
                        )
                    )
                    .frame(width: markerSize, height: markerSize)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                provinceColor,
                                provinceColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isCompleted ? 4 : isPartial ? 3 : 2
                    )
                    .frame(width: markerSize - 4, height: markerSize - 4)
                
                Circle()
                    .fill(provinceColor)
                    .frame(width: isCompleted ? 26 : isPartial ? 22 : 18, height: isCompleted ? 26 : isPartial ? 22 : 18)
                    .shadow(color: provinceColor.opacity(0.6), radius: isCompleted ? 8 : 4)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1)
                } else if isPartial {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(provinceColor)
                            .frame(width: 4, height: 4)
                    }
                } else {
                    Text("\(markerNumber)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(isPressed ? 0.85 : 1.0)
        }
        .onAppear {
            if isCompleted || isPartial {
                isPulsing = true
            }
        }
    }
}

enum ProvinceMapData {

    static let jilinCities: [CityMapPoint] = [
        CityMapPoint(id: "长春", name: "长春", x: 0.42, y: 0.48),
        CityMapPoint(id: "吉林市", name: "吉林市", x: 0.58, y: 0.42),
        CityMapPoint(id: "四平", name: "四平", x: 0.30, y: 0.62),
        CityMapPoint(id: "辽源", name: "辽源", x: 0.42, y: 0.65),
        CityMapPoint(id: "通化", name: "通化", x: 0.52, y: 0.78),
        CityMapPoint(id: "白山", name: "白山", x: 0.65, y: 0.72),
        CityMapPoint(id: "松原", name: "松原", x: 0.25, y: 0.32),
        CityMapPoint(id: "白城", name: "白城", x: 0.12, y: 0.18),
        CityMapPoint(id: "延边", name: "延边", x: 0.80, y: 0.48),
    ]

    static let liaoningCities: [CityMapPoint] = [
        CityMapPoint(id: "沈阳", name: "沈阳", x: 0.48, y: 0.30),
        CityMapPoint(id: "大连", name: "大连", x: 0.45, y: 0.88),
        CityMapPoint(id: "鞍山", name: "鞍山", x: 0.48, y: 0.48),
        CityMapPoint(id: "抚顺", name: "抚顺", x: 0.58, y: 0.26),
        CityMapPoint(id: "本溪", name: "本溪", x: 0.60, y: 0.40),
        CityMapPoint(id: "丹东", name: "丹东", x: 0.78, y: 0.48),
        CityMapPoint(id: "锦州", name: "锦州", x: 0.18, y: 0.42),
        CityMapPoint(id: "营口", name: "营口", x: 0.38, y: 0.58),
        CityMapPoint(id: "盘锦", name: "盘锦", x: 0.28, y: 0.50),
        CityMapPoint(id: "铁岭", name: "铁岭", x: 0.50, y: 0.14),
        CityMapPoint(id: "朝阳", name: "朝阳", x: 0.12, y: 0.20),
        CityMapPoint(id: "葫芦岛", name: "葫芦岛", x: 0.10, y: 0.38),
    ]

    static let heilongjiangCities: [CityMapPoint] = [
        CityMapPoint(id: "哈尔滨", name: "哈尔滨", x: 0.55, y: 0.72),
        CityMapPoint(id: "齐齐哈尔", name: "齐齐哈尔", x: 0.28, y: 0.58),
        CityMapPoint(id: "大庆", name: "大庆", x: 0.38, y: 0.65),
        CityMapPoint(id: "牡丹江", name: "牡丹江", x: 0.72, y: 0.80),
        CityMapPoint(id: "佳木斯", name: "佳木斯", x: 0.72, y: 0.55),
        CityMapPoint(id: "鸡西", name: "鸡西", x: 0.78, y: 0.72),
        CityMapPoint(id: "伊春", name: "伊春", x: 0.58, y: 0.45),
        CityMapPoint(id: "黑河", name: "黑河", x: 0.42, y: 0.22),
        CityMapPoint(id: "绥化", name: "绥化", x: 0.52, y: 0.60),
        CityMapPoint(id: "大兴安岭", name: "大兴安岭", x: 0.22, y: 0.12),
    ]

    static func cities(for province: String) -> [CityMapPoint] {
        switch province {
        case "吉林": jilinCities
        case "辽宁": liaoningCities
        case "黑龙江": heilongjiangCities
        default: []
        }
    }
}

struct JilinShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: 0.05 * w, y: 0.10 * h))
        path.addLine(to: CGPoint(x: 0.20 * w, y: 0.05 * h))
        path.addLine(to: CGPoint(x: 0.40 * w, y: 0.08 * h))
        path.addLine(to: CGPoint(x: 0.55 * w, y: 0.03 * h))
        path.addLine(to: CGPoint(x: 0.70 * w, y: 0.10 * h))
        path.addLine(to: CGPoint(x: 0.85 * w, y: 0.15 * h))
        path.addLine(to: CGPoint(x: 0.95 * w, y: 0.30 * h))
        path.addLine(to: CGPoint(x: 0.92 * w, y: 0.45 * h))
        path.addLine(to: CGPoint(x: 0.88 * w, y: 0.58 * h))
        path.addLine(to: CGPoint(x: 0.80 * w, y: 0.65 * h))
        path.addLine(to: CGPoint(x: 0.72 * w, y: 0.75 * h))
        path.addLine(to: CGPoint(x: 0.60 * w, y: 0.85 * h))
        path.addLine(to: CGPoint(x: 0.48 * w, y: 0.90 * h))
        path.addLine(to: CGPoint(x: 0.38 * w, y: 0.85 * h))
        path.addLine(to: CGPoint(x: 0.28 * w, y: 0.75 * h))
        path.addLine(to: CGPoint(x: 0.22 * w, y: 0.65 * h))
        path.addLine(to: CGPoint(x: 0.15 * w, y: 0.55 * h))
        path.addLine(to: CGPoint(x: 0.08 * w, y: 0.42 * h))
        path.addLine(to: CGPoint(x: 0.03 * w, y: 0.28 * h))
        path.closeSubpath()
        return path
    }
}

struct LiaoningShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: 0.05 * w, y: 0.12 * h))
        path.addLine(to: CGPoint(x: 0.20 * w, y: 0.05 * h))
        path.addLine(to: CGPoint(x: 0.38 * w, y: 0.03 * h))
        path.addLine(to: CGPoint(x: 0.55 * w, y: 0.06 * h))
        path.addLine(to: CGPoint(x: 0.70 * w, y: 0.10 * h))
        path.addLine(to: CGPoint(x: 0.85 * w, y: 0.18 * h))
        path.addLine(to: CGPoint(x: 0.90 * w, y: 0.32 * h))
        path.addLine(to: CGPoint(x: 0.88 * w, y: 0.48 * h))
        path.addLine(to: CGPoint(x: 0.82 * w, y: 0.58 * h))
        path.addLine(to: CGPoint(x: 0.70 * w, y: 0.65 * h))
        path.addLine(to: CGPoint(x: 0.58 * w, y: 0.72 * h))
        path.addLine(to: CGPoint(x: 0.50 * w, y: 0.80 * h))
        path.addLine(to: CGPoint(x: 0.45 * w, y: 0.92 * h))
        path.addLine(to: CGPoint(x: 0.42 * w, y: 0.97 * h))
        path.addLine(to: CGPoint(x: 0.38 * w, y: 0.90 * h))
        path.addLine(to: CGPoint(x: 0.32 * w, y: 0.78 * h))
        path.addLine(to: CGPoint(x: 0.25 * w, y: 0.68 * h))
        path.addLine(to: CGPoint(x: 0.18 * w, y: 0.60 * h))
        path.addLine(to: CGPoint(x: 0.10 * w, y: 0.52 * h))
        path.addLine(to: CGPoint(x: 0.05 * w, y: 0.40 * h))
        path.addLine(to: CGPoint(x: 0.03 * w, y: 0.25 * h))
        path.closeSubpath()
        return path
    }
}

struct HeilongjiangShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: 0.08 * w, y: 0.08 * h))
        path.addLine(to: CGPoint(x: 0.20 * w, y: 0.03 * h))
        path.addLine(to: CGPoint(x: 0.35 * w, y: 0.05 * h))
        path.addLine(to: CGPoint(x: 0.48 * w, y: 0.02 * h))
        path.addLine(to: CGPoint(x: 0.58 * w, y: 0.08 * h))
        path.addLine(to: CGPoint(x: 0.68 * w, y: 0.12 * h))
        path.addLine(to: CGPoint(x: 0.78 * w, y: 0.18 * h))
        path.addLine(to: CGPoint(x: 0.88 * w, y: 0.28 * h))
        path.addLine(to: CGPoint(x: 0.95 * w, y: 0.38 * h))
        path.addLine(to: CGPoint(x: 0.92 * w, y: 0.50 * h))
        path.addLine(to: CGPoint(x: 0.88 * w, y: 0.60 * h))
        path.addLine(to: CGPoint(x: 0.82 * w, y: 0.68 * h))
        path.addLine(to: CGPoint(x: 0.78 * w, y: 0.78 * h))
        path.addLine(to: CGPoint(x: 0.70 * w, y: 0.85 * h))
        path.addLine(to: CGPoint(x: 0.60 * w, y: 0.90 * h))
        path.addLine(to: CGPoint(x: 0.48 * w, y: 0.95 * h))
        path.addLine(to: CGPoint(x: 0.38 * w, y: 0.92 * h))
        path.addLine(to: CGPoint(x: 0.28 * w, y: 0.85 * h))
        path.addLine(to: CGPoint(x: 0.18 * w, y: 0.78 * h))
        path.addLine(to: CGPoint(x: 0.12 * w, y: 0.68 * h))
        path.addLine(to: CGPoint(x: 0.08 * w, y: 0.55 * h))
        path.addLine(to: CGPoint(x: 0.05 * w, y: 0.40 * h))
        path.addLine(to: CGPoint(x: 0.03 * w, y: 0.25 * h))
        path.closeSubpath()
        return path
    }
}

struct ProvinceMapView: View {
    let province: String
    let completedCities: Set<String>
    let partialCities: Set<String>
    let cityMarkerNumbers: [String: Int]
    let onCityTap: (String) -> Void
    
    @State private var snowflakes: [FloatSnowflake] = []
    @State private var mapScale: CGFloat = 0.8
    @State private var mapOpacity: Double = 0
    
    private var cities: [CityMapPoint] {
        ProvinceMapData.cities(for: province)
    }
    
    private var provinceColor: Color {
        switch province {
        case "吉林": DongbeiColors.cuilu
        case "辽宁": DongbeiColors.dahong
        case "黑龙江": DongbeiColors.binglan
        default: .gray
        }
    }
    
    private var provinceGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                provinceColor.opacity(0.15),
                provinceColor.opacity(0.05),
                provinceColor.opacity(0.02)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                provinceColor.opacity(0.03)
                    .ignoresSafeArea()
                
                snowflakeLayer
                    .allowsHitTesting(false)
                
                ZStack {
                    provinceShape
                        .fill(provinceGradient)
                    
                    provinceShape
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    provinceColor.opacity(0.5),
                                    provinceColor.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .shadow(color: provinceColor.opacity(0.3), radius: 8, x: 0, y: 0)
                    
                    routeLines(width: w, height: h)
                    
                    ForEach(Array(cities.enumerated()), id: \.element.id) { index, city in
                        let isCompleted = completedCities.contains(city.name)
                        let isPartial = partialCities.contains(city.name)
                        let pos = CGPoint(x: city.x * w, y: city.y * h)
                        let markerNumber = cityMarkerNumbers[city.name] ?? (index + 1)
                        
                        Button {
                            HapticManager.impact(.light)
                            onCityTap(city.name)
                        } label: {
                            CityMarkerView(
                                city: city,
                                isCompleted: isCompleted,
                                isPartial: isPartial,
                                markerNumber: markerNumber,
                                provinceColor: provinceColor
                            )
                            .frame(width: 80, height: 80)
                        }
                        .buttonStyle(MapButtonStyle())
                        .position(pos)
                    }
                }
                .scaleEffect(mapScale)
                .opacity(mapOpacity)
                
                provinceNameWatermark
                    .allowsHitTesting(false)
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
        .onAppear {
            generateSnowflakes()
            withAnimation(.easeOut(duration: 0.8)) {
                mapScale = 1.0
                mapOpacity = 1.0
            }
        }
    }
    
    private var snowflakeLayer: some View {
        ZStack {
            ForEach(snowflakes) { flake in
                FloatingSnowflake(
                    delay: flake.delay,
                    size: flake.size,
                    xPosition: flake.xPosition
                )
            }
        }
    }
    
    private var provinceNameWatermark: some View {
        VStack(spacing: 4) {
            Text(province)
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(provinceColor.opacity(0.08))
            
            Text("东北")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(provinceColor.opacity(0.05))
        }
    }
    
    private func generateSnowflakes() {
        snowflakes = (0..<12).map { _ in
            FloatSnowflake(
                delay: Double.random(in: 0...4),
                size: CGFloat.random(in: 8...16),
                xPosition: CGFloat.random(in: 0...1)
            )
        }
    }
    
    private func routeLines(width w: CGFloat, height h: CGFloat) -> some View {
        Canvas { context, _ in
            guard cities.count >= 2 else { return }
            
            for i in 0..<(cities.count - 1) {
                let from = cities[i]
                let to = cities[i + 1]
                let start = CGPoint(x: from.x * w, y: from.y * h)
                let end = CGPoint(x: to.x * w, y: to.y * h)
                
                let fromDone = completedCities.contains(from.name)
                let toDone = completedCities.contains(to.name)
                let fromPartial = partialCities.contains(from.name)
                let toPartial = partialCities.contains(to.name)
                
                let segmentColor: Color
                let lineWidth: CGFloat
                if fromDone && toDone {
                    segmentColor = provinceColor
                    lineWidth = 4.5
                } else if fromDone || fromPartial || toDone || toPartial {
                    segmentColor = provinceColor.opacity(0.5)
                    lineWidth = 3.5
                } else {
                    segmentColor = Color.gray.opacity(0.25)
                    lineWidth = 2.5
                }
                
                var path = Path()
                let mid = CGPoint(
                    x: (start.x + end.x) / 2 + (end.y - start.y) * 0.15,
                    y: (start.y + end.y) / 2 - (end.x - start.x) * 0.15
                )
                path.move(to: start)
                path.addQuadCurve(to: end, control: mid)
                
                if fromDone && toDone {
                    context.stroke(
                        path,
                        with: .color(segmentColor),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    context.stroke(
                        path,
                        with: .color(.white.opacity(0.3)),
                        style: StrokeStyle(lineWidth: lineWidth - 2, lineCap: .round)
                    )
                } else {
                    context.stroke(
                        path,
                        with: .color(segmentColor),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: [8, 5])
                    )
                }
                
                drawArrow(context, start: start, end: end, color: segmentColor, isCompleted: fromDone && toDone)
            }
        }
        .frame(width: w, height: h)
        .allowsHitTesting(false)
    }
    
    private func drawArrow(_ context: GraphicsContext, start: CGPoint, end: CGPoint, color: Color, isCompleted: Bool) {
        let mid = CGPoint(
            x: (start.x + end.x) / 2,
            y: (start.y + end.y) / 2
        )
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowSize: CGFloat = isCompleted ? 6 : 4
        
        var arrowPath = Path()
        let tip = CGPoint(x: mid.x + cos(angle) * arrowSize * 1.5, y: mid.y + sin(angle) * arrowSize * 1.5)
        let left = CGPoint(x: mid.x + cos(angle + .pi * 0.8) * arrowSize, y: mid.y + sin(angle + .pi * 0.8) * arrowSize)
        let right = CGPoint(x: mid.x + cos(angle - .pi * 0.8) * arrowSize, y: mid.y + sin(angle - .pi * 0.8) * arrowSize)
        
        arrowPath.move(to: tip)
        arrowPath.addLine(to: left)
        arrowPath.addLine(to: right)
        arrowPath.closeSubpath()
        
        context.fill(arrowPath, with: .color(color))
        if isCompleted {
            context.fill(arrowPath, with: .color(.white.opacity(0.4)))
        }
    }
    
    private var provinceShape: AnyShape {
        switch province {
        case "吉林": AnyShape(JilinShape())
        case "辽宁": AnyShape(LiaoningShape())
        default: AnyShape(HeilongjiangShape())
        }
    }
}

struct FloatSnowflake: Identifiable {
    let id = UUID()
    let delay: Double
    let size: CGFloat
    let xPosition: CGFloat
}

struct MapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
