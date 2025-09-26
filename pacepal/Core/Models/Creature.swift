import Foundation

struct CreatureState: Codable {
    var mood: CreatureMood
    var health: Double
    var growth: Int
    var lastActivityDate: Date?
}

final class CreatureEngine {
    static func evaluateState(from activities: [StravaActivity]) -> CreatureState {
        let sorted = activities.sorted(by: { $0.startDate > $1.startDate })
        let lastDate = sorted.first?.startDate
        let oneWeekDistance = activities.filter { $0.startDate > Date().addingTimeInterval(-7 * 86400) }
            .map { $0.distance }
            .reduce(0, +)

        var mood: CreatureMood = .neutral
        var health: Double = 0.5
        var growth: Int = 0

        if oneWeekDistance > 20000 { // 20km in last week
            mood = .happy
            health = 0.9
            growth = 2
        } else if oneWeekDistance > 5000 {
            mood = .neutral
            health = 0.7
            growth = 1
        } else {
            mood = lastDate == nil || (lastDate! < Date().addingTimeInterval(-3 * 86400)) ? .tired : .sad
            health = 0.4
            growth = 0
        }

        return CreatureState(mood: mood, health: health, growth: growth, lastActivityDate: lastDate)
    }
}


