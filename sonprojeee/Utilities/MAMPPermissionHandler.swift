import Foundation
import AppKit

// MARK: - MAMP Permission Handler

class MAMPPermissionHandler {
    static let shared = MAMPPermissionHandler()
    
    private init() {}
    
    /// Check if MAMP files are writable
    func checkMAMPPermissions(vhostPath: String, httpdPath: String) -> (canWrite: Bool, errors: [TunnelError]) {
        var errors: [TunnelError] = []
        let fileManager = FileManager.default
        
        // Check vhost file
        if !fileManager.fileExists(atPath: vhostPath) {
            errors.append(.mampFileNotFound(path: vhostPath))
        } else if !fileManager.isWritableFile(atPath: vhostPath) {
            errors.append(.mampPermissionDenied(file: vhostPath))
        }
        
        // Check httpd.conf
        if !fileManager.fileExists(atPath: httpdPath) {
            errors.append(.mampFileNotFound(path: httpdPath))
        } else if !fileManager.isWritableFile(atPath: httpdPath) {
            errors.append(.mampPermissionDenied(file: httpdPath))
        }
        
        return (errors.isEmpty, errors)
    }
    
    /// Request admin privileges to fix MAMP file permissions
    func requestAdminPrivileges(for filePaths: [String]) -> Bool {
        let filePathsString = filePaths.map { "'\($0)'" }.joined(separator: " ")
        let script = """
        do shell script "chmod 644 \(filePathsString)" with administrator privileges
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            return error == nil
        }
        return false
    }
    
    /// Show manual configuration instructions
    func showManualConfigInstructions(config: String, filePath: String) {
        let alert = NSAlert()
        alert.messageText = "Manuel Yapılandırma Gerekli"
        alert.informativeText = """
        MAMP dosyalarına otomatik yazma başarısız oldu.
        
        Yapılandırma panoya kopyalandı.
        
        Manuel Adımlar:
        1. Terminal'i açın
        2. Şu komutu çalıştırın:
           sudo nano \(filePath)
        3. Dosya sonuna gidin (Ctrl+End)
        4. Panodaki içeriği yapıştırın (Cmd+V)
        5. Kaydedin (Ctrl+O, Enter, Ctrl+X)
        6. MAMP'ı yeniden başlatın
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("Kopyalandı, Tamam", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Terminal'i Aç", comment: ""))
        
        let response = alert.runModal()
        
        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(config, forType: .string)
        
        // Open Terminal if requested
        if response == .alertSecondButtonReturn {
            let terminalURL = URL(fileURLWithPath: "/Applications/Utilities/Terminal.app")
            NSWorkspace.shared.open(terminalURL)
        }
    }
}
