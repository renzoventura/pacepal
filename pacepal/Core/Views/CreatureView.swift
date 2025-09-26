import SwiftUI

struct CreatureView: View {
    let state: CreatureState
    @State private var bounce: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(colorForMood(state.mood))
                    .frame(width: 120 + CGFloat(state.growth * 10), height: 120 + CGFloat(state.growth * 10))
                    .scaleEffect(bounce ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: bounce)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                HStack(spacing: 24) {
                    Circle().fill(.white).frame(width: 16, height: 16)
                    Circle().fill(.white).frame(width: 16, height: 16)
                }
                .offset(y: -10)
                
                Text(emojiForMood(state.mood))
                    .font(.system(size: 28))
                    .offset(y: 18)
            }
            .onAppear { bounce = true }

            Text(labelForMood(state.mood))
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 4) {
                Text("Health")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                ProgressView(value: state.health, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .frame(width: 180)
            }
        }
    }

    private func colorForMood(_ mood: CreatureMood) -> Color {
        switch mood {
        case .happy: return .green
        case .neutral: return .blue
        case .tired: return .orange
        case .sad: return .gray
        }
    }

    private func emojiForMood(_ mood: CreatureMood) -> String {
        switch mood {
        case .happy: return "😊"
        case .neutral: return "😐"
        case .tired: return "🥱"
        case .sad: return "😢"
        }
    }

    private func labelForMood(_ mood: CreatureMood) -> String {
        switch mood {
        case .happy: return "Happy"
        case .neutral: return "Okay"
        case .tired: return "Tired"
        case .sad: return "Sad"
        }
    }
}

#Preview {
    CreatureView(state: CreatureState(mood: .happy, health: 0.8, growth: 2, lastActivityDate: Date()))
}


