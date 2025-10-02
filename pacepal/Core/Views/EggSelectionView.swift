import SwiftUI

struct EggSelectionView: View {
    var onComplete: () -> Void

    @State private var selected: CreatureProfile.EggType? = nil
    @State private var isSaving = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Choose your egg")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.pacePalOrange)

                HStack(spacing: 16) {
                    eggCard(type: .ember, title: "Ember")
                    eggCard(type: .aqua, title: "Aqua")
                    eggCard(type: .terra, title: "Terra")
                }

                Button(action: createCreature) {
                    if isSaving { ProgressView().tint(.pacePalOrange) }
                    else { Text("Create Creature").font(.headline) }
                }
                .disabled(selected == nil || isSaving)
                .buttonStyle(.borderedProminent)
                .tint(.pacePalOrange)
                .foregroundColor(.white)
            }
            .padding()
        }
    }

    private func eggCard(type: CreatureProfile.EggType, title: String) -> some View {
        Button(action: { selected = type }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pacePalOrange.opacity(selected == type ? 0.9 : 0.3))
                        .frame(width: 90, height: 120)
                    Text("🥚")
                        .font(.system(size: 40))
                }
                Text(title)
                    .foregroundColor(.pacePalOrange)
            }
        }
        .buttonStyle(.plain)
    }

    private func createCreature() {
        guard selected != nil else { return }
        isSaving = true
        
        // Create new active creature (egg stage)
        let now = Date()
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        let end = cal.date(byAdding: .day, value: 7, to: start) ?? now.addingTimeInterval(7*86400)
        
        let creature = Creature(
            id: UUID().uuidString,
            stage: 0, // egg stage
            runPoints: 0,
            kmCurrency: 0,
            happiness: 50,
            experiencePoints: 0,
            hunger: 80,
            lastFedDate: now,
            weekStart: start,
            weekEnd: end
        )
        
        ActiveCreatureStorage.shared.save(creature)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isSaving = false
            onComplete()
        }
    }
}

#Preview {
    EggSelectionView { }
}


