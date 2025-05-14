import SwiftUI

struct EquipmentListView: View {
    @State private var equipment: [(id: Int, name: String, description: String?, imagePath: String?, status: String)] = []
    @State private var showingAddEquipment = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(equipment, id: \.id) { item in
                        EquipmentCard(equipment: item, isAdmin: authViewModel.currentUser?.role == "admin", reload: loadEquipment)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationTitle("Equipment")
            .toolbar {
                if authViewModel.currentUser?.role == "admin" {
                    Button(action: {
                        showingAddEquipment = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddEquipment) {
                AddEquipmentView()
            }
            .onChange(of: showingAddEquipment) { newValue in
                if !newValue {
                    loadEquipment()
                }
            }
            .onAppear {
                loadEquipment()
            }
        }
    }
    
    private func loadEquipment() {
        equipment = DatabaseManager.shared.getAllEquipment()
    }
}

struct EquipmentCard: View {
    let equipment: (id: Int, name: String, description: String?, imagePath: String?, status: String)
    var isAdmin: Bool
    var reload: () -> Void
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imagePath = equipment.imagePath, let uiImage = loadImage(imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(16)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .foregroundColor(.gray)
                    .padding(.vertical, 16)
            }
            HStack {
                Text(equipment.name)
                    .font(.title3).bold()
                Spacer()
                statusIcon(equipment.status)
                Text(equipment.status)
                    .font(.subheadline)
                    .foregroundColor(statusColor(equipment.status))
            }
            if let description = equipment.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            if isAdmin {
                HStack {
                    Button(action: { showingEdit = true }) {
                        Label("Edit", systemImage: "pencil")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    Button(action: { showingDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showingEdit) {
            EditEquipmentView(equipment: equipment, reload: reload)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Equipment"),
                message: Text("Are you sure you want to delete this equipment?"),
                primaryButton: .destructive(Text("Delete")) {
                    _ = DatabaseManager.shared.deleteEquipment(id: equipment.id)
                    reload()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    func loadImage(_ imagePath: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(imagePath)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    func statusColor(_ status: String) -> Color {
        switch status {
        case "Available": return .green
        case "In Use": return .orange
        case "Maintenance": return .red
        default: return .gray
        }
    }
    
    func statusIcon(_ status: String) -> some View {
        switch status {
        case "Available": return Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case "In Use": return Image(systemName: "clock.fill").foregroundColor(.orange)
        case "Maintenance": return Image(systemName: "wrench.fill").foregroundColor(.red)
        default: return Image(systemName: "questionmark.circle.fill").foregroundColor(.gray)
        }
    }
}

struct EditEquipmentView: View {
    let equipment: (id: Int, name: String, description: String?, imagePath: String?, status: String)
    var reload: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String
    @State private var description: String
    @State private var status: String
    @State private var image: UIImage?
    @State private var showingImagePicker = false
    
    init(equipment: (id: Int, name: String, description: String?, imagePath: String?, status: String), reload: @escaping () -> Void) {
        self.equipment = equipment
        self.reload = reload
        _name = State(initialValue: equipment.name)
        _description = State(initialValue: equipment.description ?? "")
        _status = State(initialValue: equipment.status)
        if let imagePath = equipment.imagePath {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent(imagePath)
            _image = State(initialValue: UIImage(contentsOfFile: fileURL.path))
        } else {
            _image = State(initialValue: nil)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Form {
                    Section(header: Text("Equipment Details")) {
                        TextField("Name", text: $name)
                        TextField("Description", text: $description)
                        Picker("Status", selection: $status) {
                            ForEach(Equipment.statuses, id: \.self) { status in
                                Text(status)
                            }
                        }
                    }
                    Section(header: Text("Image")) {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 180)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text(image == nil ? "Select Image" : "Change Image")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                        }
                    }
                }
                Button(action: {
                    saveEquipment()
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
            .navigationTitle("Edit Equipment")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $image)
        }
    }
    
    private func saveEquipment() {
        var imagePath: String? = equipment.imagePath
        if let image = image {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = imagePath ?? UUID().uuidString + ".jpg"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                try? imageData.write(to: fileURL)
                imagePath = fileName
            }
        }
        if DatabaseManager.shared.updateEquipment(
            id: equipment.id,
            name: name,
            description: description.isEmpty ? nil : description,
            imagePath: imagePath,
            status: status
        ) {
            presentationMode.wrappedValue.dismiss()
            reload()
        }
    }
}

struct AddEquipmentView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var description = ""
    @State private var status = "Available"
    @State private var image: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Form {
                    Section(header: Text("Equipment Details")) {
                        TextField("Name", text: $name)
                        TextField("Description", text: $description)
                        Picker("Status", selection: $status) {
                            ForEach(Equipment.statuses, id: \.self) { status in
                                Text(status)
                            }
                        }
                    }
                    Section(header: Text("Image")) {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 180)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text(image == nil ? "Select Image" : "Change Image")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                        }
                    }
                }
                Button(action: {
                    saveEquipment()
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
            .navigationTitle("Add Equipment")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $image)
        }
    }
    
    private func saveEquipment() {
        // Save image to documents directory
        var imagePath: String?
        if let image = image {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = UUID().uuidString + ".jpg"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                try? imageData.write(to: fileURL)
                imagePath = fileName
            }
        }
        
        // Save equipment to database
        if DatabaseManager.shared.addEquipment(
            name: name,
            description: description.isEmpty ? nil : description,
            imagePath: imagePath,
            status: status
        ) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
} 