import Foundation
import SwiftUI

struct Scenic: Codable, Identifiable, Sendable, Hashable {
    // MARK: - Hashable
    static func == (lhs: Scenic, rhs: Scenic) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var id: String
    var name: String
    var province: Province
    var city: String
    var description: String
    var location: String
    var category: ScenicCategory
    var highlight: String
    var imageName: String?
    var imageMatchType: ImageMatchType
    var latitude: Double?
    var longitude: Double?

    var uniqueImageName: String {
        "scenic_\(id)"
    }

    var imageCandidates: [String] {
        var result: [String] = [uniqueImageName]
        if let imageName, imageName != uniqueImageName {
            result.append(imageName)
        }
        return result
    }

    enum ImageMatchType: String, Codable, Sendable {
        case exact = "exact"
        case representative = "representative"
        case pending = "pending"

        var badgeText: String? {
            switch self {
            case .exact:
                return "实拍已核验"
            case .representative:
                return "示意图"
            case .pending:
                return "待核验"
            }
        }
    }

    enum Province: String, Codable, Sendable, CaseIterable {
        case heilongjiang = "黑龙江"
        case jilin = "吉林"
        case liaoning = "辽宁"

        var color: Color {
            switch self {
            case .heilongjiang: Color(red: 0.1, green: 0.25, blue: 0.45)
            case .jilin: Color(red: 0.15, green: 0.40, blue: 0.30)
            case .liaoning: Color(red: 0.55, green: 0.15, blue: 0.15)
            }
        }

        var gradient: [Color] {
            switch self {
            case .heilongjiang: [Color(red: 0.08, green: 0.20, blue: 0.42), Color(red: 0.20, green: 0.45, blue: 0.70)]
            case .jilin: [Color(red: 0.10, green: 0.35, blue: 0.25), Color(red: 0.30, green: 0.60, blue: 0.45)]
            case .liaoning: [Color(red: 0.50, green: 0.12, blue: 0.12), Color(red: 0.75, green: 0.30, blue: 0.20)]
            }
        }
    }

    enum ScenicCategory: String, Codable, Sendable {
        case mountain = "山岳"
        case lake = "湖泊"
        case icesnow = "冰雪"
        case city = "城市"
        case nature = "自然"
        case culture = "人文"
        case coast = "海滨"
        case forest = "森林"
        case wetland = "湿地"
        case volcano = "火山"

        var icon: String {
            switch self {
            case .mountain: "mountain.2.fill"
            case .lake: "drop.fill"
            case .icesnow: "snowflake"
            case .city: "building.2.fill"
            case .nature: "leaf.fill"
            case .culture: "building.columns.fill"
            case .coast: "water.waves"
            case .forest: "tree.fill"
            case .wetland: "bird.fill"
            case .volcano: "flame.fill"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, province, city, description, location, category, highlight, imageName, imageMatchType, latitude, longitude
    }

    init(
        id: String,
        name: String,
        province: Province,
        city: String,
        description: String,
        location: String,
        category: ScenicCategory,
        highlight: String,
        imageName: String? = nil,
        imageMatchType: ImageMatchType = .pending,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.province = province
        self.city = city
        self.description = description
        self.location = location
        self.category = category
        self.highlight = highlight
        self.imageName = imageName
        self.imageMatchType = imageMatchType
        self.latitude = latitude
        self.longitude = longitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        province = try container.decode(Province.self, forKey: .province)
        city = try container.decode(String.self, forKey: .city)
        description = try container.decode(String.self, forKey: .description)
        location = try container.decode(String.self, forKey: .location)
        category = try container.decode(ScenicCategory.self, forKey: .category)
        highlight = try container.decode(String.self, forKey: .highlight)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        imageMatchType = try container.decodeIfPresent(ImageMatchType.self, forKey: .imageMatchType) ?? .pending
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
    }
}
