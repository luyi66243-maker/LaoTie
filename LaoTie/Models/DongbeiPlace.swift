import Foundation

struct DongbeiPlace: Codable, Identifiable, Sendable {
    var id: String
    var name: String
    var province: String
    var latitude: Double
    var longitude: Double
    var climate: String
    var culture: String
    var signatureDishes: [String]
    var famousSpots: [String]
    var story: String
}
