import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("gym_room.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
            return
        }
        
        createTables()
    }
    
    private func createTables() {
        // Users table
        let createUsersTable = """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                role TEXT NOT NULL,
                membership_end_date TEXT
            );
        """
        
        // Staff table
        let createStaffTable = """
            CREATE TABLE IF NOT EXISTS staff (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                position TEXT NOT NULL,
                phone TEXT,
                email TEXT
            );
        """
        
        // Equipment table
        let createEquipmentTable = """
            CREATE TABLE IF NOT EXISTS equipment (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                image_path TEXT,
                status TEXT NOT NULL
            );
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, createUsersTable, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Users table created")
            }
        }
        sqlite3_finalize(statement)
        
        if sqlite3_prepare_v2(db, createStaffTable, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Staff table created")
            }
        }
        sqlite3_finalize(statement)
        
        if sqlite3_prepare_v2(db, createEquipmentTable, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Equipment table created")
            }
        }
        sqlite3_finalize(statement)
        
        // Thêm admin mặc định nếu chưa có
        let insertAdmin = """
            INSERT OR IGNORE INTO users (username, password, role)
            VALUES ('admin', 'admin123', 'admin');
        """
        if sqlite3_prepare_v2(db, insertAdmin, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - User Operations
    func createUser(username: String, password: String, role: String, membershipEndDate: String?) -> Bool {
        let query = "INSERT INTO users (username, password, role, membership_end_date) VALUES (?, ?, ?, ?)"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (username as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (password as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (role as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (membershipEndDate as NSString?)?.utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }
    
    func updateUser(id: Int, username: String, role: String, membershipEndDate: String?) -> Bool {
        let query = "UPDATE users SET username = ?, role = ?, membership_end_date = ? WHERE id = ?"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (username as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (role as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (membershipEndDate as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_int(statement, 4, Int32(id))
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }
    
    func deleteUser(id: Int) -> Bool {
        let query = "DELETE FROM users WHERE id = ?"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }
    
    func authenticateUser(username: String, password: String) -> (success: Bool, role: String?)? {
        let query = "SELECT role FROM users WHERE username = ? AND password = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (username as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (password as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let role = String(cString: sqlite3_column_text(statement, 0))
                sqlite3_finalize(statement)
                return (true, role)
            }
        }
        sqlite3_finalize(statement)
        return (false, nil)
    }
    
    func getAllUsers() -> [User] {
        var users: [User] = []
        let query = "SELECT id, username, role, membership_end_date FROM users"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let username = String(cString: sqlite3_column_text(statement, 1))
                let role = String(cString: sqlite3_column_text(statement, 2))
                let membershipEndDate = sqlite3_column_text(statement, 3) != nil ? String(cString: sqlite3_column_text(statement, 3)) : nil
                users.append(User(id: id, username: username, role: role, membershipEndDate: membershipEndDate))
            }
        }
        sqlite3_finalize(statement)
        return users
    }
    
    // MARK: - Staff Operations
    func addStaff(name: String, position: String, phone: String?, email: String?) -> Bool {
        let query = "INSERT INTO staff (name, position, phone, email) VALUES (?, ?, ?, ?)"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (position as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (phone as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (email as NSString?)?.utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }
    
    func updateStaff(id: Int, name: String, position: String, phone: String?, email: String?) -> Bool {
        let query = "UPDATE staff SET name = ?, position = ?, phone = ?, email = ? WHERE id = ?"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (position as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (phone as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (email as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_int(statement, 5, Int32(id))
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }
    
    func deleteStaff(id: Int) -> Bool {
        let query = "DELETE FROM staff WHERE id = ?"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }
    
    func getAllStaff() -> [Staff] {
        var staffList: [Staff] = []
        let query = "SELECT id, name, position, phone, email FROM staff"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let position = String(cString: sqlite3_column_text(statement, 2))
                let phone = sqlite3_column_text(statement, 3) != nil ? String(cString: sqlite3_column_text(statement, 3)) : nil
                let email = sqlite3_column_text(statement, 4) != nil ? String(cString: sqlite3_column_text(statement, 4)) : nil
                staffList.append(Staff(id: id, name: name, position: position, phone: phone, email: email))
            }
        }
        sqlite3_finalize(statement)
        return staffList
    }
    
    // MARK: - Equipment Operations
    func addEquipment(name: String, description: String?, imagePath: String?, status: String) -> Bool {
        let query = "INSERT INTO equipment (name, description, image_path, status) VALUES (?, ?, ?, ?)"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (description as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (imagePath as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (status as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }
    
    func updateEquipment(id: Int, name: String, description: String?, imagePath: String?, status: String) -> Bool {
        let query = "UPDATE equipment SET name = ?, description = ?, image_path = ?, status = ? WHERE id = ?"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (description as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (imagePath as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (status as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 5, Int32(id))
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }
    
    func deleteEquipment(id: Int) -> Bool {
        let query = "DELETE FROM equipment WHERE id = ?"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }
    
    func getAllEquipment() -> [(id: Int, name: String, description: String?, imagePath: String?, status: String)] {
        var equipment: [(id: Int, name: String, description: String?, imagePath: String?, status: String)] = []
        let query = "SELECT id, name, description, image_path, status FROM equipment"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let description = sqlite3_column_text(statement, 2) != nil ? String(cString: sqlite3_column_text(statement, 2)) : nil
                let imagePath = sqlite3_column_text(statement, 3) != nil ? String(cString: sqlite3_column_text(statement, 3)) : nil
                let status = String(cString: sqlite3_column_text(statement, 4))
                
                equipment.append((id: id, name: name, description: description, imagePath: imagePath, status: status))
            }
        }
        sqlite3_finalize(statement)
        return equipment
    }
} 