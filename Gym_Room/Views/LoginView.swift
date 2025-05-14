import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "dumbbell.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                    .shadow(radius: 8)
                Text("Gym Room")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                }
                .padding(.horizontal, 32)
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.top, -12)
                }
                Button(action: {
                    authViewModel.login(username: username, password: password)
                }) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14)
                        .shadow(radius: 4)
                }
                .padding(.horizontal, 32)
                Spacer()
            }
        }
    }
} 