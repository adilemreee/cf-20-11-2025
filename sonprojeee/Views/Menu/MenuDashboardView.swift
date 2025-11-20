import SwiftUI

struct MenuDashboardView: View {
    @ObservedObject var manager: TunnelManager
    
    var activeTunnelsCount: Int {
        manager.tunnels.filter { $0.status == .running }.count + 
        manager.quickTunnels.filter { $0.publicURL != nil }.count
    }
    
    var errorCount: Int {
        manager.tunnels.filter { $0.status == .error }.count +
        manager.quickTunnels.filter { $0.lastError != nil }.count
    }
    
    var isCloudflaredInstalled: Bool {
        let path = manager.cloudflaredExecutablePath
        return !path.isEmpty && FileManager.default.fileExists(atPath: path)
    }
    
    var isHealthy: Bool {
        isCloudflaredInstalled && errorCount == 0
    }
    
    var statusText: String {
        if !isCloudflaredInstalled { return "Cloudflared Eksik" }
        if errorCount > 0 { return "Dikkat Gerekiyor" }
        return "Sistem Normal"
    }
    
    var statusColor: Color {
        if !isCloudflaredInstalled || errorCount > 0 { return .red }
        return .secondary
    }
    
    var statusIcon: String {
        if !isCloudflaredInstalled { return "cloud.slash.fill" }
        if errorCount > 0 { return "exclamationmark.triangle" }
        return "checkmark"
    }
    
    var statusIconColor: Color {
        if !isCloudflaredInstalled || errorCount > 0 { return .red }
        return .green
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header Row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cloudflared")
                        .font(.system(size: 14, weight: .bold))
                    Text(statusText)
                        .font(.system(size: 11))
                        .foregroundColor(statusColor)
                }
                
                Spacer()
                
                // Status Icon
                ZStack {
                    Circle()
                        .fill(statusIconColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(statusIconColor)
                }
            }
            
            // Stats Row
            HStack(spacing: 0) {
                StatItem(value: "\(activeTunnelsCount)", label: "Aktif", color: .blue)
                Divider().frame(height: 24)
                StatItem(value: "\(manager.tunnels.count)", label: "Toplam", color: .secondary)
                Divider().frame(height: 24)
                StatItem(value: "\(errorCount)", label: "Hata", color: errorCount > 0 ? .red : .secondary)
            }
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(12)
        .frame(width: 240)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
