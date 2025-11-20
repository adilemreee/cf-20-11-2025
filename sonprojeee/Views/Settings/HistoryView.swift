import SwiftUI

struct HistoryView: View {
    @StateObject private var historyManager = HistoryManager.shared
    @AppStorage("accentColor") private var accentColorName = "blue"
    @State private var selectedTab: HistoryTab = .notifications
    @State private var searchText = ""
    @State private var showExportSheet = false
    @State private var exportContent = ""
    
    enum HistoryTab: String, CaseIterable {
        case notifications = "Bildirimler"
        case errors = "Hatalar"
        case logs = "Loglar"
        
        var icon: String {
            switch self {
            case .notifications: return "bell.fill"
            case .errors: return "exclamationmark.triangle.fill"
            case .logs: return "doc.text.fill"
            }
        }
    }
    
    private let accentColors: [(name: String, color: Color)] = [
        ("blue", .blue), ("purple", .purple), ("pink", .pink),
        ("red", .red), ("orange", .orange), ("yellow", .yellow),
        ("green", .green), ("mint", .mint), ("teal", .teal), ("cyan", .cyan)
    ]
    
    private var currentAccentColor: Color {
        accentColors.first(where: { $0.name == accentColorName })?.color ?? .blue
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Actions & Tabs
            VStack(spacing: 16) {
                // Actions Row
                HStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: exportCurrent) {
                            Label("Dışa Aktar", systemImage: "square.and.arrow.up")
                                .font(.caption.bold())
                                .foregroundColor(currentAccentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(currentAccentColor.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: clearCurrent) {
                            Label("Temizle", systemImage: "trash")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Tab Selector & Search
                HStack(spacing: 16) {
                    // Tabs
                    HStack(spacing: 4) {
                        ForEach(HistoryTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.icon)
                                    Text(tab.rawValue)
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(selectedTab == tab ? .white : .secondary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background {
                                    if selectedTab == tab {
                                        Capsule()
                                            .fill(currentAccentColor)
                                            .matchedGeometryEffect(id: "TAB", in: namespace)
                                    } else {
                                        Capsule()
                                            .fill(Color.gray.opacity(0.1))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Spacer()
                    
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        TextField("Ara...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.subheadline)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .frame(width: 200)
                }
            }
            
            // Content
            contentView
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(content: exportContent)
        }
    }
    
    @Namespace private var namespace
    
    // MARK: - Content
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .notifications: notificationsView
        case .errors: errorsView
        case .logs: logsView
        }
    }
    
    private var notificationsView: some View {
        LazyVStack(spacing: 12) {
            if filteredNotifications.isEmpty {
                emptyStateView(
                    icon: "bell.slash",
                    title: searchText.isEmpty ? "Henüz bildirim yok" : "Eşleşen bildirim bulunamadı",
                    subtitle: searchText.isEmpty ? "Bildirimler burada görünecek" : nil
                )
            } else {
                ForEach(filteredNotifications) { entry in
                    NotificationRowView(entry: entry, accentColor: currentAccentColor)
                }
            }
        }
    }
    
    private var errorsView: some View {
        LazyVStack(spacing: 12) {
            if filteredErrors.isEmpty {
                emptyStateView(
                    icon: "checkmark.circle",
                    title: searchText.isEmpty ? "Henüz hata kaydı yok" : "Eşleşen hata bulunamadı",
                    subtitle: searchText.isEmpty ? "Harika! Hiç hata yok" : nil
                )
            } else {
                ForEach(filteredErrors) { entry in
                    ErrorRowView(entry: entry)
                }
            }
        }
    }
    
    private var logsView: some View {
        LazyVStack(spacing: 8) {
            if filteredLogs.isEmpty {
                emptyStateView(
                    icon: "doc.text",
                    title: searchText.isEmpty ? "Henüz log kaydı yok" : "Eşleşen log bulunamadı",
                    subtitle: searchText.isEmpty ? "Log kayıtları burada görünecek" : nil
                )
            } else {
                ForEach(filteredLogs) { entry in
                    LogRowView(entry: entry)
                }
            }
        }
    }
    
    private func emptyStateView(icon: String, title: String, subtitle: String?) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Filtering
    
    private var filteredNotifications: [NotificationHistoryEntry] {
        if searchText.isEmpty {
            return historyManager.notificationHistory
        }
        return historyManager.notificationHistory.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.body?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.tunnelName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private var filteredErrors: [ErrorLogEntry] {
        if searchText.isEmpty {
            return historyManager.errorLogs
        }
        return historyManager.errorLogs.filter {
            $0.tunnelName.localizedCaseInsensitiveContains(searchText) ||
            $0.errorMessage.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredLogs: [LogEntry] {
        if searchText.isEmpty {
            return historyManager.generalLogs
        }
        return historyManager.generalLogs.filter {
            $0.message.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Actions
    
    private func clearCurrent() {
        let alert = NSAlert()
        alert.messageText = "Geçmişi Temizle"
        alert.informativeText = "Seçili kategorideki tüm kayıtlar silinecek. Bu işlem geri alınamaz."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Temizle")
        alert.addButton(withTitle: "İptal")
        
        if alert.runModal() == .alertFirstButtonReturn {
            switch selectedTab {
            case .notifications: historyManager.clearNotificationHistory()
            case .errors: historyManager.clearErrorLogs()
            case .logs: historyManager.clearGeneralLogs()
            }
        }
    }
    
    private func exportCurrent() {
        switch selectedTab {
        case .notifications: exportContent = historyManager.exportNotificationHistory()
        case .errors: exportContent = historyManager.exportErrorLogs()
        case .logs: exportContent = historyManager.exportGeneralLogs()
        }
        showExportSheet = true
    }
}

// MARK: - Row Views

struct NotificationRowView: View {
    let entry: NotificationHistoryEntry
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: entry.type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(typeColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(formatDate(entry.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let body = entry.body {
                    Text(body)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let tunnel = entry.tunnelName {
                    HStack(spacing: 4) {
                        Image(systemName: "network")
                            .font(.caption2)
                        Text(tunnel)
                            .font(.caption2.bold())
                    }
                    .foregroundColor(accentColor)
                    .padding(.top, 2)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var typeColor: Color {
        switch entry.type.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ErrorRowView: View {
    let entry: ErrorLogEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.tunnelName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(entry.source.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDate(entry.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(entry.errorMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let code = entry.errorCode {
                    Text("Hata Kodu: \(code)")
                        .font(.caption2.bold())
                        .foregroundColor(.red)
                        .padding(.top, 2)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct LogRowView: View {
    let entry: LogEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Level indicator
            Circle()
                .fill(levelColor)
                .frame(width: 8, height: 8)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.level.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(levelColor)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(entry.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(entry.timestamp))
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                
                Text(entry.message)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var levelColor: Color {
        switch entry.level.color {
        case "gray": return .gray
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        default: return .gray
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Export Sheet

struct ExportSheet: View {
    let content: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Dışa Aktar")
                    .font(.headline)
                
                Spacer()
                
                Button("Kapat") { dismiss() }
            }
            .padding()
            
            ScrollView {
                Text(content)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
            
            HStack(spacing: 12) {
                Button("Panoya Kopyala") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                }
                
                Button("Dosyaya Kaydet") {
                    saveToFile()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 600, height: 500)
        .padding()
    }
    
    private func saveToFile() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "history-\(Date().timeIntervalSince1970).txt"
        panel.allowedContentTypes = [.plainText]
        
        if panel.runModal() == .OK, let url = panel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

#Preview {
    HistoryView()
}
