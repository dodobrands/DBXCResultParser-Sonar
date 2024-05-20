import Foundation

class DBLogger {
    static var verbose = false
    
    static func logDebug(_ message: String) {
        guard verbose else { return }
        print(message)
    }
    
    static func logInfo(_ message: String) {
        print(message)
    }
    
    static func logWarning(_ message: String) {
        // Use ANSI escape codes for colored output in terminals that support it
        // Yellow color for warnings: \u{001B}[33m
        // Reset colors: \u{001B}[0m
        print("\u{001B}[33mWarning:\u{001B}[0m \(message)")
    }
}
