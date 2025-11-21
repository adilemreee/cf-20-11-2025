import Foundation
import Combine

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var notificationHistory: [NotificationHistoryEntry] = []
    @Published var errorLogs: [ErrorLogEntry] = []
    @Published var generalLogs: [LogEntry] = []
    
    private let maxNotifications = 100
    private let maxErrorLogs = 200
    private let maxGeneralLogs = 500
    
    private let notificationHistoryKey = "notificationHistory"
    private let errorLogsKey = "errorLogs"
    private let generalLogsKey = "generalLogs"
    
    private init() {
        loadHistory()
    }
    
    // MARK: - Notification History
    
    func addNotification(title: String, body: String? = nil, type: NotificationHistoryEntry.NotificationType, tunnelName: String? = nil) {
        let entry = NotificationHistoryEntry(title: title, body: body, type: type, tunnelName: tunnelName)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.notificationHistory.insert(entry, at: 0)
            
            // Keep only the latest entries
            if self.notificationHistory.count > self.maxNotifications {
                self.notificationHistory = Array(self.notificationHistory.prefix(self.maxNotifications))
            }
            
            self.saveNotificationHistory()
        }
    }
    
    func clearNotificationHistory() {
        DispatchQueue.main.async { [weak self] in
            self?.notificationHistory.removeAll()
            self?.saveNotificationHistory()
        }
    }
    
    // MARK: - Error Logs
    
    func addErrorLog(tunnelName: String, errorMessage: String, errorCode: Int? = nil, source: ErrorLogEntry.ErrorSource) {
        let entry = ErrorLogEntry(tunnelName: tunnelName, errorMessage: errorMessage, errorCode: errorCode, source: source)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.errorLogs.insert(entry, at: 0)
            
            // Keep only the latest entries
            if self.errorLogs.count > self.maxErrorLogs {
                self.errorLogs = Array(self.errorLogs.prefix(self.maxErrorLogs))
            }
            
            self.saveErrorLogs()
        }
    }
    
    func clearErrorLogs() {
        DispatchQueue.main.async { [weak self] in
            self?.errorLogs.removeAll()
            self?.saveErrorLogs()
        }
    }
    
    // MARK: - General Logs
    
    func log(_ message: String, level: LogEntry.LogLevel = .info, category: String = "General") {
        let entry = LogEntry(message: message, level: level, category: category)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.generalLogs.insert(entry, at: 0)
            
            // Keep only the latest entries
            if self.generalLogs.count > self.maxGeneralLogs {
                self.generalLogs = Array(self.generalLogs.prefix(self.maxGeneralLogs))
            }
            
            self.saveGeneralLogs()
        }
        
        // Also print to console for debugging
        print("[\(level.rawValue)] [\(category)] \(message)")
    }
    
    func clearGeneralLogs() {
        DispatchQueue.main.async { [weak self] in
            self?.generalLogs.removeAll()
            self?.saveGeneralLogs()
        }
    }
    
    // MARK: - Persistence
    
    private func saveNotificationHistory() {
        if let encoded = try? JSONEncoder().encode(notificationHistory) {
            UserDefaults.standard.set(encoded, forKey: notificationHistoryKey)
        }
    }
    
    private func saveErrorLogs() {
        if let encoded = try? JSONEncoder().encode(errorLogs) {
            UserDefaults.standard.set(encoded, forKey: errorLogsKey)
        }
    }
    
    private func saveGeneralLogs() {
        if let encoded = try? JSONEncoder().encode(generalLogs) {
            UserDefaults.standard.set(encoded, forKey: generalLogsKey)
        }
    }
    
    private func loadHistory() {
        // Load notification history
        if let data = UserDefaults.standard.data(forKey: notificationHistoryKey),
           let decoded = try? JSONDecoder().decode([NotificationHistoryEntry].self, from: data) {
            notificationHistory = decoded
        }
        
        // Load error logs
        if let data = UserDefaults.standard.data(forKey: errorLogsKey),
           let decoded = try? JSONDecoder().decode([ErrorLogEntry].self, from: data) {
            errorLogs = decoded
        }
        
        // Load general logs
        if let data = UserDefaults.standard.data(forKey: generalLogsKey),
           let decoded = try? JSONDecoder().decode([LogEntry].self, from: data) {
            generalLogs = decoded
        }
    }
    
    // MARK: - Export
    
    func exportNotificationHistory() -> String {
        var output = "=== Bildirim Geçmişi ===\n"
        output += "Oluşturulma: \(Date())\n\n"
        
        for entry in notificationHistory {
            output += "[\(formatDate(entry.timestamp))] [\(entry.type.rawValue)]\n"
            output += "Başlık: \(entry.title)\n"
            if let body = entry.body {
                output += "Mesaj: \(body)\n"
            }
            if let tunnel = entry.tunnelName {
                output += "Tünel: \(tunnel)\n"
            }
            output += "\n"
        }
        
        return output
    }
    
    func exportErrorLogs() -> String {
        var output = "=== " + NSLocalizedString("Hata Geçmişi", comment: "") + " ===\n"
        output += "Oluşturulma: \(Date())\n\n"
        
        for entry in errorLogs {
            output += "[\(formatDate(entry.timestamp))] [\(entry.source.rawValue)]\n"
            output += "Tünel: \(entry.tunnelName)\n"
            output += NSLocalizedString("Hata: ", comment: "") + "\(entry.errorMessage)\n"
            if let code = entry.errorCode {
                output += "Kod: \(code)\n"
            }
            output += "\n"
        }
        
        return output
    }
    
    func exportGeneralLogs() -> String {
        var output = "=== Genel Log Geçmişi ===\n"
        output += "Oluşturulma: \(Date())\n\n"
        
        for entry in generalLogs {
            output += "[\(formatDate(entry.timestamp))] [\(entry.level.rawValue)] [\(entry.category)]\n"
            output += "\(entry.message)\n\n"
        }
        
        return output
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        return formatter.string(from: date)
    }
}
