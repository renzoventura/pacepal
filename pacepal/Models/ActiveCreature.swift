import Foundation

struct Creature: Codable, Identifiable, Equatable {
    let id: String
    var stage: Int // 0 = Egg, 1 = Baby, 2 = Teen, 3 = Adult
    var runPoints: Int
    var kmCurrency: Double
    var happiness: Int // Used for creature mood/display
    var experiencePoints: Int // Used for evolution
    var weekStart: Date
    var weekEnd: Date
    
    // Evolution thresholds based on XP
    // Egg → Baby: 1 XP, Baby → Teen: 3 runs (3 XP), Teen → Adult: 5 runs (5 XP), Adult: 10 runs (10 XP)
    static let evolutionThresholds = [0, 1, 4, 9] // Egg(0), Baby(1), Teen(4), Adult(9)
    static let stageNames = [0: "Egg", 1: "Baby", 2: "Teen", 3: "Adult"]
    
    var stageName: String {
        switch stage {
        case 0: return "Egg"
        case 1: return "Baby"
        case 2: return "Teen"
        case 3: return "Adult"
        default: return "Unknown"
        }
    }
    
    var stageEmoji: String {
        switch stage {
        case 0: return "🥚"
        case 1: return "🐣"
        case 2: return "🐥"
        case 3: return "🐔"
        default: return "❓"
        }
    }
    
    var currentStageXP: Int {
        return experiencePoints - (stage > 0 ? Self.evolutionThresholds[stage] : 0)
    }
    
    var maxStageXP: Int {
        return stage < 3 ? Self.evolutionThresholds[stage + 1] - Self.evolutionThresholds[stage] : 0
    }
    
    var canEvolve: Bool {
        return stage < 3 && experiencePoints >= Self.evolutionThresholds[stage + 1]
    }
}

final class ActiveCreatureStorage {
    static let shared = ActiveCreatureStorage()
    private init() {}

    private let key = "active_creature_v1"

    func load() -> Creature? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Creature.self, from: data)
    }

    func save(_ creature: Creature) {
        if let data = try? JSONEncoder().encode(creature) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func ensureExists() {
        // Only create creature when explicitly needed (e.g., when redeeming runs)
        // Don't auto-create on app launch
        if load() == nil {
            let now = Date()
            let cal = Calendar.current
            let start = cal.startOfDay(for: now)
            let end = cal.date(byAdding: .day, value: 7, to: start) ?? now.addingTimeInterval(7*86400)
            let creature = Creature(id: UUID().uuidString, stage: 0, runPoints: 0, kmCurrency: 0, happiness: 0, experiencePoints: 0, weekStart: start, weekEnd: end)
            save(creature)
        }
    }

    func resetWeekIfNeeded() {
        guard var current = load() else { return }
        if Date() > current.weekEnd {
            FarmStorage.shared.append(current)
            let now = Date()
            let cal = Calendar.current
            let start = cal.startOfDay(for: now)
            let end = cal.date(byAdding: .day, value: 7, to: start) ?? now.addingTimeInterval(7*86400)
            let newCreature = Creature(id: UUID().uuidString, stage: 0, runPoints: 0, kmCurrency: current.kmCurrency, happiness: 0, experiencePoints: 0, weekStart: start, weekEnd: end)
            save(newCreature)
        }
    }

    // Apply effects for a redeemed run: +1 runPoint, +distance km currency, +1 XP
    func applyRedeemedRun(distanceKm: Double) -> Bool {
        ensureExists()
        resetWeekIfNeeded()
        guard var current = load() else { return false }
        
        let oldStage = current.stage
        current.runPoints += 1
        current.kmCurrency += max(0, distanceKm)
        // Earn 1 XP for redeeming a run
        current.experiencePoints += 1
        // Happiness boost on redeem
        current.happiness = min(100, current.happiness + 5)
        
        // Check for evolution
        var didEvolve = false
        while current.canEvolve {
            current.stage += 1
            didEvolve = true
        }
        
        save(current)
        return didEvolve
    }
    
    // Feed the creature and gain happiness
    func feedCreature(happinessGained: Int) -> Bool {
        guard var current = load() else { return false }
        
        // Add happiness
        current.happiness += happinessGained
        
        // Check for evolution based on XP
        var didEvolve = false
        while current.canEvolve {
            current.stage += 1
            didEvolve = true
        }
        
        save(current)
        return didEvolve
    }
    
    // Get evolution info if creature can evolve
    func getEvolutionInfo() -> (oldStage: Int, newStage: Int, stageName: String)? {
        guard var current = load() else { return nil }
        guard current.canEvolve else { return nil }
        
        let oldStage = current.stage
        let newStage = current.stage + 1
        let stageName = Creature.stageNames[newStage] ?? "Unknown"
        
        return (oldStage, newStage, stageName)
    }
}



