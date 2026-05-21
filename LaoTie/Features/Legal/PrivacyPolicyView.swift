import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    sectionTitle("隐私政策")
                    Text("更新日期：2026年3月18日")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    sectionTitle("一、引言")
                    bodyText("欢迎使用「唠嗑小馆」（以下简称「本应用」）。我们非常重视您的隐私保护。本隐私政策旨在向您说明我们如何收集、使用和保护您的个人信息。请您在使用本应用前仔细阅读本政策。")

                    sectionTitle("二、我们收集的信息")
                    bodyText("""
                    本应用默认仅在您的设备本地存储以下信息：

                    1. 昵称：您在首次使用时输入的昵称，仅用于应用内显示，默认存储在设备本地（UserDefaults）。

                    2. 学习进度：包括词汇学习记录、测验成绩、连续学习天数等，默认存储在设备本地文件中。

                    本应用不要求您提供真实姓名、身份证号、邮箱地址或电话号码等法定身份信息。
                    """)
                }

                Group {
                    sectionTitle("三、设备权限使用")
                    bodyText("""
                    本应用可能请求以下设备权限：

                    1. 麦克风权限：用于「跟读练习」录制语音进行发音评测。

                    2. 语音识别权限：用于跟读练习中的语音识别与评分。

                    3. 相机权限：用于「风景打卡」拍摄照片。

                    4. 相册权限：用于「风景打卡」从系统相册选择照片。

                    5. 定位权限：用于打卡时验证您是否位于景点附近。
                    """)

                    sectionTitle("四、数据存储与安全")
                    bodyText("核心学习数据默认存储在您的设备本地。本应用不包含广告或追踪 SDK。当您主动启用可选联网功能（如 AI 对话、云端语音合成）时，您输入的文本或语音内容可能会发送至您所选择的第三方服务提供商进行处理。")

                    sectionTitle("五、数据共享")
                    bodyText("我们不会将您的数据出售给第三方，不会用于广告投放或跨应用跟踪。仅在您主动使用可选联网功能时，相关请求数据会传输给对应的服务提供商，用于完成该次功能请求。")
                }

                Group {
                    sectionTitle("六、数据删除")
                    bodyText("您可以随时通过以下方式删除您的数据：\n\n1. 在应用内点击「退出登录」清除账户信息\n2. 直接卸载本应用，所有本地数据将被完全删除\n\n由于所有数据均存储在设备本地，卸载应用即可彻底删除所有相关数据。")

                    sectionTitle("七、儿童隐私")
                    bodyText("本应用不会故意收集13岁以下儿童的个人信息。本应用的内容适合所有年龄段用户使用。")

                    sectionTitle("八、隐私政策的变更")
                    bodyText("我们可能会不时更新本隐私政策。更新后的政策将在应用内展示，请您定期查看。继续使用本应用即表示您同意更新后的隐私政策。")

                    sectionTitle("九、联系我们")
                    bodyText("如果您对本隐私政策有任何疑问或建议，请通过以下方式联系我们：\n\n邮箱：laotie.app@outlook.com")
                }
            }
            .padding()
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(DongbeiColors.meihei)
    }

    private func bodyText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineSpacing(4)
    }
}
