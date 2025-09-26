import SwiftUI

struct LandingView: View {
    @State private var navigateToLogin = false
    @State private var navigateToHome = false
    @State private var navigateToEggs = false
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack {
                Text("PacePal")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.pacePalOrange)
                    .multilineTextAlignment(.center)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                opacity = 1.0
            }
            
            // Decide where to go after a short splash
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                StravaAuthService.shared.hasValidSession { isValid in
                    withAnimation(.easeOut(duration: 0.8)) {
                        opacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        if isValid {
                            navigateToHome = true
                        } else {
                            navigateToLogin = true
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $navigateToLogin) { LoginView() }
        .fullScreenCover(isPresented: $navigateToHome) { HomeView() }
    }
}

#Preview {
    LandingView()
}
