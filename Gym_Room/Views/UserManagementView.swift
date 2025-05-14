import SwiftUI

struct UserManagementView: View {
    @State private var users: [User] = []
    @State private var showingAddUser = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(users, id: \.id) { user in
                        UserCard(user: user, reload: loadUsers)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationTitle("Users")
            .toolbar {
                Button(action: {
                    showingAddUser = true
                }) {
                    Image(systemName: "person.badge.plus.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showingAddUser) {
                AddUserView()
            }
            .onChange(of: showingAddUser) { newValue in
                if !newValue {
                    loadUsers()
                }
            }
            .onAppear {
                loadUsers()
            }
        }
    }
    
    private func loadUsers() {
        users = DatabaseManager.shared.getAllUsers()
    }
}

struct UserCard: View {
    let user: User
    var reload: () -> Void
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .top, endPoint: .bottom))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: user.role == "admin" ? "person.crop.circle.badge.checkmark" : "person.crop.circle")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .padding(12)
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.username)
                        .font(.title3).bold()
                    HStack(spacing: 8) {
                        Image(systemName: user.role == "admin" ? "star.fill" : "person.fill")
                            .foregroundColor(user.role == "admin" ? .yellow : .blue)
                        Text(user.role.capitalized)
                            .font(.subheadline)
                            .foregroundColor(user.role == "admin" ? .yellow : .blue)
                    }
                }
                Spacer()
                if user.role != "admin" {
                    Button(action: { showingEdit = true }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.orange)
                    }
                    Button(action: { showingDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            if let endDate = user.membershipEndDate, user.role != "admin" {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.purple)
                    Text("Membership ends: \(endDate)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showingEdit) {
            EditUserView(user: user, reload: reload)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete User"),
                message: Text("Are you sure you want to delete this user?"),
                primaryButton: .destructive(Text("Delete")) {
                    _ = DatabaseManager.shared.deleteUser(id: user.id)
                    reload()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct EditUserView: View {
    let user: User
    var reload: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var username: String
    @State private var role: String
    @State private var membershipEndDate: Date
    
    init(user: User, reload: @escaping () -> Void) {
        self.user = user
        self.reload = reload
        _username = State(initialValue: user.username)
        _role = State(initialValue: user.role)
        if let endDateStr = user.membershipEndDate, let date = EditUserView.dateFormatter.date(from: endDateStr) {
            _membershipEndDate = State(initialValue: date)
        } else {
            _membershipEndDate = State(initialValue: Date())
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Form {
                    Section(header: Text("User Details")) {
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                        Picker("Role", selection: $role) {
                            ForEach(User.roles, id: \.self) { role in
                                Text(role.capitalized)
                            }
                        }
                    }
                    if role == "user" {
                        Section(header: Text("Membership")) {
                            DatePicker(
                                "End Date",
                                selection: $membershipEndDate,
                                displayedComponents: .date
                            )
                        }
                    }
                }
                Button(action: {
                    saveUser()
                }) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14)
                        .shadow(radius: 4)
                }
                .padding(.horizontal)
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.red)
                .padding(.bottom, 8)
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationTitle("Edit User")
        }
    }
    
    private func saveUser() {
        let dateFormatter = EditUserView.dateFormatter
        let endDateString = role == "user" ? dateFormatter.string(from: membershipEndDate) : nil
        if DatabaseManager.shared.updateUser(
            id: user.id,
            username: username,
            role: role,
            membershipEndDate: endDateString
        ) {
            presentationMode.wrappedValue.dismiss()
            reload()
        }
    }
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
}

struct AddUserView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var username = ""
    @State private var password = ""
    @State private var role = "user"
    @State private var membershipEndDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("User Details")) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                    Picker("Role", selection: $role) {
                        ForEach(User.roles, id: \.self) { role in
                            Text(role.capitalized)
                        }
                    }
                }
                
                if role == "user" {
                    Section(header: Text("Membership")) {
                        DatePicker(
                            "End Date",
                            selection: $membershipEndDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("Add User")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveUser()
                }
            )
        }
    }
    
    private func saveUser() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let endDateString = role == "user" ? dateFormatter.string(from: membershipEndDate) : nil
        
        if DatabaseManager.shared.createUser(
            username: username,
            password: password,
            role: role,
            membershipEndDate: endDateString
        ) {
            presentationMode.wrappedValue.dismiss()
        }
    }
} 