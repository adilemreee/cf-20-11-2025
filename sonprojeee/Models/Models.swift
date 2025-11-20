import Foundation // For UUID, pid_t

// MARK: - History Models

// Notification history entry
struct NotificationHistoryEntry: Identifiable, Codable {
    let id: UUID
    let title: String
    let body: String?
    let timestamp: Date
    let type: NotificationType
    let tunnelName: String?
    
    enum NotificationType: String, Codable {
        case info = "Bilgi"
        case success = "Başarılı"
        case warning = "Uyarı"
        case error = "Hata"
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .info: return "blue"
            case .success: return "green"
            case .warning: return "orange"
            case .error: return "red"
            }
        }
    }
    
    init(id: UUID = UUID(), title: String, body: String? = nil, type: NotificationType, tunnelName: String? = nil) {
        self.id = id
        self.title = title
        self.body = body
        self.timestamp = Date()
        self.type = type
        self.tunnelName = tunnelName
    }
}

// Error log entry
struct ErrorLogEntry: Identifiable, Codable {
    let id: UUID
    let tunnelName: String
    let errorMessage: String
    let errorCode: Int?
    let timestamp: Date
    let source: ErrorSource
    
    enum ErrorSource: String, Codable {
        case managed = "Yönetilen Tünel"
        case quick = "Hızlı Tünel"
        case system = "Sistem"
        case cloudflared = "Cloudflared"
        case mamp = "MAMP"
    }
    
    init(id: UUID = UUID(), tunnelName: String, errorMessage: String, errorCode: Int? = nil, source: ErrorSource) {
        self.id = id
        self.tunnelName = tunnelName
        self.errorMessage = errorMessage
        self.errorCode = errorCode
        self.timestamp = Date()
        self.source = source
    }
}

// General log entry
struct LogEntry: Identifiable, Codable {
    let id: UUID
    let message: String
    let timestamp: Date
    let level: LogLevel
    let category: String
    
    enum LogLevel: String, Codable {
        case debug = "Debug"
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
        case critical = "Critical"
        
        var icon: String {
            switch self {
            case .debug: return "ant.fill"
            case .info: return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.octagon"
            case .critical: return "flame.fill"
            }
        }
        
        var color: String {
            switch self {
            case .debug: return "gray"
            case .info: return "blue"
            case .warning: return "orange"
            case .error: return "red"
            case .critical: return "purple"
            }
        }
    }
    
    init(id: UUID = UUID(), message: String, level: LogLevel, category: String = "General") {
        self.id = id
        self.message = message
        self.timestamp = Date()
        self.level = level
        self.category = category
    }
}

// MARK: - Tunnel Models

// Represents the possible states of a tunnel
enum TunnelStatus: String, CaseIterable {
    case running = "Çalışıyor"
    case stopped = "Durduruldu"
    case starting = "Başlatılıyor..."
    case stopping = "Durduruluyor..."
    case error = "Hata"

    var displayName: String {
        return self.rawValue
    }
}

// Represents a tunnel managed via a configuration file (~/.cloudflared)
struct TunnelInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String           // Config file name without extension OR Tunnel Name from cloudflared
    let configPath: String?    // Path to YML config file (might be nil for newly created tunnels before config exists)
    var status: TunnelStatus = .stopped
    var processIdentifier: pid_t? // PID of the running process (only for tunnels run via config)
    var lastError: String?        // Store last error message if any
    var isManaged: Bool = true   // True if associated with a config file found in ~/.cloudflared
    var uuidFromConfig: String? // Store UUID parsed from config if available
    var port: Int?             // Port number used by this tunnel (parsed from config)
    
    // Helper computed property
    var isRunning: Bool {
        return status == .running
    }
}

// Represents a temporary "quick tunnel" created via a URL
struct QuickTunnelData: Identifiable, Equatable { // Identifiable is enough
    let id: UUID // Unique ID for tracking this specific instance
    let process: Process // Reference to the running process
    var publicURL: String? // Initially nil, found by parsing output
    let localURL: String   // The local URL being tunneled (e.g., http://localhost:8000)
    var processIdentifier: pid_t? // Keep track of PID too
    var lastError: String? // Store errors for quick tunnels too
    var port: Int { // Computed property to extract port from localURL
        if let portString = localURL.split(separator: ":").last,
           let portInt = Int(portString) {
            return portInt
        }
        return 80 // Default HTTP port
    }
    var isRunning: Bool { // Helper property
        return process.isRunning
    }
    
    init(id: UUID, process: Process, publicURL: String? = nil, localURL: String, processIdentifier: pid_t? = nil, lastError: String? = nil) {
        self.id = id
        self.process = process
        self.publicURL = publicURL
        self.localURL = localURL
        self.processIdentifier = processIdentifier
        self.lastError = lastError
    }
    
    static func == (lhs: QuickTunnelData, rhs: QuickTunnelData) -> Bool {
        return lhs.id == rhs.id &&
               lhs.publicURL == rhs.publicURL &&
               lhs.localURL == rhs.localURL &&
               lhs.isRunning == rhs.isRunning &&
               lhs.lastError == rhs.lastError
    }
}

