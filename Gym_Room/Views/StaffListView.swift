import SwiftUI

struct StaffListView: View {
    @State private var staff: [Staff] = []
    @State private var showingAddStaff = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(staff, id: \.id) { staffMember in
                        StaffCard(staff: staffMember, reload: loadStaff)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationTitle("Staff")
            .toolbar {
                Button(action: {
                    showingAddStaff = true
                }) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showingAddStaff) {
                AddStaffView()
            }
            .onChange(of: showingAddStaff) { newValue in
                if !newValue {
                    loadStaff()
                }
            }
            .onAppear {
                loadStaff()
            }
        }
    }
    
    private func loadStaff() {
        staff = DatabaseManager.shared.getAllStaff()
    }
}

struct StaffCard: View {
    let staff: Staff
    var reload: () -> Void
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .top, endPoint: .bottom))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .padding(12)
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text(staff.name)
                        .font(.title3).bold()
                    Text(staff.position)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                Spacer()
                Button(action: { showingEdit = true }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.orange)
                }
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            if let phone = staff.phone, !phone.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                    Text(phone)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            if let email = staff.email, !email.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.purple)
                    Text(email)
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
            EditStaffView(staff: staff, reload: reload)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Staff"),
                message: Text("Are you sure you want to delete this staff member?"),
                primaryButton: .destructive(Text("Delete")) {
                    _ = DatabaseManager.shared.deleteStaff(id: staff.id)
                    reload()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct EditStaffView: View {
    let staff: Staff
    var reload: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String
    @State private var position: String
    @State private var phone: String
    @State private var email: String
    
    init(staff: Staff, reload: @escaping () -> Void) {
        self.staff = staff
        self.reload = reload
        _name = State(initialValue: staff.name)
        _position = State(initialValue: staff.position)
        _phone = State(initialValue: staff.phone ?? "")
        _email = State(initialValue: staff.email ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Form {
                    Section(header: Text("Staff Details")) {
                        TextField("Name", text: $name)
                        TextField("Position", text: $position)
                        TextField("Phone", text: $phone)
                        TextField("Email", text: $email)
                            .autocapitalization(.none)
                    }
                }
                Button(action: {
                    saveStaff()
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
            .navigationTitle("Edit Staff")
        }
    }
    
    private func saveStaff() {
        if DatabaseManager.shared.updateStaff(
            id: staff.id,
            name: name,
            position: position,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email
        ) {
            presentationMode.wrappedValue.dismiss()
            reload()
        }
    }
}

struct AddStaffView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var position = ""
    @State private var phone = ""
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Staff Details")) {
                    TextField("Name", text: $name)
                    TextField("Position", text: $position)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add Staff")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveStaff()
                }
            )
        }
    }
    
    private func saveStaff() {
        if DatabaseManager.shared.addStaff(
            name: name,
            position: position,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email
        ) {
            presentationMode.wrappedValue.dismiss()
        }
    }
} 