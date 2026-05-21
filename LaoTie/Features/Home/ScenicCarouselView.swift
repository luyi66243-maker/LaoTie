import SwiftUI

struct ScenicCarouselView: View {
    let scenics: [Scenic]
    @State private var currentPage = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack {
                Text("东北三省风光")
                    .font(Theme.headlineFont)
                    .foregroundStyle(DongbeiColors.meihei)
                Spacer()
                Text("\(currentPage + 1)/\(scenics.count)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            TabView(selection: $currentPage) {
                ForEach(Array(scenics.enumerated()), id: \.element.id) { index, scenic in
                    NavigationLink {
                        ScenicDetailView(scenic: scenic)
                    } label: {
                        ScenicCardView(scenic: scenic)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))

            // Province dots
            HStack(spacing: 6) {
                ForEach(Scenic.Province.allCases, id: \.rawValue) { province in
                    let isCurrent = scenics.indices.contains(currentPage) && scenics[currentPage].province == province
                    HStack(spacing: 3) {
                        Circle()
                            .fill(province.color)
                            .frame(width: isCurrent ? 8 : 6, height: isCurrent ? 8 : 6)
                        if isCurrent {
                            Text(province.rawValue)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(province.color)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: isCurrent)
                }
                Spacer()
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentPage = (currentPage + 1) % max(scenics.count, 1)
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Carousel Card

struct ScenicCardView: View {
    let scenic: Scenic

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Photo background
            ScenicImageView(scenicId: scenic.id, imageName: scenic.imageName, imageMatchType: scenic.imageMatchType)

            // Dark gradient overlay for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content overlay
            VStack(alignment: .leading, spacing: 6) {
                Spacer()

                HStack(spacing: 4) {
                    Text(scenic.province.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.white.opacity(0.25))
                        .clipShape(Capsule())

                    Text(scenic.category.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.white.opacity(0.25))
                        .clipShape(Capsule())
                }
                .foregroundStyle(.white)

                Text(scenic.name)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(scenic.highlight)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                    Text("\(scenic.city) · \(scenic.location)")
                        .font(.system(size: 10))
                }
                .foregroundStyle(.white.opacity(0.7))
            }
            .padding(Theme.spacingMD)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
    }
}

// MARK: - Detail View

struct ScenicDetailView: View {
    let scenic: Scenic
    @State private var isFlipped = false
    @State private var showCheckIn = false
    @State private var showNavSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingLG) {
                // Flippable card
                ZStack {
                    frontView
                        .opacity(isFlipped ? 0 : 1)
                    backView
                        .opacity(isFlipped ? 1 : 0)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusXL))
                .onTapGesture {
                    withAnimation(.spring(duration: 0.5)) {
                        isFlipped.toggle()
                    }
                }

                Text(isFlipped ? "点击卡片看风景" : "点击卡片看介绍")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Check-in button
                DongbeiButton(title: "风景打卡", icon: "camera.fill") {
                    showCheckIn = true
                }

                // Navigation button
                if scenic.latitude != nil && scenic.longitude != nil {
                    Button {
                        showNavSheet = true
                    } label: {
                        HStack(spacing: Theme.spacingSM) {
                            Image(systemName: "location.fill")
                                .font(.body)
                            Text("导航到此")
                                .font(.body.bold())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(DongbeiColors.cuilu, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                    }
                }

                // Info section
                VStack(alignment: .leading, spacing: Theme.spacingMD) {
                    HStack(spacing: Theme.spacingMD) {
                        infoChip(icon: "mappin.circle.fill", text: scenic.city)
                        infoChip(icon: scenic.category.icon, text: scenic.category.rawValue)
                        infoChip(icon: "map", text: scenic.province.rawValue)
                    }

                    Divider()

                    Text("景点介绍")
                        .font(.headline.bold())
                        .foregroundStyle(DongbeiColors.meihei)

                    Text(scenic.description)
                        .font(.body)
                        .foregroundStyle(DongbeiColors.meihei.opacity(0.8))
                        .lineSpacing(6)

                    Divider()

                    VStack(alignment: .leading, spacing: Theme.spacingSM) {
                        Label("地理位置", systemImage: "location.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(DongbeiColors.meihei)
                        Text("\(scenic.province.rawValue) · \(scenic.city) · \(scenic.location)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: Theme.spacingSM) {
                        Label("特色亮点", systemImage: "sparkles")
                            .font(.subheadline.bold())
                            .foregroundStyle(DongbeiColors.meihei)
                        Text(scenic.highlight)
                            .font(.subheadline)
                            .foregroundStyle(DongbeiColors.jinhuang)
                    }
                }
                .padding(Theme.spacingMD)
            }
            .padding(.horizontal, Theme.spacingMD)
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle(scenic.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCheckIn) {
            ScenicCheckInView(scenic: scenic)
        }
        .sheet(isPresented: $showNavSheet) {
            NavigationMapSheet(scenic: scenic)
                .presentationDetents([.medium])
        }
    }

    private var frontView: some View {
        ZStack(alignment: .bottomLeading) {
            // Photo
            GeometryReader { geo in
                ScenicImageView(scenicId: scenic.id, imageName: scenic.imageName, imageMatchType: scenic.imageMatchType)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Spacer()

                HStack(spacing: 6) {
                    Text(scenic.province.rawValue)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.25))
                        .clipShape(Capsule())

                    Text(scenic.category.rawValue)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.25))
                        .clipShape(Capsule())
                }
                .foregroundStyle(.white)

                Text(scenic.name)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(scenic.highlight)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                    Text("\(scenic.city) · \(scenic.location)")
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            }
            .padding(Theme.spacingMD)
        }
    }

    private var backView: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack {
                Image(systemName: scenic.category.icon)
                    .font(.title3)
                    .foregroundStyle(scenic.province.color)
                Text(scenic.name)
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                    .lineLimit(1)
                Spacer()
            }

            Divider()

            Text(scenic.description)
                .font(.subheadline)
                .foregroundStyle(DongbeiColors.meihei.opacity(0.85))
                .lineSpacing(4)
                .lineLimit(8)

            Spacer(minLength: 0)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("位置")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text("\(scenic.province.rawValue) \(scenic.city)")
                        .font(.caption.bold())
                        .foregroundStyle(scenic.province.color)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("类型")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text(scenic.category.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(scenic.province.color)
                }
            }
        }
        .padding(Theme.spacingMD)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusXL))
    }

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2.bold())
        }
        .foregroundStyle(DongbeiColors.meihei)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(DongbeiColors.meihei.opacity(0.06))
        .clipShape(Capsule())
    }
}

// MARK: - Navigation Map Sheet

struct NavigationMapSheet: View {
    let scenic: Scenic
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.spacingLG) {
                // Scenic info header
                VStack(spacing: Theme.spacingSM) {
                    Image(systemName: scenic.category.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(scenic.province.color)

                    Text(scenic.name)
                        .font(.title3.bold())
                        .foregroundStyle(DongbeiColors.meihei)

                    Text("\(scenic.province.rawValue) · \(scenic.city) · \(scenic.location)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let lat = scenic.latitude, let lon = scenic.longitude {
                        Text("坐标: \(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, Theme.spacingMD)

                // Map app options
                VStack(spacing: Theme.spacingSM) {
                    Text("选择导航方式")
                        .font(.subheadline.bold())
                        .foregroundStyle(DongbeiColors.meihei)

                    ForEach(MapNavigationService.availableApps) { app in
                        Button {
                            if let lat = scenic.latitude, let lon = scenic.longitude {
                                MapNavigationService.navigate(
                                    to: scenic.name,
                                    latitude: lat,
                                    longitude: lon,
                                    using: app
                                )
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: Theme.spacingMD) {
                                Image(systemName: app.icon)
                                    .font(.title3)
                                    .foregroundStyle(app == .amap ? DongbeiColors.binglan : .primary)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.rawValue)
                                        .font(.body.bold())
                                        .foregroundStyle(DongbeiColors.meihei)
                                    Text(app == .amap ? "打开高德地图进行导航" : "使用系统自带地图导航")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(Theme.spacingMD)
                            .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingMD)

                Spacer()
            }
            .background(DongbeiColors.pageBackground)
            .navigationTitle("导航到此")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(DongbeiColors.dahong)
                }
            }
        }
    }
}
