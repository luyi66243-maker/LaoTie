import Foundation

class AuthRepository {
    
    var isSignedIn: Bool {
        UserDefaults.standard.string(forKey: "laotie_user_id") != nil
    }
    
    var currentUserId: String? {
        UserDefaults.standard.string(forKey: "laotie_user_id")
    }
    
    func login(nickname: String) -> String {
        // 如果已有用户 ID 则复用，否则生成新的
        if let existingId = UserDefaults.standard.string(forKey: "laotie_user_id") {
            UserDefaults.standard.set(nickname, forKey: "laotie_nickname")
            return existingId
        }
        let userId = UUID().uuidString
        UserDefaults.standard.set(userId, forKey: "laotie_user_id")
        UserDefaults.standard.set(nickname, forKey: "laotie_nickname")
        return userId
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "laotie_user_id")
        UserDefaults.standard.removeObject(forKey: "laotie_nickname")
        UserDefaults.standard.removeObject(forKey: "laotie_score")
        UserDefaults.standard.removeObject(forKey: "laotie_streak")
        UserDefaults.standard.removeObject(forKey: "laotie_region")
    }
}
