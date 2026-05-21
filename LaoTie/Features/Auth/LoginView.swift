import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState

    @State private var nickname = ""
    @State private var isSubmitting = false

    var body: some View {
        ZStack {
            DongbeiColors.pageBackground.ignoresSafeArea()
            FlowerPatternBackground()

            VStack(spacing: Theme.spacingXL) {
                Spacer()

                // Logo
                VStack(spacing: Theme.spacingMD) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(DongbeiColors.dahong)
                        .shadow(color: DongbeiColors.dahong.opacity(0.3), radius: 20)

                    Text("唠嗑小馆")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(DongbeiColors.meihei)

                    Text("南方小土豆的东北话学习神器")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Nickname input
                VStack(spacing: Theme.spacingMD) {
                    TextField("给自己起个东北名儿", text: $nickname)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    DongbeiButton(title: "开整！", icon: "arrow.right.circle.fill") {
                        login()
                    }
                    .opacity(isNicknameValid && !isSubmitting ? 1.0 : 0.6)

                    // Error message
                    if let error = appState.errorMessage {
                        Text(error)
                            .font(.system(.callout, design: .rounded))
                            .foregroundStyle(DongbeiColors.dahong)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, Theme.spacingXL)

                Spacer().frame(height: Theme.spacingLG)
            }
        }
    }

    // MARK: - Helpers

    private var isNicknameValid: Bool {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    private func login() {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            appState.errorMessage = "名字至少得俩字儿吧！"
            return
        }
        guard !isSubmitting else { return }

        appState.errorMessage = nil
        isSubmitting = true
        appState.login(nickname: trimmed)
        isSubmitting = false
    }
}
