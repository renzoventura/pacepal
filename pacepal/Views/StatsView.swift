import SwiftUI

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    var stats: StravaStats?

    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    Text("Stats")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.pacePalOrange)
                        .padding(.top, 20)
                
                if let stats {
                    VStack(spacing: 16) {
                        statRow("Total distance", formatDistance(stats.totalDistanceMeters))
                        statRow("Activities", String(stats.totalActivities))
                        statRow("Moving time", formatTime(stats.totalMovingTimeSeconds))
                        statRow("Calories", "\(Int(stats.calories)) kcal")
                        statRow("This week", formatDistance(stats.weekDistanceMeters))
                        if let lastSync = stats.lastSync {
                            statRow("Last sync", lastSync.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    .padding()
                    .background(Color.pacePalOrange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                } else {
                    Text("No stats yet. Connect Strava on Home.")
                        .foregroundColor(.black.opacity(0.7))
                        .font(.subheadline)
                }
                
                    Spacer()
                }
            }
            .navigationTitle("Stats")
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
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.black)
                .font(.subheadline)
            Spacer()
            Text(value)
                .foregroundColor(.black)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000.0
        return String(format: "%.1f km", km)
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
    }
}

#Preview {
    NavigationView { StatsView(stats: StravaStats(totalDistanceMeters: 42195, totalActivities: 12, totalMovingTimeSeconds: 12345, calories: 2500, weekDistanceMeters: 10000, lastSync: Date())) }
}


