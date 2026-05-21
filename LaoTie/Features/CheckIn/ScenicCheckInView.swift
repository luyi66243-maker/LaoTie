import SwiftUI
import PhotosUI
import CoreLocation
import ImageIO

struct ScenicCheckInView: View {
    let scenic: Scenic
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoImage: Image?
    @State private var isSubmitting = false
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    // GPS 验证相关状态
    @StateObject private var locationService = LocationService()
    @State private var isVerifyingLocation = false
    @State private var verifyResult: LocationVerifyResult?
    @State private var showSuccessMap = false
    @State private var allScenics: [Scenic] = []
    @State private var checkedInIds: Set<String> = []
    @State private var photoEvidence = PhotoEvidence.empty
    @State private var latestAuthenticity: ScenicCheckIn.Authenticity?

    private let repo = CheckInRepository()
    private let scenicRepo = ScenicRepository()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingLG) {
                    // Scenic info header
                    HStack(spacing: Theme.spacingMD) {
                        ScenicImageView(scenicId: scenic.id, imageName: scenic.imageName, imageMatchType: scenic.imageMatchType)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(scenic.name)
                                .font(.headline.bold())
                                .foregroundStyle(DongbeiColors.meihei)
                            Text("\(scenic.province.rawValue) · \(scenic.city)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(DongbeiColors.jinhuang)
                                Text("打卡奖励 +100 XP")
                                    .font(.caption.bold())
                                    .foregroundStyle(DongbeiColors.jinhuang)
                            }
                        }
                        Spacer()
                    }
                    .padding(Theme.spacingMD)
                    .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))

                    // Photo selection
                    VStack(spacing: Theme.spacingMD) {
                        Text("上传你的打卡照片")
                            .font(.headline.bold())
                            .foregroundStyle(DongbeiColors.meihei)

                        if let photoImage {
                            photoImage
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
                        } else {
                            // Placeholder
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusLG)
                                .fill(DongbeiColors.meihei.opacity(0.05))
                                .frame(height: 200)
                                .overlay {
                                    VStack(spacing: Theme.spacingSM) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.secondary)
                                        Text("选择或拍摄一张风景照片")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                        }

                        HStack(spacing: Theme.spacingMD) {
                            // Camera button
                            Button {
                                showCamera = true
                            } label: {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("拍照")
                                }
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(DongbeiColors.dahong.opacity(0.1))
                                .foregroundStyle(DongbeiColors.dahong)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                            }

                            // Photo picker
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                HStack {
                                    Image(systemName: "photo.fill")
                                    Text("相册")
                                }
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(DongbeiColors.cuilu.opacity(0.1))
                                .foregroundStyle(DongbeiColors.cuilu)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                            }
                        }
                    }
                    .padding(Theme.spacingMD)
                    .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))

                    // 验证结果显示
                    if let result = verifyResult {
                        verifyResultCard(result)
                    }

                    if photoData != nil {
                        authenticityPreviewCard
                    }

                    // Submit button / 验证中状态
                    if !showSuccessMap {
                        if isVerifyingLocation {
                            // 定位验证中
                            VStack(spacing: Theme.spacingSM) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("正在验证你的位置...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(Theme.spacingLG)
                        } else if !isVerifyFailed {
                            DongbeiButton(
                                title: isSubmitting ? "提交审核中..." : "提交打卡",
                                icon: isSubmitting ? "hourglass" : "paperplane.fill"
                            ) {
                                guard photoData != nil, !isSubmitting else { return }
                                Task { await submitCheckIn() }
                            }
                            .disabled(photoData == nil || isSubmitting)
                            .opacity(photoData == nil ? 0.5 : 1)
                        }
                    }

                    // Note
                    if !isVerifyFailed && !showSuccessMap {
                        Text("提交后将验证你的位置，到达景点附近即可打卡成功")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(Theme.spacingMD)
            }
            .background(DongbeiColors.pageBackground)
            .navigationTitle("风景打卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .onChange(of: selectedPhoto) { _ in
                Task { await loadPhoto() }
            }
            .onChange(of: cameraImage) { _ in
                if let img = cameraImage {
                    let data = img.jpegData(compressionQuality: 0.8)
                    photoData = data
                    photoImage = Image(uiImage: img)
                    if let data {
                        photoEvidence = analyzePhotoEvidence(from: data)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $cameraImage)
            }
            .fullScreenCover(isPresented: $showSuccessMap) {
                CheckInSuccessMapView(
                    scenic: scenic,
                    checkedInIds: checkedInIds,
                    allScenics: allScenics,
                    authenticity: latestAuthenticity,
                    onDismiss: {
                        showSuccessMap = false
                        dismiss()
                    }
                )
            }
            .onAppear {
                locationService.requestAuthorization()
            }
        }
    }

    // MARK: - Computed Properties

    private var isVerifyFailed: Bool {
        guard let result = verifyResult else { return false }
        switch result {
        case .verified:
            return false
        case .tooFar, .noLocation, .denied:
            return true
        }
    }

    private func loadPhoto() async {
        guard let item = selectedPhoto,
              let data = try? await item.loadTransferable(type: Data.self) else { return }
        photoData = data
        photoEvidence = analyzePhotoEvidence(from: data)
        if let uiImage = UIImage(data: data) {
            photoImage = Image(uiImage: uiImage)
        }
    }

    private func submitCheckIn() async {
        guard photoData != nil else { return }

        // 重置验证结果
        verifyResult = nil
        isVerifyingLocation = true
        HapticManager.impact(.medium)

        // 请求定位
        locationService.requestCurrentLocation()

        // 等待定位结果（约2秒）
        try? await Task.sleep(for: .seconds(2))

        isVerifyingLocation = false

        // 验证位置
        let result: LocationVerifyResult
        if let lat = scenic.latitude, let lon = scenic.longitude {
            result = locationService.verifyLocation(scenicLatitude: lat, scenicLongitude: lon)
        } else {
            // 景点没有坐标，直接通过（兼容旧数据）
            print("[Warning] Scenic missing coordinates: \(scenic.id), auto-verified")
            result = .verified
        }

        verifyResult = result

        switch result {
        case .verified:
            // 验证通过，执行打卡流程
            await performCheckIn()
        case .tooFar, .noLocation, .denied:
            // 验证失败，显示提示
            HapticManager.wrongAnswer()
        }
    }

    private func performCheckIn() async {
        isSubmitting = true

        let fileName = "checkin_\(scenic.id)_\(Int(Date().timeIntervalSince1970)).jpg"
        let authenticity = ScenicCheckIn.Authenticity(
            locationVerified: isLocationVerified,
            distanceMeters: currentDistanceToScenic(),
            hasCaptureTimeMetadata: photoEvidence.hasCaptureTimeMetadata,
            captureTimeWithin72Hours: photoEvidence.captureTimeWithin72Hours,
            hasGPSMetadata: photoEvidence.hasGPSMetadata
        )

        // Save photo
        if let data = photoData {
            _ = try? repo.savePhoto(data: data, fileName: fileName)
        }

        // Create check-in record
        let checkIn = ScenicCheckIn(
            id: UUID().uuidString,
            scenicId: scenic.id,
            scenicName: scenic.name,
            province: scenic.province.rawValue,
            photoFileName: fileName,
            submittedAt: Date(),
            status: .pending,
            reviewedAt: nil,
            rewardXP: 100,
            authenticity: authenticity
        )

        try? await repo.saveCheckIn(checkIn)

        // Simulate review (V1.0 auto-approve)
        _ = try? await repo.simulateReview(for: checkIn)

        // 记录连续学习天数
        let streakData = StreakService().recordLearning()

        // 打卡成功后添加 XP 奖励
        let newXP = await XPService.shared.addXP(
            amount: 100,
            sourceType: .checkIn,
            description: "景点打卡「\(scenic.name)」"
        )
        // 同步到 UserDefaults（UI 层可通过通知刷新）
        UserDefaults.standard.set(newXP, forKey: "laotie_score")

        // 连续打卡梯度 XP 奖励
        let streakBonus = StreakService.streakBonusXP(for: streakData.currentStreak)
        if streakBonus > 0 {
            await XPService.shared.addXP(
                amount: streakBonus,
                sourceType: .streakBonus,
                description: "连续学习第\(streakData.currentStreak)天奖励"
            )
        }

        // Check achievements
        await checkAchievements()

        // 加载数据用于成功动画
        allScenics = (try? await scenicRepo.fetchAll()) ?? []
        let checkIns = (try? await repo.fetchCheckIns()) ?? []
        checkedInIds = Set(checkIns.filter { $0.status == .approved }.map { $0.scenicId })
        latestAuthenticity = authenticity

        isSubmitting = false
        HapticManager.correctAnswer()

        // 显示成功动画
        showSuccessMap = true
    }

    private var authenticityPreviewCard: some View {
        let preview = ScenicCheckIn.Authenticity(
            locationVerified: locationService.userLocation != nil && scenic.latitude != nil && scenic.longitude != nil,
            distanceMeters: currentDistanceToScenic(),
            hasCaptureTimeMetadata: photoEvidence.hasCaptureTimeMetadata,
            captureTimeWithin72Hours: photoEvidence.captureTimeWithin72Hours,
            hasGPSMetadata: photoEvidence.hasGPSMetadata
        )

        return VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack {
                Label("真实性预检", systemImage: "shield.checkerboard")
                    .font(.subheadline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                Spacer()
                Text(preview.level.label)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(authenticityColor(preview.level), in: Capsule())
            }

            Text(preview.summary)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let distance = preview.distanceMeters {
                Text("距景点约 \(Int(distance)) 米")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
    }

    private func currentDistanceToScenic() -> Double? {
        guard let lat = scenic.latitude, let lon = scenic.longitude,
              let userLocation = locationService.userLocation else {
            return nil
        }
        let scenicLocation = CLLocation(latitude: lat, longitude: lon)
        return userLocation.distance(from: scenicLocation)
    }

    private var isLocationVerified: Bool {
        if case .verified = verifyResult {
            return true
        }
        return false
    }

    private func authenticityColor(_ level: ScenicCheckIn.Authenticity.Level) -> Color {
        switch level {
        case .high: return DongbeiColors.cuilu
        case .medium: return DongbeiColors.jinhuang
        case .low: return DongbeiColors.dahong
        }
    }

    private func analyzePhotoEvidence(from data: Data) -> PhotoEvidence {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return .empty
        }

        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any]

        let exifDateString = exif?[kCGImagePropertyExifDateTimeOriginal] as? String
            ?? tiff?[kCGImagePropertyTIFFDateTime] as? String
        let captureDate = parseExifDate(exifDateString)
        let hasCaptureTime = captureDate != nil
        let isRecent = captureDate.map { Date().timeIntervalSince($0) <= 72 * 3600 } ?? false
        let hasGPS = gps != nil

        return PhotoEvidence(
            hasCaptureTimeMetadata: hasCaptureTime,
            captureTimeWithin72Hours: isRecent,
            hasGPSMetadata: hasGPS
        )
    }

    private func parseExifDate(_ text: String?) -> Date? {
        guard let text else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = .current
        return formatter.date(from: text)
    }

    private func checkAchievements() async {
        let checkIns = (try? await repo.fetchCheckIns()) ?? []
        let approvedCount = checkIns.filter { $0.status == .approved }.count
        var achievements = (try? await repo.fetchAchievements()) ?? Achievement.allAchievements

        for i in achievements.indices {
            if achievements[i].unlockedAt == nil && approvedCount >= achievements[i].requirement {
                achievements[i].unlockedAt = Date()
            }
        }
        try? await repo.saveAchievements(achievements)
    }

    @ViewBuilder
    private func verifyResultCard(_ result: LocationVerifyResult) -> some View {
        switch result {
        case .verified:
            // 验证通过不需要显示卡片，直接弹出成功动画
            EmptyView()

        case .tooFar(let distanceMeters):
            let distanceKm = distanceMeters / 1000
            VStack(spacing: Theme.spacingMD) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DongbeiColors.dahong)

                Text("你距离「\(scenic.name)」还有 \(String(format: "%.1f", distanceKm)) 公里")
                    .font(.headline)
                    .foregroundStyle(DongbeiColors.meihei)
                    .multilineTextAlignment(.center)

                Text("请到景点附近再进行打卡")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    verifyResult = nil
                } label: {
                    Text("知道了")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(DongbeiColors.dahong, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                }
            }
            .padding(Theme.spacingLG)
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))

        case .noLocation:
            VStack(spacing: Theme.spacingMD) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DongbeiColors.jinhuang)

                Text("无法获取位置信息")
                    .font(.headline)
                    .foregroundStyle(DongbeiColors.meihei)

                Text("请确保已开启定位服务")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    verifyResult = nil
                    locationService.requestAuthorization()
                } label: {
                    Text("重试")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(DongbeiColors.cuilu, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                }
            }
            .padding(Theme.spacingLG)
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))

        case .denied:
            VStack(spacing: Theme.spacingMD) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DongbeiColors.dahong)

                Text("定位权限未开启")
                    .font(.headline)
                    .foregroundStyle(DongbeiColors.meihei)

                Text("请在设置中允许唠嗑小馆使用定位服务")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("前往设置")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DongbeiColors.cuilu, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                }

                Button {
                    verifyResult = nil
                } label: {
                    Text("取消")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Theme.spacingLG)
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        }
    }
}

private struct PhotoEvidence {
    var hasCaptureTimeMetadata: Bool
    var captureTimeWithin72Hours: Bool
    var hasGPSMetadata: Bool

    static let empty = PhotoEvidence(
        hasCaptureTimeMetadata: false,
        captureTimeWithin72Hours: false,
        hasGPSMetadata: false
    )
}

// MARK: - Camera wrapper

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// ScenicImageView is defined in ScenicImageView.swift
