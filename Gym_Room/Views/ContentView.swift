import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.currentUser?.role == "admin" {
                    AdminView()
                } else {
                    UserView()
                }
            } else {
                LoginView()
            }
        }
        .environmentObject(authViewModel)
    }
}

struct AdminView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            NavigationView {
                EquipmentListView()
                    .navigationBarItems(trailing: Button("Logout") {
                        authViewModel.logout()
                    })
            }
            .tabItem {
                Label("Equipment", systemImage: "dumbbell.fill")
            }
            
            StaffListView()
                .tabItem {
                    Label("Staff", systemImage: "person.2.fill")
                }
            
            UserManagementView()
                .tabItem {
                    Label("Users", systemImage: "person.3.fill")
                }
        }
    }
}

struct UserView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            NavigationView {
                EquipmentListView()
                    .navigationBarItems(trailing: Button("Logout") {
                        authViewModel.logout()
                    })
            }
            .tabItem {
                Label("Equipment", systemImage: "dumbbell.fill")
            }
            
            MembershipView()
                .tabItem {
                    Label("Membership", systemImage: "creditcard.fill")
                }
        }
    }
} 