import SwiftUI

struct HomeView: View {
    @StateObject private var store = AppStore()
    @State private var creatureState = CreatureState(mood: .neutral, health: 0.5, growth: 0, lastActivityDate: nil)
    @State private var isLoading = false
    @State private var showLoadingView = false
    @State private var showStatsView = false
    @State private var showCoupons = false
    @State private var showStore = false
    @State private var showEggSelection = false
    @State private var navigateToLogin = false
    @State private var showMenu = false
    @State private var errorMessage: String? = nil
    @State private var opacity: Double = 0.0
    @State private var inventory: [InventoryItem] = []
    @State private var creature: Creature? = nil
    @State private var bounceOffset: CGFloat = 0
    @State private var showEvolutionPopup = false
    @State private var evolutionInfo: (oldStage: Int, newStage: Int, stageName: String)? = nil
    @State private var pendingEvolution = false
    @State private var tempExperiencePoints: Int? = nil
    @State private var showEvolutionNotification = false
    @State private var hungerUpdateTimer: Timer? = nil

    private var experienceBarWidth: CGFloat {
        guard let creature = creature else { return 0 }
        
        // Use temporary experience points if there's a pending evolution
        let currentXP = tempExperiencePoints ?? creature.experiencePoints
        let currentStageXP = currentXP - (creature.stage > 0 ? Creature.evolutionThresholds[creature.stage] : 0)
        let maxStageXP = creature.stage < 3 ? Creature.evolutionThresholds[creature.stage + 1] - Creature.evolutionThresholds[creature.stage] : 1
        
        let progress = maxStageXP > 0 ? CGFloat(currentStageXP) / CGFloat(maxStageXP) : 0
        // Return progress as a percentage (0.0 to 1.0) for use with maxWidth
        return max(0, min(1, progress))
    }
    
    private var currentStageXPDisplay: Int {
        guard let creature = creature else { return 0 }
        let currentXP = tempExperiencePoints ?? creature.experiencePoints
        return currentXP - (creature.stage > 0 ? Creature.evolutionThresholds[creature.stage] : 0)
    }
    
    private var maxStageXPDisplay: Int {
        guard let creature = creature else { return 1 }
        return creature.stage < 3 ? Creature.evolutionThresholds[creature.stage + 1] - Creature.evolutionThresholds[creature.stage] : 1
    }
    
    private var hungerBarWidth: CGFloat {
        guard let creature = creature else { return 0 }
        let progress = CGFloat(creature.hunger) / 100.0
        return min(200, max(0, progress * 200))
    }
    
    private var hungerBarColor: Color {
        guard let creature = creature else { return .red }
        switch creature.hunger {
        case 0..<20: return .red
        case 20..<40: return .orange
        case 40..<60: return .yellow
        case 60..<80: return .green
        case 80..<100: return .blue
        case 100: return .purple
        default: return .red
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("Keep running to grow your creature!")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: { showMenu = true }) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.pacePalOrange)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
    
    private var creatureDisplayView: some View {
        VStack(spacing: 20) {
            // Creature Display
            VStack(spacing: 8) {
                Text(creature?.stageEmoji ?? "🥚")
                    .font(.system(size: 80))
                    .offset(y: bounceOffset)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: bounceOffset)
                    .onAppear {
                        bounceOffset = -8
                        // Ensure creature is loaded when view appears
                        if creature == nil {
                            loadCreature()
                        }
                        // Update hunger when view appears
                        ActiveCreatureStorage.shared.updateHunger()
                        loadCreature()
                    }
                
                Text(creature?.stageName ?? "Egg")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            
            // Experience Bar (or XP display for fully evolved creatures)
            VStack(spacing: 8) {
                Text("Experience")
                    .font(.headline)
                    .foregroundColor(.black)
                
                if let creature = creature, creature.stage >= 3 {
                    // Fully evolved creature - show total XP as a number
                    VStack(spacing: 4) {
                        Text("\(creature.experiencePoints)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.pacePalOrange)
                        
                        Text("Total Experience")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.7))
                        
                        Text("Fully Evolved Master")
                            .font(.caption)
                            .foregroundColor(.pacePalOrange)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 16)
                } else {
                    // Not fully evolved - show progress bar
                    VStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.pacePalOrange.opacity(0.3))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(Color.pacePalOrange)
                                    .frame(width: geometry.size.width * experienceBarWidth, height: 8)
                                    .cornerRadius(4)
                                    .animation(.easeInOut(duration: 0.5), value: experienceBarWidth)
                            }
                        }
                        .frame(height: 8)
                        .frame(maxWidth: .infinity)
                        
                        HStack {
                            Text("\(currentStageXPDisplay)/\(maxStageXPDisplay) XP")
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.7))
                            
                            Spacer()
                            
                            Text(creature?.stageName ?? "Egg")
                                .font(.caption)
                                .foregroundColor(.pacePalOrange)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
            .background(Color.pacePalOrange.opacity(0.1))
            .cornerRadius(12)
            
            // Hunger Bar (only show for non-egg creatures)
            if let creature = creature, creature.stage > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("Hunger")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Text(creature.hungerEmoji)
                            .font(.title2)
                    }
                    
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.red.opacity(0.3))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(hungerBarColor)
                            .frame(width: hungerBarWidth, height: 8)
                            .cornerRadius(4)
                            .animation(.easeInOut(duration: 0.5), value: hungerBarWidth)
                    }
                    .frame(width: 200)
                    
                    HStack {
                        Text("\(creature.hunger)/100")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.7))
                        
                        Spacer()
                        
                        Text(creature.hungerLevel)
                            .font(.caption)
                            .foregroundColor(hungerBarColor)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Creature Stats
            creatureStatsView
            
            // Inventory Display (always show)
            inventoryView
        }
    }
    
    private var creatureStatsView: some View {
        VStack(spacing: 12) {
            Text("Creature Stats")
                .font(.headline)
                .foregroundColor(.black)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Run Points")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.7))
                    Text("\(creature?.runPoints ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.pacePalOrange)
                }
                
                VStack(spacing: 4) {
                    Text("KM Currency")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.7))
                    Text(String(format: "%.1f", creature?.kmCurrency ?? 0.0))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.pacePalOrange)
                }
                
                VStack(spacing: 4) {
                    Text("Happiness")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.7))
                    Text("\(creature?.happiness ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.pacePalOrange)
                }
                
                VStack(spacing: 4) {
                    Text("Experience")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.7))
                    Text("\(creature?.experiencePoints ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                // Only show hunger stat for non-egg creatures
                if let creature = creature, creature.stage > 0 {
                    VStack(spacing: 4) {
                        Text("Hunger")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.7))
                        Text("\(creature.hunger)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(hungerBarColor)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.pacePalOrange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var inventoryView: some View {
        VStack(spacing: 12) {
            Text("Inventory")
                .font(.headline)
                .foregroundColor(.black)
            
            if inventory.isEmpty {
                VStack(spacing: 8) {
                    Text("📦")
                        .font(.system(size: 40))
                        .opacity(0.5)
                    
                    Text("No items available")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.6))
                    
                    Text("Visit the store to buy food for your creature!")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(inventory) { item in
                            InventoryItemView(item: item) {
                                feedCreature(item.foodItem)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.pacePalOrange.opacity(0.1))
        .cornerRadius(12)
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("PacePal")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.pacePalOrange)
                        
                        Spacer()
                        
                        Button(action: { showMenu.toggle() }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(.pacePalOrange)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Creature Display
                    creatureDisplayView

                    if let errorMessage { 
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    // Action Buttons
                    VStack(spacing: 16) {
                        // Main Action Buttons
                        HStack(spacing: 12) {
                        Button(action: {
                            SoundService.shared.playButtonTap()
                            openCoupons()
                        }) {
                            Text("Redeem Runs").font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .tint(.pacePalOrange)

                        Button(action: {
                            SoundService.shared.playButtonTap()
                            openStore()
                        }) {
                            Text("Store").font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .tint(.pacePalOrange)

                        Button(action: {
                            SoundService.shared.playButtonTap()
                            showStats()
                        }) {
                            Text("View Details").font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .tint(.pacePalOrange)
                        }
                        
                        // Divider for Debug Section
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        // Debug Buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                SoundService.shared.playButtonTap()
                                showEvolutionNotification = true
                            }) {
                                Text("Test Evolution").font(.subheadline)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            
                            Button(action: {
                                SoundService.shared.playButtonTap()
                                if var current = ActiveCreatureStorage.shared.load() {
                                    // Give enough XP for the next evolution stage
                                    let nextStageThreshold = current.stage < 3 ? Creature.evolutionThresholds[current.stage + 1] : 19
                                    current.experiencePoints = nextStageThreshold
                                    ActiveCreatureStorage.shared.save(current)
                                    loadCreature()
                                    print("DEBUG: Forced creature XP to \(nextStageThreshold) for stage \(current.stage)")
                                }
                            }) {
                                Text("Force XP").font(.subheadline)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        }
                    }

                    if isLoading { 
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .pacePalOrange))
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }
            .refreshable {
                await refreshStatsAsync()
            }
            .opacity(opacity)
            .onAppear {
                bootstrap()
                loadInventory()
                loadCreature()
                
                // Start hunger update timer (every 5 minutes)
                hungerUpdateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
                    ActiveCreatureStorage.shared.updateHunger()
                    loadCreature()
                }
            }
            .onDisappear {
                // Stop the timer when view disappears
                hungerUpdateTimer?.invalidate()
                hungerUpdateTimer = nil
            }
        }
        .fullScreenCover(isPresented: $showLoadingView) {
            LoadingView {
                showLoadingView = false
                withAnimation(.easeIn(duration: 1.0)) {
                    opacity = 1.0
                }
            }
        }
        .sheet(isPresented: $showStatsView) {
            StatsView(stats: store.stats)
        }
        .sheet(isPresented: $showCoupons) {
            CouponView(onSuccessDismiss: { [self] in
                // First refresh creature data to show updated XP
                refreshAfterCouponRedemption()
                
                // Add a small delay to ensure data is refreshed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Check if evolution should occur
                    if let currentCreature = ActiveCreatureStorage.shared.load() {
                        let shouldEvolve = currentCreature.canEvolve
                        
                        if shouldEvolve {
                            // Set temporary XP to show progression before evolution
                            tempExperiencePoints = currentCreature.experiencePoints
                            pendingEvolution = true
                            
                            // Show evolution notification immediately when user returns to home screen
                            showEvolutionNotification = true
                        }
                    }
                }
            })
            .onDisappear {
                // Only refresh if no evolution is pending (success popup wasn't shown)
                if !pendingEvolution {
                    refreshAfterCouponRedemption()
                }
            }
        }
            .sheet(isPresented: $showStore) {
                StoreView()
                    .onDisappear {
                        loadInventory()
                        creature = ActiveCreatureStorage.shared.load()
                    }
            }
            .fullScreenCover(isPresented: $showEvolutionPopup) {
                if let evolutionInfo = evolutionInfo {
                    EvolutionPopupView(
                        oldStage: evolutionInfo.oldStage,
                        newStage: evolutionInfo.newStage,
                        stageName: evolutionInfo.stageName,
                        onDismiss: {
                            showEvolutionPopup = false
                            self.evolutionInfo = nil
                            // Clear temporary state and refresh creature data
                            tempExperiencePoints = nil
                            pendingEvolution = false
                            loadCreature()
                        }
                    )
                }
            }
        .fullScreenCover(isPresented: $showEggSelection) {
            EggSelectionView {
                showEggSelection = false
                // Continue with normal bootstrap after egg selection
                continueBootstrap()
                // Ensure creature is loaded after egg selection
                loadCreature()
            }
        }
        .fullScreenCover(isPresented: $navigateToLogin) {
            LoginView()
        }
        .overlay(
            // Evolution Notification Popup
            Group {
                if showEvolutionNotification {
                    EvolutionNotificationView {
                        showEvolutionNotification = false
                        // Play evolution sound
                        SoundService.shared.playEvolution()
                        SoundService.shared.playNotificationFeedback(.success)
                        
                        // Perform the actual evolution
                        let didEvolve = ActiveCreatureStorage.shared.performEvolution()
                        if didEvolve {
                            // Clear temporary state and refresh creature data
                            tempExperiencePoints = nil
                            pendingEvolution = false
                            loadCreature()
                            
                            // Show the detailed evolution popup after evolution is performed
                            if let evolutionData = ActiveCreatureStorage.shared.getEvolutionInfo() {
                                evolutionInfo = evolutionData
                                showEvolutionPopup = true
                            }
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showEvolutionNotification)
                }
            }
        )
        .overlay(
            // Hamburger Menu
            Group {
                if showMenu {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showMenu = false
                        }
                    
                    VStack(alignment: .trailing, spacing: 0) {
                        Spacer()
                        
                        VStack(spacing: 0) {
                            Button(action: {
                                showMenu = false
                                showStats()
                            }) {
                                HStack {
                                    Image(systemName: "chart.bar")
                                    Text("View Details")
                                    Spacer()
                                }
                                .foregroundColor(.pacePalOrange)
                                .padding()
                                .background(Color.white)
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showMenu = false
                                logout()
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Logout")
                                    Spacer()
                                }
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white)
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showMenu = false
                                clearAllData()
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear All Data (Debug)")
                                    Spacer()
                                }
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showMenu)
                }
            }
        )
    }
    
    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
                .font(.subheadline)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    private func bootstrap() {
        store.isAuthenticated = true
        
        // Check if user has an active creature, if not show egg selection
        if ActiveCreatureStorage.shared.load() == nil {
            showEggSelection = true
            return
        }
        
        continueBootstrap()
    }
    
    private func continueBootstrap() {
        if let cached = StatsCache.shared.load() { 
            store.stats = cached 
        }
        
        // Load creature data
        creature = ActiveCreatureStorage.shared.load()
        
        showLoadingView = true
        fetchAndUpdate()
    }

    private func refreshStats() {
        showLoadingView = true
        fetchAndUpdate()
    }
    
    private func refreshStatsAsync() async {
        await withCheckedContinuation { continuation in
            fetchAndUpdate()
            // Simulate a small delay to show the refresh indicator
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
    
    private func openCoupons() {
        isLoading = true
        SyncService.shared.syncRuns { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    showCoupons = true
                case .failure(let error):
                    errorMessage = "Failed to sync runs: \(error.localizedDescription)"
                }
            }
        }
    }

    private func openStore() {
        showStore = true
    }
    
    private func showStats() {
        showStatsView = true
    }
    
    private func loadInventory() {
        inventory = InventoryStorage.shared.loadInventory()
    }
    
    private func loadCreature() {
        creature = ActiveCreatureStorage.shared.load()
    }
    
    private func refreshAfterCouponRedemption() {
        // Refresh inventory in case any items were purchased
        loadInventory()
        
        // Refresh creature stats to show updated run points and KM currency
        creature = ActiveCreatureStorage.shared.load()
    }
    
    private func feedCreature(_ foodItem: FoodItem) {
        guard let creature = ActiveCreatureStorage.shared.load() else { return }
        
        // Eggs can't be fed - they don't have hunger
        if creature.stage == 0 {
            SoundService.shared.playError()
            SoundService.shared.playHapticFeedback(.light)
            errorMessage = "Eggs don't need feeding! Wait for your creature to hatch first."
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                errorMessage = nil
            }
            return
        }
        
        // Play feeding sound
        SoundService.shared.playFeedCreature()
        SoundService.shared.playHapticFeedback(.medium)
        
        // Update hunger before feeding
        ActiveCreatureStorage.shared.updateHunger()
        
        // Feed creature and check for evolution
        let didEvolve = ActiveCreatureStorage.shared.feedCreature(foodValue: foodItem.foodValue)
        
        // Update local creature state
        self.creature = ActiveCreatureStorage.shared.load()
        
        // Remove item from inventory
        InventoryStorage.shared.removeItem(foodItem)
        
        // Reload inventory
        loadInventory()
        
        if didEvolve {
            // Play evolution sound
            SoundService.shared.playEvolution()
            SoundService.shared.playNotificationFeedback(.success)
            
            // Show evolution popup
            if let evolutionData = ActiveCreatureStorage.shared.getEvolutionInfo() {
                evolutionInfo = evolutionData
                showEvolutionPopup = true
            }
        } else {
            // Show regular feedback with hunger info
            let hungerReduction = min(100, (foodItem.foodValue * 100) / creature.requiredFoodValue)
            errorMessage = "Fed \(foodItem.emoji) \(foodItem.name)! +\(hungerReduction) Hunger Relief"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                errorMessage = nil
            }
        }
    }
    
    private func logout() {
        StravaAuthService.shared.logout()
        store.isAuthenticated = false
        store.stats = nil
        creatureState = CreatureState(mood: .neutral, health: 0.5, growth: 0, lastActivityDate: nil)
        
        withAnimation(.easeOut(duration: 0.8)) {
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            navigateToLogin = true
        }
    }
    
    private func clearAllData() {
        StravaAuthService.shared.clearAllData()
        store.isAuthenticated = false
        store.stats = nil
        creatureState = CreatureState(mood: .neutral, health: 0.5, growth: 0, lastActivityDate: nil)
        
        withAnimation(.easeOut(duration: 0.8)) {
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            navigateToLogin = true
        }
    }

    private func fetchAndUpdate() {
        isLoading = true
        errorMessage = nil
        
        StravaAuthService.shared.getAccessToken { tokenResult in
            switch tokenResult {
            case .failure(let error):
                DispatchQueue.main.async {
                    isLoading = false
                    showLoadingView = false
                    errorMessage = error.localizedDescription
                }
            case .success(let token):
                StravaAPIClient.shared.fetchRecentActivities(accessToken: token) { activitiesResult in
                    DispatchQueue.main.async {
                        isLoading = false
                        switch activitiesResult {
                        case .failure(let error):
                            showLoadingView = false
                            errorMessage = error.localizedDescription
                        case .success(let activities):
                            let weekDistance = activities.filter { $0.startDate > Date().addingTimeInterval(-7 * 86400) }.map { $0.distance }.reduce(0, +)
                            let totalDistance = activities.map { $0.distance }.reduce(0, +)
                            let totalTime = activities.map { $0.movingTime }.reduce(0, +)
                            let calories = totalDistance * 0.06 // rough placeholder kcal/m
                            let newStats = StravaStats(totalDistanceMeters: totalDistance, totalActivities: activities.count, totalMovingTimeSeconds: totalTime, calories: calories, weekDistanceMeters: weekDistance, lastSync: Date())
                            store.stats = newStats
                            StatsCache.shared.save(newStats)
                            creatureState = CreatureEngine.evaluateState(from: activities)
                            // LoadingView will automatically dismiss after its sequence completes
                        }
                    }
                }
            }
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000.0
        return String(format: "%.1f km", km)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    private func formatLocalTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
//        formatter.dateStyle = DateFormatter.Style.abbreviated
        formatter.timeStyle = DateFormatter.Style.short
        return formatter.string(from: date)
    }
}

struct InventoryItemView: View {
    let item: InventoryItem
    let onFeed: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text(item.foodItem.emoji)
                .font(.system(size: 30))
            
            Text(item.foodItem.name)
                .font(.caption)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            Text("x\(item.quantity)")
                .font(.caption2)
                .foregroundColor(.black.opacity(0.7))
            
            Button("Feed") {
                onFeed()
            }
            .buttonStyle(.bordered)
            .tint(.pacePalOrange)
            .font(.caption)
        }
        .padding(8)
        .background(Color.pacePalOrange.opacity(0.1))
        .cornerRadius(8)
        .frame(width: 80)
    }
}

struct EvolutionNotificationView: View {
    let onDismiss: () -> Void
    @State private var animationScale: CGFloat = 0.5
    @State private var animationOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 20) {
                // Evolution Icon with Animation
                ZStack {
                    Circle()
                        .fill(Color.pacePalOrange)
                        .frame(width: 100, height: 100)
                        .scaleEffect(animationScale)
                        .opacity(animationOpacity)
                    
                    Text("🎉")
                        .font(.system(size: 50))
                        .scaleEffect(animationScale)
                        .opacity(animationOpacity)
                }
                
                // Evolution Message
                VStack(spacing: 12) {
                    Text("Your creature has evolved!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Tap to see the details")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .opacity(animationOpacity)
            }
            .padding(30)
            .background(Color.pacePalOrange.opacity(0.95))
            .cornerRadius(20)
            .scaleEffect(animationScale)
            .opacity(animationOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animationScale = 1.0
                animationOpacity = 1.0
            }
        }
    }
}

#Preview {
    HomeView()
}


