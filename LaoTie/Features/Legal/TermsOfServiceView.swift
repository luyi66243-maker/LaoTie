import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    sectionTitle("用户协议")
                    Text("更新日期：2026年3月18日")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    sectionTitle("一、协议的接受")
                    bodyText("欢迎使用「唠嗑小馆」应用（以下简称「本应用」）。下载、安装或使用本应用即表示您已阅读、理解并同意接受本用户协议（以下简称「本协议」）的所有条款。如果您不同意本协议的任何部分，请勿使用本应用。")

                    sectionTitle("二、服务说明")
                    bodyText("本应用是一款东北方言学习工具，提供以下功能：\n\n1. 东北方言词汇学习\n2. 情景对话练习\n3. 语音跟读与发音评分\n4. 趣味答题闯关\n\n本应用提供的内容仅供教育和娱乐目的使用。")

                    sectionTitle("三、用户行为规范")
                    bodyText("在使用本应用时，您应当：\n\n1. 遵守中华人民共和国相关法律法规\n2. 不得利用本应用从事任何违法或不当活动\n3. 不得对本应用进行反编译、反汇编或其他逆向工程操作\n4. 不得复制、修改、传播本应用的任何内容用于商业目的")
                }

                Group {
                    sectionTitle("四、知识产权")
                    bodyText("本应用的所有内容，包括但不限于文字、图片、音频、界面设计、软件代码等，均受中华人民共和国著作权法及国际著作权公约的保护。未经授权，任何人不得以任何形式复制、传播或使用本应用的内容。")

                    sectionTitle("五、免责声明")
                    bodyText("""
                    1. 本应用提供的东北方言学习内容仅供参考，不构成语言学专业建议。方言的使用可能因地区和语境而有所不同。

                    2. 本应用的语音评分功能基于语音识别技术，评分结果仅供参考，不代表专业的语言能力评估。

                    3. 本应用按「现状」提供服务，我们不对应用的适用性、准确性或可靠性作出任何明示或暗示的保证。

                    4. 对于因使用本应用而产生的任何直接或间接损失，我们不承担责任。
                    """)

                    sectionTitle("六、应用更新")
                    bodyText("我们可能会不定期发布应用更新，以改进功能、修复问题或添加新内容。建议您保持应用更新至最新版本以获得最佳体验。")
                }

                Group {
                    sectionTitle("七、协议变更")
                    bodyText("我们保留随时修改本协议的权利。修改后的协议将在应用内展示。继续使用本应用即表示您同意修改后的协议条款。")

                    sectionTitle("八、适用法律与争议解决")
                    bodyText("本协议的订立、执行和解释均适用中华人民共和国法律。因本协议产生的任何争议，双方应首先协商解决；协商不成的，任何一方均可向有管辖权的人民法院提起诉讼。")

                    sectionTitle("九、联系方式")
                    bodyText("如果您对本协议有任何疑问，请通过以下方式联系我们：\n\n邮箱：laotie.app@outlook.com")
                }
            }
            .padding()
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle("用户协议")
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
