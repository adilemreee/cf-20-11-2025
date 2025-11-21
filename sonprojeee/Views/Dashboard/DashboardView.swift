import SwiftUI
import AppKit

struct DashboardView: View {
    @EnvironmentObject var manager: TunnelManager
    @ObservedObject var historyManager = HistoryManager.shared
    
    let openSettingsAction: (() -> Void)?
    let openQuickTunnelAction: (() -> Void)?
    let openManagedTunnelAction: (() -> Void)?
    let openFileShareAction: (() -> Void)?
    
    // Time based greeting
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return NSLocalizedString("Günaydın", comment: "")
        case 12..<18: return NSLocalizedString("İyi Günler", comment: "")
        case 18..<22: return NSLocalizedString("İyi Akşamlar", comment: "")
        default: return NSLocalizedString("İyi Geceler", comment: "")
        }
    }

    init(openSettingsAction: (() -> Void)? = nil,
         openQuickTunnelAction: (() -> Void)? = nil,
         openManagedTunnelAction: (() -> Void)? = nil,
         openFileShareAction: (() -> Void)? = nil) {
        self.openSettingsAction = openSettingsAction
        self.openQuickTunnelAction = openQuickTunnelAction
        self.openManagedTunnelAction = openManagedTunnelAction
        self.openFileShareAction = openFileShareAction
    }

    private var managedTunnels: [TunnelInfo] { manager.tunnels.filter { $0.isManaged } }
    private var runningManagedTunnels: [TunnelInfo] { managedTunnels.filter { $0.status == .running } }
    private var runningManagedCount: Int { managedTunnels.filter { $0.status == .running }.count }
    private var totalManagedCount: Int { managedTunnels.count }
    private var quickTunnelCount: Int { manager.quickTunnels.count }
    private var runningQuickCount: Int { manager.quickTunnels.filter { $0.publicURL != nil }.count }
    private var errorCount: Int {
        manager.tunnels.filter { $0.status == .error }.count +
        manager.quickTunnels.filter { $0.lastError != nil }.count
    }
    
    private var systemStatus: (text: String, color: Color, icon: String) {
        if !FileManager.default.isExecutableFile(atPath: manager.cloudflaredExecutablePath) {
            return (NSLocalizedString("Cloudflared Eksik", comment: ""), .red, "exclamationmark.triangle.fill")
        } else if errorCount > 0 {
            return (NSLocalizedString("Dikkat Gerekiyor", comment: ""), .orange, "exclamationmark.triangle.fill")
        } else if runningManagedCount > 0 || runningQuickCount > 0 {
            return (NSLocalizedString("Sistem Aktif", comment: ""), .green, "checkmark.circle.fill")
        } else {
            return (NSLocalizedString("Hazır", comment: ""), .blue, "pause.circle.fill")
        }
    }

    var body: some View {
        ZStack {
            // Background
            Color(.windowBackgroundColor).ignoresSafeArea()
            
            // Ambient Gradient
            GeometryReader { proxy in
                Circle()
                    .fill(systemStatus.color.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(x: -100, y: -100)
                
                Circle()
                    .fill(Color.blue.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: proxy.size.width - 200, y: proxy.size.height - 200)
            }
            
            VStack(spacing: 24) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Grid
                        statsGrid
                        
                        HStack(alignment: .top, spacing: 24) {
                            // Left Column
                            VStack(spacing: 24) {
                                quickActionsCard
                                environmentCard
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Right Column
                            VStack(spacing: 24) {
                                recentActivityCard
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            }
        }
        .frame(minWidth: 850, minHeight: 600)
    }

    // MARK: - Components
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting),")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.secondary)
                Text(NSFullUserName())
                    .font(.system(size: 32, weight: .bold))
            }
            
            Spacer()
            
            // System Status Pill
            HStack(spacing: 8) {
                Image(systemName: systemStatus.icon)
                    .font(.title3)
                Text(systemStatus.text)
                    .font(.headline)
            }
            .foregroundColor(systemStatus.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(systemStatus.color.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(systemStatus.color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            statCard(
                title: NSLocalizedString("Yönetilen Tüneller", comment: ""),
                value: "\(runningManagedCount)",
                total: "/ \(totalManagedCount)",
                icon: "network",
                color: .blue
            )
            
            statCard(
                title: NSLocalizedString("Hızlı Tüneller", comment: ""),
                value: "\(runningQuickCount)",
                total: "/ \(quickTunnelCount)",
                icon: "bolt.fill",
                color: .purple
            )
            
            statCard(
                title: NSLocalizedString("Hatalar", comment: ""),
                value: "\(errorCount)",
                total: "",
                icon: "exclamationmark.triangle.fill",
                color: errorCount > 0 ? .red : .green
            )
        }
    }
    
    private func statCard(title: String, value: String, total: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                if total.isEmpty && value == "0" {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    Text(total)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Hızlı İşlemler", comment: ""))
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                actionButton(title: NSLocalizedString("Hızlı Tünel", comment: ""), icon: "bolt.fill", color: .purple) {
                    openQuickTunnel()
                }
                
                actionButton(title: NSLocalizedString("Yeni Tünel", comment: ""), icon: "plus", color: .blue) {
                    openManagedTunnelCreator()
                }
                
                actionButton(title: NSLocalizedString("Dosya Paylaş", comment: ""), icon: "folder.badge.gearshape", color: .orange) {
                    openFileShare()
                }
                
                actionButton(title: NSLocalizedString("Ayarlar", comment: ""), icon: "gearshape.fill", color: .gray) {
                    openSettings()
                }
                
                actionButton(title: NSLocalizedString("Tümünü Başlat", comment: ""), icon: "play.fill", color: .green) {
                    manager.startAllManagedTunnels()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private var environmentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sistem")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                envRow(label: "Cloudflared", value: "Kurulu", icon: "checkmark.circle.fill", color: .green)
                envRow(label: "MAMP", value: manager.mampBasePath.isEmpty ? "Ayarlanmadı" : "Bağlı", icon: "server.rack", color: .orange)
                envRow(label: "Kontrol Aralığı", value: "\(Int(manager.checkInterval)) sn", icon: "clock", color: .blue)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func envRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
        }
    }
    
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Son Aktiviteler")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Tümü") {
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.openHistoryWindowAction()
                    }
                }
                .font(.caption)
                .buttonStyle(.link)
            }
            
            if historyManager.notificationHistory.isEmpty {
                Text(NSLocalizedString("Henüz aktivite yok", comment: ""))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                let recentEntries = Array(historyManager.notificationHistory.prefix(5))
                ForEach(recentEntries) { entry in
                    activityRow(for: entry)
                    
                    if entry.id != recentEntries.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func activityRow(for entry: NotificationHistoryEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(entry.type == .error ? Color.red : Color.blue)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                if let body = entry.body {
                    Text(body)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Text(entry.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(Color(nsColor: .tertiaryLabelColor))
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Window Actions
private extension DashboardView {
    func openSettings() {
        guard let action = openSettingsAction else { return }
        action()
    }

    func openQuickTunnel() {
        guard let action = openQuickTunnelAction else { return }
        action()
    }

    func openManagedTunnelCreator() {
        guard let action = openManagedTunnelAction else { return }
        action()
    }
    
    func openFileShare() {
        guard let action = openFileShareAction else { return }
        action()
    }
}

#Preview {
    DashboardView()
        .environmentObject(TunnelManager())
}

