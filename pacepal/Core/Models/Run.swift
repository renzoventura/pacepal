import Foundation

struct Run: Codable, Identifiable, Equatable {
    let id: String          // Strava activity ID
    let name: String        // Activity name
    let type: String        // Activity type (Run, Ride, etc.)
    let sportType: String   // Sport type
    let date: Date          // run date
    let distance: Double    // in km
    let movingTime: Int     // in seconds
    let averageSpeed: Double? // m/s
    let calories: Double?   // calories burned
    var redeemed: Bool      // default false
}

final class RunStorage {
    static let shared = RunStorage()
    private init() {}

    private let runsKey = "runs_storage_v1"
    private let lastSyncKey = "runs_last_sync_v1"

    func loadRuns() -> [Run] {
        guard let data = UserDefaults.standard.data(forKey: runsKey) else { return [] }
        return (try? JSONDecoder().decode([Run].self, from: data)) ?? []
    }

    func saveRuns(_ runs: [Run]) {
        if let data = try? JSONEncoder().encode(runs) {
            UserDefaults.standard.set(data, forKey: runsKey)
        }
    }

    func appendRuns(_ newRuns: [Run]) {
        var runs = loadRuns()
        let existing = Set(runs.map { $0.id })
        runs.append(contentsOf: newRuns.filter { !existing.contains($0.id) })
        saveRuns(runs)
    }

    var lastSync: Date? {
        get {
            guard let ts = UserDefaults.standard.object(forKey: lastSyncKey) as? TimeInterval else { return nil }
            return Date(timeIntervalSince1970: ts)
        }
        set {
            if let value = newValue?.timeIntervalSince1970 {
                UserDefaults.standard.set(value, forKey: lastSyncKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastSyncKey)
            }
        }
    }
}


