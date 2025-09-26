import Foundation

final class StatsCache {
    static let shared = StatsCache()
    private init() {}

    private let key = "cached_strava_stats_v1"

    func save(_ stats: StravaStats) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(stats) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() -> StravaStats? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(StravaStats.self, from: data)
    }
}


