import SwiftUI

struct MembershipView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                if let user = authViewModel.currentUser {
                    VStack(alignment: .center, spacing: 20) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .foregroundColor(.blue)
                            .shadow(radius: 8)
                        Text("Membership Details")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.purple)
                                Text("Username: \(user.username)")
                                    .font(.headline)
                            }
                            HStack {
                                Image(systemName: user.role == "admin" ? "star.fill" : "person.fill")
                                    .foregroundColor(user.role == "admin" ? .yellow : .blue)
                                Text("Role: \(user.role.capitalized)")
                                    .font(.subheadline)
                                    .foregroundColor(user.role == "admin" ? .yellow : .blue)
                            }
                            if let endDate = user.membershipEndDate, user.role != "admin" {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.purple)
                                    Text("Membership ends: \(endDate)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            } else if user.role != "admin" {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text("No active membership")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                }
                Spacer()
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationTitle("Membership")
        }
    }
} 