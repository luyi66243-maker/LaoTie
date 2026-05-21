import CoreLocation
import os

private let logger = Logger(subsystem: "com.laotie.app", category: "Location")

/// 定位验证结果
enum LocationVerifyResult {
    /// 验证通过，用户在范围内
    case verified
    /// 距离过远
    case tooFar(distanceMeters: Double)
    /// 无法获取用户位置
    case noLocation
    /// 用户拒绝授权定位
    case denied
}

/// 定位服务，用于获取用户位置并验证是否在景点附近
@MainActor
final class LocationService: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var userLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    // MARK: - Private Properties

    private let locationManager: CLLocationManager

    // MARK: - Initialization

    override init() {
        self.locationManager = CLLocationManager()
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        logger.debug("LocationService initialized")
    }

    // MARK: - Public Methods

    /// 请求 whenInUse 定位授权
    func requestAuthorization() {
        logger.info("Requesting location authorization")
        locationManager.requestWhenInUseAuthorization()
    }

    /// 请求一次性定位
    func requestCurrentLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            logger.warning("Cannot request location: not authorized, status=\(self.authorizationStatus.rawValue)")
            return
        }
        logger.info("Requesting current location")
        locationManager.requestLocation()
    }

    /// 验证用户当前位置是否在景点附近
    /// - Parameters:
    ///   - scenicLatitude: 景点纬度
    ///   - scenicLongitude: 景点经度
    ///   - threshold: 距离阈值（米），默认 1000 米
    /// - Returns: 验证结果
    func verifyLocation(
        scenicLatitude: Double,
        scenicLongitude: Double,
        threshold: Double = 1000
    ) -> LocationVerifyResult {
        // 检查授权状态
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            logger.warning("Location verification failed: denied")
            return .denied
        }

        // 检查是否有用户位置
        guard let userLocation else {
            logger.warning("Location verification failed: no location")
            return .noLocation
        }

        // 计算距离
        let scenicLocation = CLLocation(latitude: scenicLatitude, longitude: scenicLongitude)
        let distance = userLocation.distance(from: scenicLocation)

        logger.info("Distance to scenic: \(distance, format: .fixed(precision: 2)) meters, threshold: \(threshold)")

        if distance <= threshold {
            return .verified
        } else {
            return .tooFar(distanceMeters: distance)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.userLocation = location
            logger.info("Location updated: (\(location.coordinate.latitude), \(location.coordinate.longitude))")
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            logger.error("Location error: \(error.localizedDescription)")
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            logger.info("Authorization status changed: \(status.rawValue)")
        }
    }
}
