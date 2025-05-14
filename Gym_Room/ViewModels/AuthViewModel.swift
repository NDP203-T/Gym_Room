import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    
    func login(username: String, password: String) {
        if let result = DatabaseManager.shared.authenticateUser(username: username, password: password) {
            if result.success {
                isAuthenticated = true
                currentUser = User(id: 0, username: username, role: result.role ?? "user", membershipEndDate: nil)
                errorMessage = nil
            } else {
                errorMessage = "Invalid username or password"
            }
        } else {
            errorMessage = "Login failed"
        }
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
    }
} 