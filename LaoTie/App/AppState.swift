import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: LaoTieUser?
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let authRepo = AuthRepository()

    init() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            self.autoSignIn()
        }
    }

    // MARK: - Auto Sign In

    private func autoSignIn() {
        if authRepo.isSignedIn,
           let userId = authRepo.currentUserId {
            let nickname = UserDefaults.standard.string(forKey: "laotie_nickname") ?? "东北铁子"
            let streakData = StreakService().loadStreak()

            currentUser = LaoTieUser(
                id: userId,
                nickname: nickname,
                region: UserDefaults.standard.string(forKey: "laotie_region") ?? "",
                totalScore: UserDefaults.standard.integer(forKey: "laotie_score"),
                currentStreak: streakData.currentStreak,
                titles: ["南方小土豆"],
                createdAt: Date(),
                lastActiveAt: Date()
            )

            UserDefaults.standard.set(streakData.currentStreak, forKey: "laotie_streak")
            isAuthenticated = true

            // 启动时同步 XP（ProgressRepository → UserDefaults）
            Task { @MainActor in
                await XPService.shared.syncXPOnLaunch()
                let xp = XPService.shared.getCurrentXPSync()
                self.currentUser?.totalScore = xp
            }
        } else {
            isAuthenticated = false
        }
        isLoading = false
    }

    // MARK: - Login

    func login(nickname: String) {
        errorMessage = nil
        let userId = authRepo.login(nickname: nickname)
        let streakData = StreakService().loadStreak()

        currentUser = LaoTieUser(
            id: userId,
            nickname: nickname,
            region: UserDefaults.standard.string(forKey: "laotie_region") ?? "",
            totalScore: UserDefaults.standard.integer(forKey: "laotie_score"),
            currentStreak: streakData.currentStreak,
            titles: ["南方小土豆"],
            createdAt: Date(),
            lastActiveAt: Date()
        )

        UserDefaults.standard.set(streakData.currentStreak, forKey: "laotie_streak")
        isAuthenticated = true

        // 登录后同步 XP
        Task { @MainActor in
            await XPService.shared.syncXPOnLaunch()
            let xp = XPService.shared.getCurrentXPSync()
            self.currentUser?.totalScore = xp
        }
    }

    // MARK: - Sign Out

    func signOut() {
        authRepo.signOut()
        currentUser = nil
        isAuthenticated = false
    }
}
