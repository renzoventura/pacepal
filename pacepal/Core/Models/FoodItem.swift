import Foundation

struct FoodItem: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String
    let cost: Double // KM Currency cost
    let happinessEffect: Int // How much happiness it provides
    let description: String
    
    static let availableItems: [FoodItem] = [
        FoodItem(
            id: "apple",
            name: "Apple",
            emoji: "🍎",
            cost: 3.0,
            happinessEffect: 5,
            description: "A fresh, crunchy apple that gives a small happiness boost"
        ),
        FoodItem(
            id: "potato",
            name: "Potato",
            emoji: "🥔",
            cost: 5.0,
            happinessEffect: 8,
            description: "A hearty potato that provides good nutrition"
        ),
        FoodItem(
            id: "cake",
            name: "Cake",
            emoji: "🍰",
            cost: 10.0,
            happinessEffect: 15,
            description: "A delicious cake that makes your creature very happy"
        ),
        FoodItem(
            id: "carrot",
            name: "Carrot",
            emoji: "🥕",
            cost: 2.0,
            happinessEffect: 3,
            description: "A healthy carrot snack"
        ),
        FoodItem(
            id: "banana",
            name: "Banana",
            emoji: "🍌",
            cost: 4.0,
            happinessEffect: 6,
            description: "A sweet banana for energy"
        ),
        FoodItem(
            id: "pizza",
            name: "Pizza",
            emoji: "🍕",
            cost: 15.0,
            happinessEffect: 25,
            description: "A special treat that brings maximum happiness"
        )
    ]
}

struct InventoryItem: Codable, Identifiable, Equatable {
    let id: String
    let foodItem: FoodItem
    let quantity: Int
    let purchaseDate: Date
}

final class InventoryStorage {
    static let shared = InventoryStorage()
    private init() {}
    
    private let inventoryKey = "inventory_storage_v1"
    
    func loadInventory() -> [InventoryItem] {
        guard let data = UserDefaults.standard.data(forKey: inventoryKey) else { return [] }
        return (try? JSONDecoder().decode([InventoryItem].self, from: data)) ?? []
    }
    
    func saveInventory(_ items: [InventoryItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: inventoryKey)
        }
    }
    
    func addItem(_ foodItem: FoodItem, quantity: Int = 1) {
        var inventory = loadInventory()
        
        if let index = inventory.firstIndex(where: { $0.foodItem.id == foodItem.id }) {
            inventory[index] = InventoryItem(
                id: inventory[index].id,
                foodItem: foodItem,
                quantity: inventory[index].quantity + quantity,
                purchaseDate: inventory[index].purchaseDate
            )
        } else {
            let newItem = InventoryItem(
                id: UUID().uuidString,
                foodItem: foodItem,
                quantity: quantity,
                purchaseDate: Date()
            )
            inventory.append(newItem)
        }
        
        saveInventory(inventory)
    }
    
    func removeItem(_ foodItem: FoodItem, quantity: Int = 1) {
        var inventory = loadInventory()
        
        if let index = inventory.firstIndex(where: { $0.foodItem.id == foodItem.id }) {
            let newQuantity = max(0, inventory[index].quantity - quantity)
            if newQuantity == 0 {
                inventory.remove(at: index)
            } else {
                inventory[index] = InventoryItem(
                    id: inventory[index].id,
                    foodItem: foodItem,
                    quantity: newQuantity,
                    purchaseDate: inventory[index].purchaseDate
                )
            }
        }
        
        saveInventory(inventory)
    }
    
    func getItemQuantity(_ foodItem: FoodItem) -> Int {
        let inventory = loadInventory()
        return inventory.first { $0.foodItem.id == foodItem.id }?.quantity ?? 0
    }
}
