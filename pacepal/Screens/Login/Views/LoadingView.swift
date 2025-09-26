import SwiftUI

struct LoadingView: View {
    @State private var progress: Double = 0.0
    @State private var loadingText = "Connecting to Strava..."
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("PacePal")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.pacePalOrange)
                
                VStack(spacing: 20) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .pacePalOrange))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .frame(width: 250)
                    
                    Text(loadingText)
                        .foregroundColor(.pacePalOrange)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            startLoadingSequence()
        }
    }
    
    private func startLoadingSequence() {
        let steps = [
            ("Connecting to Strava...", 0.2),
            ("Fetching your activities...", 0.5),
            ("Analyzing your progress...", 0.8),
            ("Preparing your creature...", 1.0)
        ]
        
        for (index, (text, targetProgress)) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.8) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    loadingText = text
                    progress = targetProgress
                }
            }
        }
        
        // Complete loading after all steps
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps.count) * 0.8) {
            onComplete()
        }
    }
}

#Preview {
    LoadingView {
        print("Loading complete!")
    }
}
