import SwiftUI

struct PlaceDetailView: View {
    let place: DongbeiPlace
    @Environment(\.dismiss) private var dismiss

    private var provinceColor: Color {
        switch place.province {
        case "吉林": DongbeiColors.cuilu
        case "辽宁": DongbeiColors.jinhuang
        default: DongbeiColors.dahong
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingLG) {
                    // Header
                    headerSection

                    // Location
                    locationSection

                    // Climate
                    infoSection(title: "气候特征", icon: "cloud.sun.fill", color: .orange, content: place.climate)

                    // Culture
                    infoSection(title: "风土人情", icon: "person.3.fill", color: provinceColor, content: place.culture)

                    // Signature dishes
                    tagSection(title: "招牌菜", icon: "fork.knife", color: DongbeiColors.dahong, items: place.signatureDishes)

                    // Famous spots
                    tagSection(title: "著名景点", icon: "mappin.and.ellipse", color: DongbeiColors.cuilu, items: place.famousSpots)

                    // Story
                    storySection
                }
                .padding(Theme.spacingMD)
            }
            .background(DongbeiColors.pageBackground)
            .navigationTitle(place.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack(spacing: Theme.spacingMD) {
            // Province badge
            VStack(spacing: 4) {
                Text(String(place.province.prefix(1)))
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                Text(place.province)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(width: 64, height: 64)
            .background(provinceColor, in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.title.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                Text(place.province)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var locationSection: some View {
        HStack(spacing: Theme.spacingSM) {
            Image(systemName: "location.fill")
                .font(.caption)
                .foregroundStyle(provinceColor)
            Text("北纬 \(String(format: "%.2f", place.latitude))° 东经 \(String(format: "%.2f", place.longitude))°")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(provinceColor.opacity(0.08), in: Capsule())
    }

    private func infoSection(title: String, icon: String, color: Color, content: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(color)

            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding(Theme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }

    private func tagSection(title: String, icon: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(color)

            FlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.1), in: Capsule())
                }
            }
        }
        .padding(Theme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }

    private var storySection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Label("故事背景", systemImage: "book.fill")
                .font(.subheadline.bold())
                .foregroundStyle(DongbeiColors.jinhuang)

            Text(place.story)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding(Theme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                        .stroke(DongbeiColors.jinhuang.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
