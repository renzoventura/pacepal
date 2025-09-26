import Foundation

final class FarmStorage {
    static let shared = FarmStorage()
    private init() {}

    private let key = "farm_creatures_v1"

    func load() -> [Creature] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Creature].self, from: data)) ?? []
    }

    func save(_ creatures: [Creature]) {
        if let data = try? JSONEncoder().encode(creatures) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func append(_ creature: Creature) {
        var all = load()
        all.append(creature)
        save(all)
    }
}


