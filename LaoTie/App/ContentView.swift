import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            // Main content underneath
            Group {
                if appState.isLoading {
                    Color.clear // Splash covers loading phase
                } else if appState.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .animation(.easeInOut, value: appState.isAuthenticated)

            // Splash overlay
            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            DongbeiColors.snowWhite.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(DongbeiColors.dahong)
                Text("唠嗑小馆")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(DongbeiColors.meihei)
                Text("南方小土豆的东北话学习神器")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ProgressView()
                    .tint(DongbeiColors.dahong)
            }
        }
    }
}
