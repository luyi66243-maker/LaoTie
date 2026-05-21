import SwiftUI
import MapKit

struct DongbeiMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 44.0, longitude: 127.0),
        span: MKCoordinateSpan(latitudeDelta: 12, longitudeDelta: 12)
    )
    @State private var scenics: [Scenic] = []
    @State private var checkedInIds: Set<String> = []
    @State private var selectedScenic: Scenic?
    @State private var showCheckInPicker = false
    
    private let scenicRepo = ScenicRepository()
    private let checkInRepo = CheckInRepository()
    
    // Only show checked-in scenics with valid coordinates
    private var checkedInScenics: [Scenic] {
        scenics.filter { $0.latitude != nil && $0.longitude != nil && checkedInIds.contains($0.id) }
    }
    
    // Animation state for flag drop-in
    @State private var showFlags = false
    
    // Stats by province
    private var stats: [(province: Scenic.Province, checked: Int, total: Int)] {
        Scenic.Province.allCases.map { province in
            let provinceSenics = scenics.filter { $0.province == province }
            let checkedCount = provinceSenics.filter { checkedInIds.contains($0.id) }.count
            return (province, checkedCount, provinceSenics.count)
        }
    }
    
    private var totalChecked: Int {
        stats.reduce(0) { $0 + $1.checked }
    }
    
    private var totalCount: Int {
        stats.reduce(0) { $0 + $1.total }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map with annotations
            Map(coordinateRegion: $region, annotationItems: checkedInScenics) { scenic in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: scenic.latitude ?? 0,
                    longitude: scenic.longitude ?? 0
                )) {
                    annotationView(for: scenic)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Bottom stats panel
            statsPanel
        }
        .navigationDestination(isPresented: Binding(
                get: { selectedScenic != nil },
                set: { if !$0 { selectedScenic = nil } }
            )) {
                if let scenic = selectedScenic {
                    ScenicDetailView(scenic: scenic)
                }
            }
        .task {
            await loadData()
            // Trigger flag drop-in animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                showFlags = true
            }
        }
        .sheet(isPresented: $showCheckInPicker) {
            CheckInScenicPickerView(
                scenics: scenics,
                checkedInIds: checkedInIds
            )
        }
    }
    
    // MARK: - Annotation View (Red Flag)
    
    @ViewBuilder
    private func annotationView(for scenic: Scenic) -> some View {
        Button {
            selectedScenic = scenic
        } label: {
            VStack(spacing: 0) {
                // Flag icon
                Image(systemName: "flag.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DongbeiColors.dahong)
                    .shadow(color: DongbeiColors.dahong.opacity(0.5), radius: 3, x: 0, y: 1)
                
                // Flag pole
                Rectangle()
                    .fill(Color(red: 0.35, green: 0.25, blue: 0.2))
                    .frame(width: 1.5, height: 8)
                
                // Scenic name
                Text(scenic.name)
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
            .offset(y: showFlags ? 0 : -30)
            .opacity(showFlags ? 1 : 0)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Stats Panel
    
    private var statsPanel: some View {
        VStack(spacing: Theme.spacingSM) {
            // Province stats row
            HStack(spacing: Theme.spacingMD) {
                ForEach(stats, id: \.province) { stat in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(stat.province.color)
                            .frame(width: 10, height: 10)
                        Text("\(stat.province.rawValue) \(stat.checked)/\(stat.total)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(stat.province.color)
                    }
                    
                    if stat.province != .liaoning {
                        Text("|")
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
            }
            
            // Total stats
            Text("总计打卡 \(totalChecked) / \(totalCount) 处景点")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(DongbeiColors.meihei)

            Button {
                showCheckInPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.subheadline.bold())
                    Text("点击打卡")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(DongbeiColors.dahong, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            }
        }
        .padding(.vertical, Theme.spacingMD)
        .padding(.horizontal, Theme.spacingLG)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusLG)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, Theme.spacingMD)
        .padding(.bottom, Theme.spacingSM)
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        do {
            scenics = try await scenicRepo.fetchAll()
            checkedInIds = try await checkInRepo.fetchCheckedInScenicIds()
        } catch {
            print("Failed to load map data: \(error)")
        }
    }
}

private struct CheckInScenicPickerView: View {
    let scenics: [Scenic]
    let checkedInIds: Set<String>
    @Environment(\.dismiss) private var dismiss

    private var groupedScenics: [(province: Scenic.Province, items: [Scenic])] {
        Scenic.Province.allCases.map { province in
            let items = scenics
                .filter { $0.province == province }
                .sorted { $0.name < $1.name }
            return (province, items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedScenics, id: \.province) { section in
                    Section(section.province.rawValue) {
                        ForEach(section.items) { scenic in
                            NavigationLink {
                                ScenicCheckInView(scenic: scenic)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: checkedInIds.contains(scenic.id) ? "checkmark.seal.fill" : "camera.fill")
                                        .foregroundStyle(checkedInIds.contains(scenic.id) ? DongbeiColors.cuilu : DongbeiColors.dahong)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(scenic.name)
                                            .font(.subheadline.bold())
                                        Text(scenic.city)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if checkedInIds.contains(scenic.id) {
                                        Text("已打卡")
                                            .font(.caption2.bold())
                                            .foregroundStyle(DongbeiColors.cuilu)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(DongbeiColors.cuilu.opacity(0.12), in: Capsule())
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择打卡景点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview
struct DongbeiMapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DongbeiMapView()
        }
    }
}
