import SwiftUI

struct CheckInHubView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented picker
                Picker("", selection: $selectedTab) {
                    Text("打卡地图").tag(0)
                    Text("成就墙").tag(1)
                    Text("排行榜").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.spacingMD)
                .padding(.top, Theme.spacingSM)

                // Content
                switch selectedTab {
                case 0:
                    DongbeiMapView()
                case 1:
                    AchievementWallView()
                case 2:
                    CheckInLeaderboardView()
                default:
                    DongbeiMapView()
                }
            }
            .background(DongbeiColors.pageBackground)
            .navigationTitle("风景打卡")
        }
    }
}
