import SwiftUI

struct CouponView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var runs: [Run] = []
    @State private var isRedeemingAll = false
    @State private var showConfirmation = false
    @State private var showSuccess = false
    @State private var selectedRun: Run?
    @State private var totalPointsEarned = 0
    @State private var totalKMEarned = 0.0
    @State private var isRedeemingSingle = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("Redeem Runs")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.pacePalOrange)

                    if unredeemed.isEmpty {
                        Text("No runs to redeem.")
                            .foregroundColor(.black.opacity(0.7))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(unredeemed) { run in
                                    VStack(spacing: 12) {
                                        // Run Info Section
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(run.name)
                                                .font(.headline)
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.leading)
                                            
                                            Text(formatDate(run.date))
                                                .font(.subheadline)
                                                .foregroundColor(.black.opacity(0.7))
                                            
                                            HStack(spacing: 12) {
                                                HStack(spacing: 4) {
                                                    Text("🏃")
                                                        .font(.caption)
                                                    Text(String(format: "%.2f km", run.distance))
                                                        .font(.subheadline)
                                                        .foregroundColor(.black.opacity(0.8))
                                                }
                                                
                                                if let calories = run.calories {
                                                    HStack(spacing: 4) {
                                                        Text("🔥")
                                                            .font(.caption)
                                                        Text("\(Int(calories)) cal")
                                                            .font(.subheadline)
                                                            .foregroundColor(.black.opacity(0.6))
                                                    }
                                                }
                                                
                                                if let avgSpeed = run.averageSpeed {
                                                    HStack(spacing: 4) {
                                                        Text("⚡")
                                                            .font(.caption)
                                                        Text("\(String(format: "%.1f", avgSpeed * 3.6)) km/h")
                                                            .font(.subheadline)
                                                            .foregroundColor(.black.opacity(0.6))
                                                    }
                                                }
                                                
                                                Spacer()
                                            }
                                        }
                                        
                                        // Rewards and Redeem Section
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Rewards")
                                                    .font(.caption)
                                                    .foregroundColor(.black.opacity(0.6))
                                                
                                                HStack(spacing: 12) {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text("+1 Point")
                                                            .font(.subheadline)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(.pacePalOrange)
                                                        Text("Run Point")
                                                            .font(.caption2)
                                                            .foregroundColor(.black.opacity(0.5))
                                                    }
                                                    
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text("+\(String(format: "%.1f", run.distance)) KM")
                                                            .font(.subheadline)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(.pacePalOrange)
                                                        Text("Currency")
                                                            .font(.caption2)
                                                            .foregroundColor(.black.opacity(0.5))
                                                    }
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Button("Redeem") { 
                                                selectedRun = run
                                                showConfirmation = true
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(.pacePalOrange)
                                            .foregroundColor(.white)
                                            .font(.headline)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                            .disabled(isRedeemingSingle || isRedeemingAll)
                                            .overlay(
                                                Group {
                                                    if isRedeemingSingle {
                                                        ProgressView()
                                                            .tint(.pacePalOrange)
                                                            .scaleEffect(0.8)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                    .padding(16)
                                    .background(Color.pacePalOrange.opacity(0.1))
                                    .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal)
                        }

                        Button(action: {
                            selectedRun = nil // Indicates redeem all
                            showConfirmation = true
                        }) {
                            HStack {
                                if isRedeemingAll { 
                                    ProgressView()
                                        .tint(.pacePalOrange)
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Redeem All")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pacePalOrange)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .disabled(isRedeemingAll || isRedeemingSingle)
                    }
                }
                .padding()
            }
            .navigationTitle("Redeem Runs")
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
        .onAppear(perform: load)
        .alert("Confirm Redemption", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Redeem") {
                if let run = selectedRun {
                    redeemSingleRun(run)
                } else {
                    redeemAllRuns()
                }
            }
        } message: {
            if let run = selectedRun {
                Text("Redeem '\(run.name)' for +1 Point and +\(String(format: "%.1f", run.distance)) KM?")
            } else {
                Text("Redeem all \(unredeemed.count) runs for +\(unredeemed.count) Points and +\(String(format: "%.1f", unredeemed.reduce(0) { $0 + $1.distance })) KM?")
            }
        }
        .overlay(
            Group {
                if showSuccess {
                    SuccessAnimationView(
                        pointsEarned: totalPointsEarned,
                        kmEarned: totalKMEarned,
                        onDismiss: {
                            showSuccess = false
                            dismiss()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccess)
                }
            }
        )
    }

    private var unredeemed: [Run] {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return runs
            .filter { !$0.redeemed && $0.date >= oneWeekAgo }
            .sorted { $0.date > $1.date }
    }

    private func load() {
        runs = RunStorage.shared.loadRuns()
    }

    private func save() {
        RunStorage.shared.saveRuns(runs)
    }

    private func redeemSingleRun(_ run: Run) {
        guard let idx = runs.firstIndex(of: run) else { return }
        isRedeemingSingle = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            runs[idx].redeemed = true
            ActiveCreatureStorage.shared.applyRedeemedRun(distanceKm: run.distance)
            save()
            
            // Set success data
            totalPointsEarned = 1
            totalKMEarned = run.distance
            
            isRedeemingSingle = false
            showSuccess = true
        }
    }

    private func redeemAllRuns() {
        isRedeemingAll = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var pointsEarned = 0
            var kmEarned = 0.0
            
            for (i, r) in runs.enumerated() where !runs[i].redeemed {
                runs[i].redeemed = true
                ActiveCreatureStorage.shared.applyRedeemedRun(distanceKm: r.distance)
                pointsEarned += 1
                kmEarned += r.distance
            }
            save()
            
            // Set success data
            totalPointsEarned = pointsEarned
            totalKMEarned = kmEarned
            
            isRedeemingAll = false
            showSuccess = true
        }
    }

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: date)
    }
}

struct SuccessAnimationView: View {
    let pointsEarned: Int
    let kmEarned: Double
    let onDismiss: () -> Void
    
    @State private var animationScale: CGFloat = 0.5
    @State private var animationOpacity: Double = 0.0
    @State private var showParticles = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 20) {
                // Success Icon with Animation
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 100, height: 100)
                        .scaleEffect(animationScale)
                        .opacity(animationOpacity)
                    
                    Text("🎉")
                        .font(.system(size: 50))
                        .scaleEffect(animationScale)
                        .opacity(animationOpacity)
                }
                
                // Success Message
                VStack(spacing: 12) {
                    Text("Redeemed Successfully!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("You earned:")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 30) {
                        VStack(spacing: 4) {
                            Text("+\(pointsEarned)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.pacePalOrange)
                            Text("Points")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack(spacing: 4) {
                            Text("+\(String(format: "%.1f", kmEarned))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.pacePalOrange)
                            Text("KM")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animationScale = 1.0
                animationOpacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showParticles = true
            }
        }
    }
}

#Preview {
    CouponView()
}


