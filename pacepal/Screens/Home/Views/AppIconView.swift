import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Orange background
            Color.orange
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                // Running figure icon
                Image(systemName: "figure.run")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                
                // PacePal text
                Text("PacePal")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

#Preview {
    AppIconView()
}
