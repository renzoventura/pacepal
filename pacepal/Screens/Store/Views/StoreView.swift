import SwiftUI

struct StoreView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inventory: [InventoryItem] = []
    @State private var showPurchaseAlert = false
    @State private var selectedItem: FoodItem?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("Store")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.pacePalOrange)
                        .padding(.top)
                    
                    // Current KM Currency
                    HStack {
                        Text("Your KM Currency:")
                            .foregroundColor(.black.opacity(0.7))
                        Text(String(format: "%.1f", ActiveCreatureStorage.shared.load()?.kmCurrency ?? 0.0))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.pacePalOrange)
                    }
                    .padding()
                    .background(Color.pacePalOrange.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Food Items Grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(FoodItem.availableItems) { item in
                                FoodItemCard(
                                    item: item,
                                    onPurchase: { purchaseItem(item) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.pacePalOrange)
                }
            }
        }
        .onAppear {
            loadInventory()
        }
        .alert("Purchase Confirmation", isPresented: $showPurchaseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Buy") {
                if let item = selectedItem {
                    confirmPurchase(item)
                }
            }
        } message: {
            if let item = selectedItem {
                Text("Buy \(item.emoji) \(item.name) for \(String(format: "%.1f", item.cost)) KM?")
            }
        }
    }
    
    private func loadInventory() {
        inventory = InventoryStorage.shared.loadInventory()
    }
    
    private func purchaseItem(_ item: FoodItem) {
        guard let creature = ActiveCreatureStorage.shared.load() else {
            errorMessage = "No active creature found"
            return
        }
        
        guard creature.kmCurrency >= item.cost else {
            errorMessage = "Not enough KM Currency! You need \(String(format: "%.1f", item.cost)) KM"
            return
        }
        
        selectedItem = item
        showPurchaseAlert = true
    }
    
    private func confirmPurchase(_ item: FoodItem) {
        guard let creature = ActiveCreatureStorage.shared.load() else {
            errorMessage = "No active creature found"
            return
        }
        
        // Play purchase sound
        SoundService.shared.playBuyItem()
        SoundService.shared.playHapticFeedback(.medium)
        
        // Deduct KM Currency
        var updatedCreature = creature
        updatedCreature.kmCurrency -= item.cost
        ActiveCreatureStorage.shared.save(updatedCreature)
        
        // Add to inventory
        InventoryStorage.shared.addItem(item)
        
        // Clear error and reload
        errorMessage = nil
        loadInventory()
    }
}

struct FoodItemCard: View {
    let item: FoodItem
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text(item.emoji)
                .font(.system(size: 40))
            
            Text(item.name)
                .font(.headline)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            Text(item.description)
                .font(.caption)
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            VStack(spacing: 4) {
                Text("\(String(format: "%.1f", item.cost)) KM")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.pacePalOrange)
                
                Text("+\(item.happinessEffect) happiness")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Button("Buy") {
                onPurchase()
            }
            .buttonStyle(.bordered)
            .tint(.pacePalOrange)
            .disabled(ActiveCreatureStorage.shared.load()?.kmCurrency ?? 0 < item.cost)
        }
        .padding()
        .background(Color.pacePalOrange.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    StoreView()
}
