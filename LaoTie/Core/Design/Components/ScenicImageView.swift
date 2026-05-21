import SwiftUI
import UIKit

struct ScenicImageView: View {
    let scenicId: String
    let imageName: String?
    let imageMatchType: Scenic.ImageMatchType

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let resolvedImageName {
                Image(resolvedImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.3)
            }

            if let badgeText = imageMatchType.badgeText {
                Text(badgeText)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor, in: Capsule())
                    .padding(8)
            }
        }
    }

    private var badgeColor: Color {
        switch imageMatchType {
        case .exact:
            return .green.opacity(0.9)
        case .representative:
            return .orange.opacity(0.9)
        case .pending:
            return .red.opacity(0.9)
        }
    }

    private var resolvedImageName: String? {
        let uniqueImageName = "scenic_\(scenicId)"
        let candidates = [uniqueImageName, imageName].compactMap { $0 }
        for candidate in candidates {
            if UIImage(named: candidate) != nil {
                return candidate
            }
        }
        return nil
    }
}
