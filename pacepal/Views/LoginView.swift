import SwiftUI

struct LoginView: View {
    @State private var navigateToHome = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("PacePal")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.pacePalOrange)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 20) {
                    Button(action: loginWithStrava) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "figure.run")
                                    .font(.title2)
                            }
                            Text("Login with Strava")
                                .font(.headline)
                        }
                        .foregroundColor(.pacePalOrange)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 40)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                opacity = 1.0
            }
        }
        .fullScreenCover(isPresented: $navigateToHome) {
            HomeView()
        }
    }
    
    private func loginWithStrava() {
        isLoading = true
        errorMessage = nil
        
        StravaAuthService.shared.authorize { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    withAnimation(.easeOut(duration: 0.8)) {
                        opacity = 0.0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        navigateToHome = true
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
