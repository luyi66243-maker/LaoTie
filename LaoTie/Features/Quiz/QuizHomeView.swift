import SwiftUI

struct QuizHomeView: View {
    @State private var levels: [QuizLevel] = []
    @State private var completedLevels: Set<String> = []
    @State private var selectedProvince = "吉林"
    @State private var selectedCity: String?
    @State private var showCityLevels = false
    private let repository = QuizRepository()
    private let progressRepo = ProgressRepository()

    private let provinces = ["吉林", "辽宁", "黑龙江"]

    // MARK: - Computed

    private var provinceLevels: [QuizLevel] {
        levels.filter { $0.province == selectedProvince }
    }

    private var completedCities: Set<String> {
        var result = Set<String>()
        let cityLevels = Dictionary(grouping: provinceLevels, by: \.city)
        for (city, cityLvls) in cityLevels {
            if cityLvls.allSatisfy({ completedLevels.contains($0.id) }) {
                result.insert(city)
            }
        }
        return result
    }

    private var partialCities: Set<String> {
        var result = Set<String>()
        let cityLevels = Dictionary(grouping: provinceLevels, by: \.city)
        for (city, cityLvls) in cityLevels {
            let hasAny = cityLvls.contains { completedLevels.contains($0.id) }
            let allDone = cityLvls.allSatisfy { completedLevels.contains($0.id) }
            if hasAny && !allDone {
                result.insert(city)
            }
        }
        return result
    }

    private var cityLevelsForSelected: [QuizLevel] {
        guard let city = selectedCity else { return [] }
        return provinceLevels.filter { $0.city == city }.sorted { $0.levelNumber < $1.levelNumber }
    }

    private var cityMarkerNumbers: [String: Int] {
        let grouped = Dictionary(grouping: provinceLevels, by: \.city)
        let sortedCities = grouped.sorted { lhs, rhs in
            let lhsMin = lhs.value.map(\.levelNumber).min() ?? .max
            let rhsMin = rhs.value.map(\.levelNumber).min() ?? .max
            return lhsMin < rhsMin
        }
        var result: [String: Int] = [:]
        for (idx, cityEntry) in sortedCities.enumerated() {
            result[cityEntry.key] = idx + 1
        }
        return result
    }

    private var provinceProgress: (completed: Int, total: Int) {
        let total = provinceLevels.count
        let done = provinceLevels.filter { completedLevels.contains($0.id) }.count
        return (done, total)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingMD) {
                    // Province tabs
                    provinceTabsView

                    // Province map
                    provinceMapSection

                    // Province progress
                    progressBar

                    // City levels list (shown when city selected)
                    if showCityLevels, let city = selectedCity {
                        cityLevelsSection(city: city)
                    }
                }
                .padding(Theme.spacingMD)
            }
            .background(DongbeiColors.pageBackground)
            .navigationTitle("闯关地图")
            .task { await loadData() }
        }
    }

    // MARK: - Province Tabs

    private var provinceTabsView: some View {
        HStack(spacing: 0) {
            ForEach(provinces, id: \.self) { prov in
                let isSelected = prov == selectedProvince
                let provLevels = levels.filter { $0.province == prov }
                let doneCount = provLevels.filter { completedLevels.contains($0.id) }.count
                let allDone = doneCount == provLevels.count && provLevels.count > 0

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedProvince = prov
                        selectedCity = nil
                        showCityLevels = false
                    }
                } label: {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            if allDone {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                            }
                            Text(prov)
                                .font(.subheadline.bold())
                        }
                        Text("\(doneCount)/\(provLevels.count)")
                            .font(.system(size: 9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(isSelected ? .white : provinceColor(prov))
                    .background(
                        isSelected ? provinceColor(prov) : provinceColor(prov).opacity(0.08),
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                    )
                }
            }
        }
    }

    // MARK: - Map Section

    private var provinceMapSection: some View {
        VStack(spacing: Theme.spacingSM) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundStyle(provinceColor(selectedProvince))
                Text("\(selectedProvince)省闯关地图")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                Spacer()
                if let city = selectedCity {
                    Text(city)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(provinceColor(selectedProvince), in: Capsule())
                }
            }

            ProvinceMapView(
                province: selectedProvince,
                completedCities: completedCities,
                partialCities: partialCities,
                cityMarkerNumbers: cityMarkerNumbers
            ) { city in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if selectedCity == city {
                        showCityLevels.toggle()
                    } else {
                        selectedCity = city
                        showCityLevels = true
                    }
                }
                HapticManager.impact(.light)
            }
            .frame(height: 260)
            .padding(Theme.spacingSM)
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

            // Legend
            HStack(spacing: Theme.spacingMD) {
                legendItem(color: provinceColor(selectedProvince), label: "已通关")
                legendItem(color: provinceColor(selectedProvince).opacity(0.5), label: "进行中")
                legendItem(color: .gray.opacity(0.3), label: "未解锁")
            }
            .font(.system(size: 10))
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let prog = provinceProgress
        return HStack(spacing: Theme.spacingSM) {
            Image(systemName: "flag.fill")
                .foregroundStyle(provinceColor(selectedProvince))
            ProgressView(value: Double(prog.completed), total: max(Double(prog.total), 1))
                .tint(provinceColor(selectedProvince))
            Text("\(prog.completed)/\(prog.total) 关")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(Theme.spacingSM)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }

    // MARK: - City Levels

    private func cityLevelsSection(city: String) -> some View {
        let cityLvls = cityLevelsForSelected
        let allCityLevels = provinceLevels.sorted { $0.levelNumber < $1.levelNumber }
        let cityOrder = cityMarkerNumbers[city] ?? 1

        return VStack(alignment: .leading, spacing: Theme.spacingMD) {
            HStack {
                Text("\(city) - \(cityOrder) 关")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                Text("共 \(cityLvls.count) 关")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    withAnimation { showCityLevels = false; selectedCity = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(Array(cityLvls.enumerated()), id: \.element.id) { index, level in
                let isCompleted = completedLevels.contains(level.id)
                let isUnlocked = isLevelUnlocked(level, allLevels: allCityLevels)

                NavigationLink(
                    destination: QuizPlayView(level: level) { passedId in
                        completedLevels.insert(passedId)
                    }
                ) {
                    LevelNodeView(
                        level: level,
                        displayNumber: index + 1,
                        isUnlocked: isUnlocked,
                        isCompleted: isCompleted
                    )
                }
                .disabled(!isUnlocked)
            }

            if cityLvls.isEmpty {
                Text("该城市暂未配置关卡，先试试其他城市")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Helpers

    private func isLevelUnlocked(_ level: QuizLevel, allLevels: [QuizLevel]) -> Bool {
        // 获取该城市的所有关卡并按 levelNumber 排序
        let cityLevels = provinceLevels.filter { $0.city == level.city }.sorted { $0.levelNumber < $1.levelNumber }
        
        // 如果是该城市的第一个关卡，则解锁
        if let firstLevel = cityLevels.first, firstLevel.id == level.id {
            return true
        }
        
        // 否则需要完成该城市的前一个关卡
        if let index = cityLevels.firstIndex(where: { $0.id == level.id }), index > 0 {
            let prevLevel = cityLevels[index - 1]
            return completedLevels.contains(prevLevel.id)
        }
        
        return false
    }

    private func provinceColor(_ prov: String) -> Color {
        switch prov {
        case "吉林": DongbeiColors.cuilu
        case "辽宁": DongbeiColors.dahong
        case "黑龙江": DongbeiColors.binglan
        default: .gray
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(.secondary)
        }
    }

    private func loadData() async {
        do {
            levels = try await repository.fetchAllLevels()
            let progress = try await progressRepo.fetchProgress()
            completedLevels = Set(progress.quizResults.keys)
        } catch {
            // Keep empty
        }
    }
}

// MARK: - Level Node View

struct LevelNodeView: View {
    let level: QuizLevel
    let displayNumber: Int
    let isUnlocked: Bool
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            ZStack {
                Circle()
                    .fill(badgeColor)
                    .frame(width: 48, height: 48)
                    .shadow(color: badgeColor.opacity(0.3), radius: 6, y: 3)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                } else if isUnlocked {
                    Text("\(displayNumber)")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(level.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isUnlocked ? DongbeiColors.meihei : .secondary)

                Text(level.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: Theme.spacingSM) {
                    Label("\(level.questions.count)题", systemImage: "questionmark.circle")
                    Label("+\(level.rewardXP)XP", systemImage: "star.fill")
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }

            Spacer()

            if isUnlocked && !isCompleted {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(provinceColor)
            }
        }
        .padding(Theme.spacingSM)
        .background(
            .white.opacity(isUnlocked ? 1 : 0.5),
            in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
        )
    }

    private var badgeColor: Color {
        if isCompleted { return DongbeiColors.cuilu }
        if isUnlocked { return provinceColor }
        return .gray.opacity(0.3)
    }

    private var provinceColor: Color {
        switch level.province {
        case "吉林": DongbeiColors.cuilu
        case "辽宁": DongbeiColors.dahong
        case "黑龙江": DongbeiColors.binglan
        default: DongbeiColors.dahong
        }
    }
}
