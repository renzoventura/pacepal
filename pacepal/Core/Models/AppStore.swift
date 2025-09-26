import Foundation
import Combine

enum CreatureMood: String, Codable {
    case happy
    case neutral
    case tired
    case sad
}

struct StravaStats: Codable {
    var totalDistanceMeters: Double
    var totalActivities: Int
    var totalMovingTimeSeconds: Int
    var calories: Double
    var weekDistanceMeters: Double
    var lastSync: Date?
}

final class AppStore: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var stats: StravaStats? = nil
    @Published var creatureMood: CreatureMood = .neutral
    @Published var creatureGrowthStage: Int = 0

    private var cancellables: Set<AnyCancellable> = []

    init() {}
}


