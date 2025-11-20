import Foundation
import AppKit

// TunnelError moved to TunnelError.swift

// MARK: - Error Handler

class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    // Enhanced error presentation
    func handle(_ error: Error, context: String = "", showAlert: Bool = true) {
        let errorMessage = formatError(error, context: context)
        print("❌ \(context): \(errorMessage)")
        
        if showAlert {
            DispatchQueue.main.async {
                self.showErrorAlert(message: errorMessage)
            }
        }
        
        // Send notification
        NotificationCenter.default.post(
            name: .sendUserNotification,
            object: nil,
            userInfo: [
                "title": "Hata",
                "message": errorMessage
            ]
        )
    }
    
    private func formatError(_ error: Error, context: String) -> String {
        var message = ""
        
        if !context.isEmpty {
            message += "📍 \(context)\n\n"
        }
        
        if let tunnelError = error as? TunnelError {
            message += "❌ \(tunnelError.localizedDescription)\n\n"
            if let suggestion = tunnelError.recoverySuggestion {
                message += "💡 \(suggestion)"
            }
        } else {
            message += "❌ \(error.localizedDescription)"
        }
        
        return message
    }
    
    func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Hata Oluştu"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Tamam")
        
        // Check if there's a key window
        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
    
    func showInfoAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Tamam")
        
        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}

// PortChecker moved to PortChecker.swift

// MAMPPermissionHandler moved to MAMPPermissionHandler.swift
