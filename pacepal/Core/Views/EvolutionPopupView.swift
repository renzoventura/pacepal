import SwiftUI

struct EvolutionPopupView: View {
    let oldStage: Int
    let newStage: Int
    let stageName: String
    let onDismiss: () -> Void
    
    @State private var animationScale: CGFloat = 0.5
    @State private var animationOpacity: Double = 0.0
    @State private var showSparkles = false
    @State private var showNewStage = false
    
    private var evolutionTitle: String {
        if oldStage == 0 && newStage == 1 {
            return "🥚 Your Egg Has Hatched! 🐣"
        } else {
            return "🎉 Evolution Complete! 🎉"
        }
    }
    
    private var evolutionMessage: String {
        if oldStage == 0 && newStage == 1 {
            return "Your little creature has hatched from its egg!"
        } else {
            return "Your pet has evolved!"
        }
    }
    
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
                        .frame(width: 120, height: 120)
                        .scaleEffect(animationScale)
                        .opacity(animationOpacity)
                    
                    // Show old stage first, then transition to new stage
                    Text(showNewStage ? (Creature.stageNames[newStage]?.stageEmoji ?? "❓") : (Creature.stageNames[oldStage]?.stageEmoji ?? "❓"))
                        .font(.system(size: 60))
                        .scaleEffect(animationScale)
                        .opacity(animationOpacity)
                        .animation(.easeInOut(duration: 0.5), value: showNewStage)
                }
                
                // Evolution Message
                VStack(spacing: 12) {
                    Text(evolutionTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(evolutionMessage)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 8) {
                        Text("\(Creature.stageNames[oldStage] ?? "Unknown") → \(stageName)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.pacePalOrange)
                        
                        Text("New Stage: \(stageName)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                .opacity(animationOpacity)
                
                // Continue Button
                Button("Continue") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.pacePalOrange)
                .font(.headline)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .opacity(animationOpacity)
            }
            .padding(30)
            .background(Color.pacePalOrange.opacity(0.95))
            .cornerRadius(20)
            .scaleEffect(animationScale)
            .opacity(animationOpacity)
        }
        .onAppear {
            // Start with old stage emoji
            showNewStage = false
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animationScale = 1.0
                animationOpacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showSparkles = true
            }
            
            // Transition to new stage after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showNewStage = true
                }
            }
        }
    }
}

extension String {
    var stageEmoji: String {
        switch self {
        case "Egg": return "🥚"
        case "Baby": return "🐣"
        case "Teen": return "🐥"
        case "Adult": return "🐔"
        default: return "❓"
        }
    }
}

#Preview {
    EvolutionPopupView(
        oldStage: 0,
        newStage: 1,
        stageName: "Baby",
        onDismiss: {}
    )
}
