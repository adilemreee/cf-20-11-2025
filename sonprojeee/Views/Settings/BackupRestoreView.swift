import SwiftUI

struct BackupRestoreView: View {
    @EnvironmentObject var manager: TunnelManager
    @StateObject private var backupManager = BackupManager.shared
    
    @State private var showingCreateBackup = false
    @State private var showingRestoreAlert = false
    @State private var selectedBackup: BackupFile?
    @State private var restoreSettings = true
    @State private var restoreTunnels = true
    @State private var showingDeleteAlert = false
    @State private var backupToDelete: BackupFile?
    @State private var showingExportPanel = false
    @State private var showingImportPanel = false
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var autoBackupIntervalHours = 24.0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Quick Actions
                quickActionsSection
                
                // Auto Backup Settings
                autoBackupSection
                
                // Available Backups
                backupsListSection
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(NSLocalizedString("Backup Geri Yükle", comment: ""), isPresented: $showingRestoreAlert) {
            Button(NSLocalizedString("İptal", comment: ""), role: .cancel) { }
            Button(NSLocalizedString("Geri Yükle", comment: ""), role: .destructive) {
                if let backup = selectedBackup {
                    restoreBackupAction(backup)
                }
            }
        } message: {
            Text(NSLocalizedString("Bu backup'ı geri yüklemek istediğinizden emin misiniz? Mevcut ayarlarınız değiştirilecek.", comment: ""))
        }
        .alert(NSLocalizedString("Backup Sil", comment: ""), isPresented: $showingDeleteAlert) {
            Button(NSLocalizedString("İptal", comment: ""), role: .cancel) { }
            Button(NSLocalizedString("Sil", comment: ""), role: .destructive) {
                if let backup = backupToDelete {
                    deleteBackupAction(backup)
                }
            }
        } message: {
            Text(NSLocalizedString("Bu backup'ı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.", comment: ""))
        }
        .alert(NSLocalizedString("Bilgi", comment: ""), isPresented: $showingAlert) {
            Button(NSLocalizedString("Tamam", comment: ""), role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .fileImporter(
            isPresented: $showingImportPanel,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .onAppear {
            autoBackupIntervalHours = backupManager.autoBackupInterval / 3600
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "externaldrive.badge.timemachine")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("Yedekleme & Geri Yükleme", comment: ""))
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(NSLocalizedString("Tünel yapılandırmalarınızı ve ayarlarınızı yedekleyin", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let lastBackup = backupManager.lastBackupDate {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(NSLocalizedString("Son yedekleme: ", comment: ""))\(formattedDate(lastBackup))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Hızlı İşlemler", comment: ""))
                .font(.headline)
                .padding(.horizontal, 16)
            
            HStack(spacing: 12) {
                // Create Backup Button
                Button(action: createBackupAction) {
                    HStack {
                        if backupManager.isCreatingBackup {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("Yeni Yedek", comment: ""))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(NSLocalizedString("Mevcut durumu kaydet", comment: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .disabled(backupManager.isCreatingBackup)
                
                // Import Backup Button
                Button(action: { showingImportPanel = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 18))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("İçe Aktar", comment: ""))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(NSLocalizedString("Backup dosyası yükle", comment: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    // MARK: - Auto Backup Section
    
    private var autoBackupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Otomatik Yedekleme", comment: ""))
                .font(.headline)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: Binding(
                    get: { backupManager.autoBackupEnabled },
                    set: { backupManager.toggleAutoBackup(enabled: $0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("Otomatik Yedekleme", comment: ""))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(NSLocalizedString("Belirtilen aralıklarla otomatik yedek oluştur", comment: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
                
                if backupManager.autoBackupEnabled {
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("Yedekleme Aralığı: ", comment: "") + "\(Int(autoBackupIntervalHours)) " + NSLocalizedString(" saat", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Slider(
                            value: $autoBackupIntervalHours,
                            in: 1...168,
                            step: 1,
                            onEditingChanged: { editing in
                                if !editing {
                                    backupManager.setAutoBackupInterval(autoBackupIntervalHours * 3600)
                                }
                            }
                        )
                        
                        HStack {
                            Text(NSLocalizedString("1 saat", comment: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(NSLocalizedString("1 hafta", comment: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.textBackgroundColor).opacity(0.5))
            )
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    // MARK: - Backups List
    
    private var backupsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("Yedekler", comment: ""))
                    .font(.headline)
                
                Spacer()
                
                Text("\(backupManager.availableBackups.count) \(NSLocalizedString("yedek", comment: ""))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            
            if backupManager.availableBackups.isEmpty {
                emptyBackupsView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(backupManager.availableBackups) { backup in
                        backupRow(backup)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private var emptyBackupsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(NSLocalizedString("Henüz yedek bulunmuyor", comment: ""))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(NSLocalizedString("Yukarıdaki 'Yeni Yedek' butonuna tıklayarak ilk yedeğinizi oluşturun", comment: ""))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private func backupRow(_ backup: BackupFile) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "doc.zipper")
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(backup.filename)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label("\(backup.tunnelCount) \(NSLocalizedString("tünel", comment: ""))", systemImage: "network")
                    Label(backup.formattedSize, systemImage: "doc")
                    Label(backup.formattedDate, systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 6) {
                // Restore Button
                Button(action: {
                    selectedBackup = backup
                    showingRestoreAlert = true
                }) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                .help("Geri Yükle")
                
                // Export Button
                Button(action: {
                    exportBackupAction(backup)
                }) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Dışa Aktar")
                
                // Delete Button
                Button(action: {
                    backupToDelete = backup
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Sil")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Actions
    
    private func createBackupAction() {
        Task {
            do {
                _ = try await backupManager.createBackup(manager: manager)
            } catch {
                alertMessage = "Backup oluşturulamadı: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func restoreBackupAction(_ backup: BackupFile) {
        Task {
            do {
                try await backupManager.restoreBackup(
                    backupFile: backup,
                    manager: manager,
                    restoreSettings: restoreSettings,
                    restoreTunnels: restoreTunnels
                )
                alertMessage = "Backup başarıyla geri yüklendi!"
                showingAlert = true
            } catch {
                alertMessage = "Backup geri yüklenemedi: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func deleteBackupAction(_ backup: BackupFile) {
        do {
            try backupManager.deleteBackup(backup)
        } catch {
            alertMessage = "Backup silinemedi: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func exportBackupAction(_ backup: BackupFile) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = backup.filename
        savePanel.allowedContentTypes = [.json]
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            
            do {
                let sourceURL = try backupManager.exportBackup(backup)
                try FileManager.default.copyItem(at: sourceURL, to: url)
                alertMessage = "Backup başarıyla dışa aktarıldı!"
                showingAlert = true
            } catch {
                alertMessage = "Backup dışa aktarılamadı: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                _ = try backupManager.importBackup(from: url)
                alertMessage = "Backup başarıyla içe aktarıldı!"
                showingAlert = true
            } catch {
                alertMessage = "Backup içe aktarılamadı: \(error.localizedDescription)"
                showingAlert = true
            }
            
        case .failure(let error):
            alertMessage = "Dosya seçilemedi: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    // MARK: - Utilities
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct BackupRestoreView_Previews: PreviewProvider {
    static var previews: some View {
        BackupRestoreView()
            .environmentObject(TunnelManager())
            .frame(width: 800, height: 600)
    }
}
