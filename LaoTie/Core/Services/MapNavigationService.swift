import Foundation
import UIKit
import os

private let logger = Logger(subsystem: "com.laotie.app", category: "MapNavigation")

@MainActor
enum MapNavigationService {

    enum MapApp: String, CaseIterable, Identifiable {
        case amap = "高德地图"
        case apple = "苹果地图"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .amap: "map.fill"
            case .apple: "apple.logo"
            }
        }
    }

    /// Returns the list of available map apps on this device
    static var availableApps: [MapApp] {
        var apps: [MapApp] = []
        if let url = URL(string: "iosamap://"), UIApplication.shared.canOpenURL(url) {
            apps.append(.amap)
        }
        apps.append(.apple) // Apple Maps is always available
        return apps
    }

    /// Open navigation to the specified destination
    nonisolated static func navigate(
        to name: String,
        latitude: Double,
        longitude: Double,
        using app: MapApp
    ) {
        Task { @MainActor in
            switch app {
            case .amap:
                openAmap(name: name, latitude: latitude, longitude: longitude)
            case .apple:
                openAppleMaps(name: name, latitude: latitude, longitude: longitude)
            }
        }
    }

    // MARK: - Private

    private static func openAmap(name: String, latitude: Double, longitude: Double) {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let urlString = "iosamap://path?sourceApplication=LaoTie&dname=\(encodedName)&dlat=\(latitude)&dlon=\(longitude)&dev=0&t=0"

        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            logger.info("Opening Amap navigation to \(name)")
        } else {
            // Fallback to Amap web
            let webURL = "https://uri.amap.com/navigation?to=\(longitude),\(latitude),\(encodedName)&mode=car&src=LaoTie"
            if let url = URL(string: webURL) {
                UIApplication.shared.open(url)
                logger.info("Opening Amap web navigation to \(name)")
            }
        }
    }

    private static func openAppleMaps(name: String, latitude: Double, longitude: Double) {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let urlString = "http://maps.apple.com/?daddr=\(latitude),\(longitude)&q=\(encodedName)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
            logger.info("Opening Apple Maps navigation to \(name)")
        }
    }
}
