import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)

            VocabularyListView()
                .tabItem {
                    Label("学词儿", systemImage: "character.book.closed.fill")
                }
                .tag(1)

            ScenarioListView()
                .tabItem {
                    Label("唠嗑", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(2)

            QuizHomeView()
                .tabItem {
                    Label("闯关", systemImage: "gamecontroller.fill")
                }
                .tag(3)

            NavigationStack {
                ChatView()
            }
                .tabItem {
                    Label("搭子", systemImage: "person.2.fill")
                }
                .tag(4)

            ToolsHubView()
                .tabItem {
                    Label("工具", systemImage: "wrench.fill")
                }
                .tag(5)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle.fill")
                }
                .tag(6)
        }
        .tint(DongbeiColors.dahong)
        .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { notification in
            if let tab = notification.userInfo?["tab"] as? Int {
                selectedTab = tab
            }
        }
    }
}
