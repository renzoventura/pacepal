import Foundation

struct Creature: Codable, Identifiable, Equatable {
    let id: String
    var stage: Int // 0 = Egg, 1 = Baby, 2 = Teen, 3 = Adult
    var runPoints: Int
    var kmCurrency: Double
    var happiness: Int // Used for creature mood/display
    var experiencePoints: Int // Used for evolution
    var hunger: Int // Hunger level (0-100, 0 = starving, 100 = full)
    var lastFedDate: Date // When the creature was last fed
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
    
    // Hunger-related properties
    var hungerLevel: String {
        switch hunger {
        case 0..<20: return "Starving"
        case 20..<40: return "Very Hungry"
        case 40..<60: return "Hungry"
        case 60..<80: return "Satisfied"
        case 80..<100: return "Full"
        case 100: return "Completely Full"
        default: return "Unknown"
        }
    }
    
    var hungerEmoji: String {
        switch hunger {
        case 0..<20: return "😵"
        case 20..<40: return "😰"
        case 40..<60: return "😐"
        case 60..<80: return "😊"
        case 80..<100: return "😋"
        case 100: return "🤤"
        default: return "❓"
        }
    }
    
    // Proportional feeding requirements based on stage
    var requiredFoodValue: Int {
        switch stage {
        case 0: return 5  // Egg needs less food
        case 1: return 10 // Baby needs more
        case 2: return 15 // Teen needs even more
        case 3: return 20 // Adult needs the most
        default: return 10
        }
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
            let creature = Creature(id: UUID().uuidString, stage: 0, runPoints: 0, kmCurrency: 0, happiness: 50, experiencePoints: 0, hunger: 80, lastFedDate: now, weekStart: start, weekEnd: end)
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
            let newCreature = Creature(id: UUID().uuidString, stage: 0, runPoints: 0, kmCurrency: current.kmCurrency, happiness: 50, experiencePoints: 0, hunger: 80, lastFedDate: now, weekStart: start, weekEnd: end)
            save(newCreature)
        }
    }

    // Apply effects for a redeemed run: +1 runPoint, +distance km currency, +1 XP
    func applyRedeemedRun(distanceKm: Double) -> Bool {
        ensureExists()
        resetWeekIfNeeded()
        guard var current = load() else { return false }
        
        current.runPoints += 1
        current.kmCurrency += max(0, distanceKm)
        // Earn 1 XP for redeeming a run
        current.experiencePoints += 1
        // Happiness boost on redeem
        current.happiness = min(100, current.happiness + 5)
        
        // Check if evolution should occur (but don't evolve yet)
        let shouldEvolve = current.canEvolve
        
        save(current)
        return shouldEvolve
    }
    
    // Actually perform the evolution
    func performEvolution() -> Bool {
        guard var current = load() else { return false }
        
        var didEvolve = false
        while current.canEvolve {
            current.stage += 1
            didEvolve = true
        }
        
        if didEvolve {
            save(current)
        }
        return didEvolve
    }
    
    // Feed the creature and reduce hunger
    func feedCreature(foodValue: Int) -> Bool {
        guard var current = load() else { return false }
        
        // Calculate hunger reduction based on food value and creature's required food value
        let hungerReduction = min(100, (foodValue * 100) / current.requiredFoodValue)
        current.hunger = min(100, current.hunger + hungerReduction)
        current.lastFedDate = Date()
        
        // Add some happiness based on hunger satisfaction
        let happinessGain = hungerReduction / 10
        current.happiness = min(100, current.happiness + happinessGain)
        
        // Check for evolution based on XP
        var didEvolve = false
        while current.canEvolve {
            current.stage += 1
            didEvolve = true
        }
        
        save(current)
        return didEvolve
    }
    
    // Update hunger based on time passed since last feeding
    func updateHunger() {
        guard var current = load() else { return }
        
        let now = Date()
        let timeSinceLastFed = now.timeIntervalSince(current.lastFedDate)
        
        // Hunger decays based on creature stage (higher stages need more frequent feeding)
        let decayRate: Double
        switch current.stage {
        case 0: decayRate = 0.5  // Egg decays slowly
        case 1: decayRate = 1.0  // Baby decays normally
        case 2: decayRate = 1.5  // Teen decays faster
        case 3: decayRate = 2.0  // Adult decays fastest
        default: decayRate = 1.0
        }
        
        // Calculate hunger loss (1 point per hour * decay rate)
        let hoursSinceLastFed = timeSinceLastFed / 3600
        let hungerLoss = Int(hoursSinceLastFed * decayRate)
        
        if hungerLoss > 0 {
            current.hunger = max(0, current.hunger - hungerLoss)
            current.lastFedDate = now
            save(current)
        }
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



