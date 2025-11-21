import SwiftUI
import AppKit

struct QuickTunnelPreset: Identifiable, Codable, Equatable {
    static let customID = "preset-custom"
    
    let id: String
    var name: String
    var url: String
    var details: String
    var isBuiltIn: Bool
    var isCustomEntry: Bool
    
    init(id: String = UUID().uuidString, name: String, url: String, details: String, isBuiltIn: Bool = false, isCustomEntry: Bool = false) {
        self.id = id
        self.name = name
        self.url = url
        self.details = details
        self.isBuiltIn = isBuiltIn
        self.isCustomEntry = isCustomEntry
    }
}

// Modern Alert View for Quick Tunnel
struct QuickTunnelAlertView: View {
    let title: String
    let message: String
    let type: AlertType
    let action: () -> Void
    
    @State private var isAnimating = false
    
    enum AlertType {
        case success, error, info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .purple
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: type.icon)
                .font(.system(size: 40))
                .foregroundColor(type.color)
                .symbolEffect(.bounce, options: .repeating, value: isAnimating)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Button(action: action) {
                Text(NSLocalizedString("Tamam", comment: ""))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 120, height: 36)
                    .background(type.color)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(24)
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct QuickTunnelView: View {
    @EnvironmentObject var tunnelManager: TunnelManager
    @Environment(\.dismiss) var dismiss

    // Form State
    @State private var localURL: String = "http://localhost:3000"
    @State private var selectedPreset: String = QuickTunnelPreset.customID
    
    // Preset management
    private let defaultPresets: [QuickTunnelPreset] = [
        QuickTunnelPreset(id: QuickTunnelPreset.customID, name: NSLocalizedString("Özel", comment: ""), url: "", details: NSLocalizedString("Özel URL girin", comment: ""), isBuiltIn: true, isCustomEntry: true),
        QuickTunnelPreset(id: "preset-react", name: "React", url: "http://localhost:3000", details: "React Development Server", isBuiltIn: true),
        QuickTunnelPreset(id: "preset-vue", name: "Vue.js", url: "http://localhost:8080", details: "Vue.js Development Server", isBuiltIn: true),
        QuickTunnelPreset(id: "preset-angular", name: "Angular", url: "http://localhost:4200", details: "Angular Development Server", isBuiltIn: true),
        QuickTunnelPreset(id: "preset-nextjs", name: "Next.js", url: "http://localhost:3000", details: "Next.js Development Server", isBuiltIn: true),
        QuickTunnelPreset(id: "preset-vite", name: "Vite", url: "http://localhost:5173", details: "Vite Development Server", isBuiltIn: true),
        QuickTunnelPreset(id: "preset-express", name: "Express.js", url: "http://localhost:8000", details: "Express.js Server", isBuiltIn: true),
        QuickTunnelPreset(id: "preset-django", name: "Django", url: "http://localhost:8000", details: "Django Development Server", isBuiltIn: true),
        QuickTunnelPreset(id: "preset-flask", name: "Flask", url: "http://localhost:5000", details: "Flask Development Server", isBuiltIn: true),
        QuickTunnelPreset(id: "preset-mamp", name: "MAMP", url: "http://localhost:8888", details: "MAMP Apache Server", isBuiltIn: true),
        QuickTunnelPreset(id: "preset-xampp", name: "XAMPP", url: "http://localhost:80", details: "XAMPP Apache Server", isBuiltIn: true),
        QuickTunnelPreset(id: "preset-generic", name: "Localhost", url: "http://localhost:8080", details: "Generic Local Server", isBuiltIn: true)
    ]
    private let userPresetsKey = "quickTunnelUserPresets"
    @State private var userPresets: [QuickTunnelPreset] = []
    @State private var newPresetName: String = ""
    @State private var newPresetURL: String = ""
    @State private var newPresetDetails: String = ""
    @State private var presetMessage: String?
    @State private var presetError: String?
    
    // UI State
    @State private var isStarting: Bool = false
    @State private var startingStatus: String = ""
    @State private var activeTunnelID: UUID?
    @State private var activeTunnelURL: String?
    @State private var quickTunnelError: String?
    
    // Modern alert state
    @State private var showCustomAlert: Bool = false
    @State private var customAlertTitle: String = ""
    @State private var customAlertMessage: String = ""
    @State private var customAlertType: QuickTunnelAlertView.AlertType = .info
    @State private var customAlertAction: (() -> Void)?
    
    // Animation states
    @State private var headerOffset: CGFloat = -50
    @State private var contentOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.8

    // Computed Properties
    private var sortedUserPresets: [QuickTunnelPreset] {
        userPresets.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    private var allPresets: [QuickTunnelPreset] {
        defaultPresets + sortedUserPresets
    }
    
    var selectedPresetData: QuickTunnelPreset? {
        allPresets.first { $0.id == selectedPreset }
    }
    
    private var canAddPreset: Bool {
        let trimmedName = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = newPresetURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedURL.isEmpty else { return false }
        guard let candidateURL = URL(string: trimmedURL), let scheme = candidateURL.scheme, let host = candidateURL.host, !scheme.isEmpty, !host.isEmpty else {
            return false
        }
        let duplicate = (defaultPresets + userPresets).contains { $0.url.caseInsensitiveCompare(trimmedURL) == .orderedSame || $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
        return !duplicate
    }
    
    private var shouldShowStatusCard: Bool {
        isStarting || (activeTunnelID != nil && activeTunnelURL == nil && quickTunnelError == nil)
    }
    
    var isFormValid: Bool {
        guard !localURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let url = URL(string: localURL.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return url.scheme != nil && url.host != nil
    }

    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(
                colors: [
                    Color(.windowBackgroundColor),
                    Color(.windowBackgroundColor).opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Modern Header
                modernHeader
                    .offset(y: headerOffset)
                    .opacity(contentOpacity)

                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Preset Selection Card
                        modernPresetSelectionCard
                        
                        // URL Input Card
                        modernURLInputCard
                        
                        // Info Card
                        modernInfoCard
                        
                        if shouldShowStatusCard {
                            modernStatusCard
                        }
                        
                        if let url = activeTunnelURL {
                            quickTunnelURLCard(url: url)
                        } else if let error = quickTunnelError {
                            quickTunnelErrorCard(message: error)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .opacity(contentOpacity)

                // Modern Action Bar
                modernActionBar
                    .scaleEffect(buttonScale)
                    .opacity(contentOpacity)
            }
        }
        .frame(width: 520, height: 460)
        .onAppear {
            setupInitialValues()
            animateEntry()
        }
        .overlay {
            if showCustomAlert {
                modernAlertOverlay
            }
        }
        .onReceive(tunnelManager.$quickTunnels) { tunnels in
            handleQuickTunnelUpdates(tunnels)
        }
    }

    // MARK: - Modern UI Components
    
    private var modernHeader: some View {
        VStack(spacing: 12) {
            HStack {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("Hızlı Tünel Başlat", comment: ""))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(NSLocalizedString("Yerel sunucunuzu hızlıca internete açın", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Progress indicator
            if isStarting {
                ProgressView(value: 0.5)
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                    .scaleEffect(y: 0.5)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    private var modernPresetSelectionCard: some View {
        QuickTunnelCard(title: NSLocalizedString("Hızlı Seçim", comment: ""), icon: "list.bullet") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Yaygın Sunucu Türleri", comment: ""))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("", selection: $selectedPreset) {
                        ForEach(allPresets) { preset in
                            Text(preset.isCustomEntry ? preset.details : "\(preset.name) (\(preset.url))")
                                .tag(preset.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedPreset) { _, newPreset in
                        if let presetData = allPresets.first(where: { $0.id == newPreset }),
                           !presetData.url.isEmpty {
                            localURL = presetData.url
                        }
                    }
                }
                
                if let preset = selectedPresetData, !preset.isCustomEntry {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.details)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Port: \(extractPort(from: preset.url))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !preset.isBuiltIn {
                            Button(role: .destructive) {
                                removeUserPreset(preset)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                            .help(NSLocalizedString("Preset'i sil", comment: ""))
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.purple.opacity(0.1))
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
                }
                
                if let message = presetMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.green)
                }
                if let error = presetError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(NSLocalizedString("Özel Preset Ekle", comment: ""))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    QuickTunnelTextField(
                        title: NSLocalizedString("Ad", comment: ""),
                        text: $newPresetName,
                        placeholder: "örn. Laravel",
                        icon: "tag"
                    )
                    
                    QuickTunnelTextField(
                        title: NSLocalizedString("URL", comment: ""),
                        text: $newPresetURL,
                        placeholder: "http://localhost:8000",
                        icon: "globe"
                    )
                    
                    QuickTunnelTextField(
                        title: NSLocalizedString("Açıklama", comment: ""),
                        text: $newPresetDetails,
                        placeholder: NSLocalizedString("Yerel geliştirme sunucusu", comment: ""),
                        icon: "info.circle"
                    )
                    
                    Button(NSLocalizedString("Preset Ekle", comment: "")) {
                        addUserPreset()
                    }
                    .buttonStyle(QuickTunnelPrimaryButtonStyle())
                    .disabled(!canAddPreset)
                }
            }
        }
    }
    
    private var modernURLInputCard: some View {
        QuickTunnelCard(title: NSLocalizedString("URL Yapılandırması", comment: ""), icon: "network") {
            VStack(spacing: 16) {
                QuickTunnelTextField(
                    title: NSLocalizedString("Yerel URL", comment: ""),
                    text: $localURL,
                    placeholder: "http://localhost:3000",
                    icon: "globe"
                )
                
                // URL validation indicator
                HStack {
                    Image(systemName: isFormValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(isFormValid ? .green : .red)
                    
                    Text(isFormValid ? NSLocalizedString("Geçerli URL formatı", comment: "") : NSLocalizedString("Geçersiz URL formatı", comment: ""))
                        .font(.caption)
                        .foregroundColor(isFormValid ? .green : .red)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }
    
    private var modernInfoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("Nasıl Çalışır?", comment: ""))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(NSLocalizedString("Hızlı tüneller geçici URL'ler oluşturur ve sunucunuz kapandığında otomatik olarak sona erer. Kalıcı tüneller için 'Yönetilen Tünel' oluşturun.", comment: ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow.opacity(0.1))
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var modernStatusCard: some View {
        QuickTunnelCard(title: NSLocalizedString("Başlatma Durumu", comment: ""), icon: "gearshape.fill") {
            HStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(startingStatus.isEmpty ? NSLocalizedString("İşlem devam ediyor...", comment: "") : startingStatus)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(isStarting ? NSLocalizedString("cloudflared komutu hazırlanıyor...", comment: "") : NSLocalizedString("URL hazır olduğunda bu sayfada göreceksiniz.", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private var modernActionBar: some View {
        HStack(spacing: 16) {
            Button(NSLocalizedString("İptal", comment: "")) {
                if !isStarting {
                    withAnimation(.easeOut(duration: 0.3)) {
                        dismiss()
                    }
                }
            }
            .buttonStyle(QuickTunnelSecondaryButtonStyle())
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            if activeTunnelID != nil {
                Button(NSLocalizedString("Tüneli Durdur", comment: "")) {
                    stopActiveTunnel()
                }
                .buttonStyle(QuickTunnelSecondaryButtonStyle())
                .disabled(isStarting)
            }

            Button(action: startQuickTunnelProcess) {
                HStack(spacing: 8) {
                    if isStarting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "bolt.circle.fill")
                    }
                    Text(NSLocalizedString("Tüneli Başlat", comment: ""))
                }
            }
            .buttonStyle(QuickTunnelPrimaryButtonStyle())
            .disabled(isStarting || !isFormValid)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            Rectangle()
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
    }
    
    private var modernAlertOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showCustomAlert = false
                    }
                }
            
            QuickTunnelAlertView(
                title: customAlertTitle,
                message: customAlertMessage,
                type: customAlertType
            ) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showCustomAlert = false
                }
                customAlertAction?()
            }
        }
        .transition(.opacity.combined(with: .scale))
    }
    // MARK: - Helper Functions
    
    private func setupInitialValues() {
        // Set default based on most common development server
        if localURL.isEmpty {
            localURL = "http://localhost:3000"
        }
        selectedPreset = QuickTunnelPreset.customID
        loadUserPresets()
    }
    
    private func animateEntry() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            headerOffset = 0
            contentOpacity = 1
            buttonScale = 1
        }
    }
    
    private func extractPort(from urlString: String) -> String {
        guard let url = URL(string: urlString) else { return "N/A" }
        return url.port?.description ?? (url.scheme == "https" ? "443" : "80")
    }
    
    private func startQuickTunnelProcess() {
        guard isFormValid else {
            customAlertTitle = NSLocalizedString("Hata", comment: "")
            customAlertMessage = NSLocalizedString("Lütfen geçerli bir yerel URL girin.\n\nÖrnek: http://localhost:3000", comment: "")
            customAlertType = .error
            showCustomAlert = true
            return
        }
        
        let cleanURL = localURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        showCustomAlert = false
        quickTunnelError = nil
        activeTunnelURL = nil
        startingStatus = NSLocalizedString("Hızlı tünel başlatılıyor...", comment: "")
        isStarting = true
        
        tunnelManager.startQuickTunnel(localURL: cleanURL) { result in
            DispatchQueue.main.async {
                self.isStarting = false
                
                switch result {
                case .success(let tunnelID):
                    self.activeTunnelID = tunnelID
                    self.activeTunnelURL = nil
                    self.startingStatus = NSLocalizedString("URL hazırlanıyor...", comment: "")
                    self.presetMessage = nil
                    self.presetError = nil

                case .failure(let error):
                    self.customAlertTitle = NSLocalizedString("Hata", comment: "")
                    self.customAlertMessage = NSLocalizedString("Hızlı tünel başlatılamadı", comment: "") + ":\n\n\(error.localizedDescription)"
                    self.customAlertType = .error
                    self.showCustomAlert = true
                    self.startingStatus = NSLocalizedString("Hata oluştu.", comment: "")
                    self.activeTunnelID = nil
                    self.activeTunnelURL = nil
                }
            }
        }
    }
}

// MARK: - Modern UI Components for Quick Tunnel
extension QuickTunnelView {
    private func handleQuickTunnelUpdates(_ tunnels: [QuickTunnelData]) {
        guard let activeID = activeTunnelID else { return }
        if let active = tunnels.first(where: { $0.id == activeID }) {
            if let url = active.publicURL, url != activeTunnelURL {
                activeTunnelURL = url
                startingStatus = NSLocalizedString("Tünel hazır.", comment: "")
            }
            
            if let error = active.lastError, !error.isEmpty {
                quickTunnelError = error
            } else if active.lastError == nil {
                quickTunnelError = nil
            }
        } else {
            if activeTunnelURL == nil && quickTunnelError == nil {
                quickTunnelError = NSLocalizedString("Tünel beklenmedik şekilde sonlandı.", comment: "")
            }
            activeTunnelID = nil
            activeTunnelURL = nil
            isStarting = false
            startingStatus = ""
        }
    }
    
    private func loadUserPresets() {
        guard let data = UserDefaults.standard.data(forKey: userPresetsKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([QuickTunnelPreset].self, from: data)
            userPresets = decoded
        } catch {
            print("⚠️ Quick tunnel preset'leri okunamadı: \(error)")
            userPresets = []
        }
    }
    
    private func persistUserPresets() {
        do {
            let data = try JSONEncoder().encode(userPresets)
            UserDefaults.standard.set(data, forKey: userPresetsKey)
        } catch {
            print("⚠️ Quick tunnel preset'leri kaydedilemedi: \(error)")
        }
    }
    
    private func addUserPreset() {
        let name = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = newPresetURL.trimmingCharacters(in: .whitespacesAndNewlines)
        var details = newPresetDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canAddPreset else { return }
        if details.isEmpty { details = name }
        
        let preset = QuickTunnelPreset(name: name, url: url, details: details)
        userPresets.append(preset)
        persistUserPresets()
        selectedPreset = preset.id
        localURL = preset.url
        newPresetName = ""
        newPresetURL = ""
        newPresetDetails = ""
        presetMessage = "\"\(preset.name)\" " + NSLocalizedString("preset'i eklendi.", comment: "")
        presetError = nil
    }
    
    private func removeUserPreset(_ preset: QuickTunnelPreset) {
        guard !preset.isBuiltIn else { return }
        userPresets.removeAll { $0.id == preset.id }
        persistUserPresets()
        presetMessage = "\"\(preset.name)\" " + NSLocalizedString("preset'i silindi.", comment: "")
        presetError = nil
        if selectedPreset == preset.id {
            selectedPreset = QuickTunnelPreset.customID
        }
    }
    
    private func stopActiveTunnel() {
        guard let id = activeTunnelID else { return }
        tunnelManager.stopQuickTunnel(id: id)
        startingStatus = NSLocalizedString("Tünel durduruluyor...", comment: "")
        quickTunnelError = nil
    }
    
    private func copyURLToClipboard(_ url: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
    }
    
    private func openURL(_ url: String) {
        guard let urlInstance = URL(string: url) else { return }
        NSWorkspace.shared.open(urlInstance)
    }
    
    private func quickTunnelURLCard(url: String) -> some View {
        QuickTunnelCard(title: NSLocalizedString("Genel URL", comment: ""), icon: "link") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tünel çalışıyor")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(url)
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                
                HStack(spacing: 12) {
                    Button("Kopyala") { copyURLToClipboard(url) }
                        .buttonStyle(QuickTunnelSecondaryButtonStyle())
                    
                    Button("Tarayıcıda Aç") { openURL(url) }
                        .buttonStyle(QuickTunnelSecondaryButtonStyle())
                    
                    Spacer()
                    
                    Button("Tüneli Durdur") {
                        stopActiveTunnel()
                    }
                    .buttonStyle(QuickTunnelSecondaryButtonStyle())
                }
            }
        }
    }
    
    private func quickTunnelErrorCard(message: String) -> some View {
        QuickTunnelCard(title: NSLocalizedString("Tünel Hatası", comment: ""), icon: "exclamationmark.triangle.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Hızlı tünel başlatılamadı veya sonlandırıldı")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button("Tekrar Dene") {
                    quickTunnelError = nil
                    startQuickTunnelProcess()
                }
                .buttonStyle(QuickTunnelPrimaryButtonStyle())
            }
        }
    }
}

struct QuickTunnelCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
}

struct QuickTunnelTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(QuickTunnelTextFieldStyle())
            }
        }
    }
}

// MARK: - Quick Tunnel Specific Styles

struct QuickTunnelTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.textBackgroundColor))
                    .stroke(Color(.separatorColor), lineWidth: 1)
            )
    }
}

struct QuickTunnelPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [.purple, .purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct QuickTunnelSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
                    .stroke(Color(.separatorColor), lineWidth: 1)
            )
            .foregroundColor(.primary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    QuickTunnelView()
        .environmentObject(TunnelManager())
}
