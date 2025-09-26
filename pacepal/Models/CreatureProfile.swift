import Foundation

struct CreatureProfile: Codable {
    enum EggType: String, Codable {
        case ember
        case aqua
        case terra
    }

    var selectedEgg: EggType
    var createdAt: Date
}

final class CreatureStorage {
    static let shared = CreatureStorage()
    private init() {}

    private let key = "creature_profile_v1"

    func hasCreature() -> Bool {
        return UserDefaults.standard.data(forKey: key) != nil
    }

    func save(profile: CreatureProfile) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() -> CreatureProfile? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(CreatureProfile.self, from: data)
    }

    func delete() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}


