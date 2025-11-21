import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var manager: TunnelManager
    
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoStartTunnels") private var autoStartTunnels = false
    @AppStorage("autoStartMamp") private var autoStartMamp = false
    @AppStorage("minimizeToTray") private var minimizeToTray = true
    @AppStorage("showStatusInMenuBar") private var showStatusInMenuBar = true
    @AppStorage("accentColor") private var accentColorName = "blue"
    @AppStorage("pythonProjectPath") private var storedPythonProjectPath: String = ""
    
    @State private var tempCloudflaredPath: String = ""
    @State private var tempCloudflaredDirPath: String = ""
    @State private var tempMampPath: String = "/Applications/MAMP"
    @State private var tempMampSitesPath: String = ""
    @State private var tempMampApacheConfigPath: String = ""
    @State private var tempMampVHostConfPath: String = ""
    @State private var tempMampHttpdConfPath: String = ""
    @State private var tempPythonProjectPath: String = ""
    @State private var intervalString: String = ""
    @State private var isWorking: Bool = false
    @State private var launchAtLogin: Bool = false
    @State private var launchAtLoginLoading: Bool = false
    @State private var selectedTab: SettingsTab = .general
    @State private var hoveredButton: String? = nil
    @State private var hideFromDock: Bool = false
    
    enum SettingsTab: String, CaseIterable {
        case general = "general"
        case paths = "paths"
        case appearance = "appearance"
        case notifications = "notifications"
        case history = "history"
        case backup = "backup"
        case advanced = "advanced"
        case about = "about"
        
        var title: String {
            switch self {
            case .general: return NSLocalizedString("Genel", comment: "")
            case .paths: return NSLocalizedString("Yollar", comment: "")
            case .appearance: return NSLocalizedString("Görünüm", comment: "")
            case .notifications: return NSLocalizedString("Bildirimler", comment: "")
            case .history: return NSLocalizedString("Geçmiş", comment: "")
            case .backup: return NSLocalizedString("Yedekleme", comment: "")
            case .advanced: return NSLocalizedString("Gelişmiş", comment: "")
            case .about: return NSLocalizedString("Hakkında", comment: "")
            }
        }
        
        var icon: String {
            switch self {
            case .general: return "gear"
            case .paths: return "folder.badge.gearshape"
            case .appearance: return "paintbrush"
            case .notifications: return "bell"
            case .history: return "clock.arrow.circlepath"
            case .backup: return "externaldrive.badge.timemachine"
            case .advanced: return "wrench.and.screwdriver"
            case .about: return "info.circle"
            }
        }
    }
    
    private let accentColors: [(name: String, color: Color)] = [
        ("blue", .blue),
        ("purple", .purple),
        ("pink", .pink),
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green),
        ("mint", .mint),
        ("teal", .teal),
        ("cyan", .cyan)
    ]
    
    var currentAccentColor: Color {
        accentColors.first(where: { $0.name == accentColorName })?.color ?? .blue
    }
    
    var body: some View {
        HStack(spacing: 24) {
            // Sidebar
            sidebarView
                .frame(width: 240)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            
            // Main Content
            mainContentView
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
        }
        .onChange(of: darkModeEnabled) { _, newValue in
            applyDarkMode(newValue)
        }
        .padding(24)
        .frame(width: 1000, height: 700)
        .background(modernBackground)
        .onAppear {
            applyDarkMode(darkModeEnabled)
            setupInitialValues()
        }
    }
    
    // MARK: - Modern Background
    private var modernBackground: some View {
        ZStack {
            // Base background
            Color(.windowBackgroundColor).ignoresSafeArea()
            
            // Ambient Gradient
            GeometryReader { proxy in
                Circle()
                    .fill(currentAccentColor.opacity(0.1))
                    .frame(width: 500, height: 500)
                    .blur(radius: 100)
                    .offset(x: -150, y: -150)
                
                Circle()
                    .fill(Color.blue.opacity(0.05))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: proxy.size.width - 200, y: proxy.size.height - 200)
                
                // Additional ambient light for settings
                Circle()
                    .fill(currentAccentColor.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 100, y: proxy.size.height / 2)
            }
        }
    }
    
    // MARK: - Sidebar
    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                // App icon placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [currentAccentColor, currentAccentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "cloud.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .shadow(color: currentAccentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 4) {
                    Text("Cloudflared Manager")
                        .font(.headline.bold())
                    Text("v6.5.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("2025")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            // Tab buttons
            VStack(spacing: 4) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    sidebarButton(for: tab)
                }
            }
            .padding(.horizontal, 12)
            
            Spacer()
            
            // Status indicator
            statusIndicatorView
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
        }
    }
    
    private func sidebarButton(for tab: SettingsTab) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                    .frame(width: 20)
                
                Text(tab.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                
                Spacer()
                
                if selectedTab == tab {
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background {
                if selectedTab == tab {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [currentAccentColor, currentAccentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: currentAccentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(hoveredButton == tab.rawValue ? Color.gray.opacity(0.1) : Color.clear)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(selectedTab == tab ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
        .onHover { isHovered in
            hoveredButton = isHovered ? tab.rawValue : nil
        }
    }
    
    private var statusIndicatorView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(FileManager.default.fileExists(atPath: tempCloudflaredPath) ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .shadow(color: FileManager.default.fileExists(atPath: tempCloudflaredPath) ? .green : .red, radius: 4)
                
                Text(FileManager.default.fileExists(atPath: tempCloudflaredPath) ? NSLocalizedString("Hazır", comment: "") : NSLocalizedString("Yapılandırma Gerekli", comment: ""))
                    .font(.caption.bold())
                    .foregroundColor(FileManager.default.fileExists(atPath: tempCloudflaredPath) ? .green : .red)
            }
            
            Button(action: { manager.checkCloudflaredExecutable() }) {
                Text(NSLocalizedString("Durumu Kontrol Et", comment: ""))
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
        }
    }
    
    // MARK: - Main Content
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedTab.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(headerSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 20)
            
            // Content
            ScrollView {
                contentForSelectedTab
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedTab)
            }
        }
    }
    
    private var headerSubtitle: String {
        switch selectedTab {
        case .general: return NSLocalizedString("Temel uygulama ayarları ve yapılandırma", comment: "")
        case .paths: return NSLocalizedString("Dosya yolları ve dizin ayarları", comment: "")
        case .appearance: return NSLocalizedString("Görünüm ve tema tercihleri", comment: "")
        case .notifications: return NSLocalizedString("Bildirim ayarları ve tercihler", comment: "")
        case .history: return NSLocalizedString("Bildirimler, hatalar ve log kayıtları", comment: "")
        case .backup: return NSLocalizedString("Yedekleme ve geri yükleme işlemleri", comment: "")
        case .advanced: return NSLocalizedString("Gelişmiş özellikler ve araçlar", comment: "")
        case .about: return NSLocalizedString("Uygulama hakkında bilgiler", comment: "")
        }
    }
    
    @ViewBuilder
    private var contentForSelectedTab: some View {
        switch selectedTab {
        case .general: generalTabContent
        case .paths: pathsTabContent
        case .appearance: appearanceTabContent
        case .notifications: notificationsTabContent
        case .history: HistoryView()
        case .backup: BackupRestoreView().environmentObject(manager)
        case .advanced: advancedTabContent
        case .about: aboutTabContent
        }
    }
    
    // MARK: - Tab Contents
    private var generalTabContent: some View {
        LazyVStack(spacing: 24) {
            // Cloudflared Configuration
            modernCard(NSLocalizedString("Cloudflared Yapılandırması", comment: ""), icon: "terminal") {
                VStack(spacing: 16) {
                    modernFormField(NSLocalizedString("Yürütülebilir Dosya Yolu", comment: ""), value: $tempCloudflaredPath) {
                        HStack(spacing: 8) {
                            Button(NSLocalizedString("Gözat", comment: "")) { chooseCloudflared() }
                                .buttonStyle(ModernButtonStyle(color: .blue, size: .small))
                            
                            Button(NSLocalizedString("Kaydet", comment: "")) { saveCloudflaredPath() }
                                .buttonStyle(ModernButtonStyle(color: currentAccentColor, size: .small))
                                .disabled(tempCloudflaredPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    
                    modernFormField(NSLocalizedString("Durum Kontrol Aralığı", comment: ""), value: .constant("\(Int(manager.checkInterval)) \(NSLocalizedString("saniye", comment: ""))")) {
                        VStack(spacing: 8) {
                            HStack {
                                Slider(value: Binding(
                                    get: { Double(Int(intervalString) ?? Int(manager.checkInterval)) },
                                    set: { newVal in intervalString = String(Int(newVal)) }
                                ), in: 5...300, step: 1) {
                                    Text(NSLocalizedString("Aralık", comment: ""))
                                }
                                .accentColor(currentAccentColor)
                                
                                Text("\(Int(intervalString) ?? Int(manager.checkInterval))s")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                            
                            Button(NSLocalizedString("Uygula", comment: "")) { applyInterval() }
                                .buttonStyle(ModernButtonStyle(color: currentAccentColor, size: .small))
                        }
                    }
                }
            }
            
            // System Behavior
            modernCard(NSLocalizedString("Sistem Davranışı", comment: ""), icon: "gearshape") {
                VStack(spacing: 16) {
                    modernToggle(NSLocalizedString("Otomatik Tünel Başlatma", comment: ""), isOn: $autoStartTunnels, description: NSLocalizedString("Uygulama açıldığında tünelleri otomatik başlat", comment: ""))
                    
                    modernToggle(NSLocalizedString("Otomatik MAMP Başlatma", comment: ""), isOn: $autoStartMamp, description: NSLocalizedString("Uygulama açıldığında MAMP'ı otomatik başlat ve kapanırken durdur", comment: ""))
                    
                    modernToggle(NSLocalizedString("Sistem Tepsisine Küçült", comment: ""), isOn: $minimizeToTray, description: NSLocalizedString("Pencere kapatıldığında uygulamayı gizle", comment: ""))
                    
                    modernToggle(NSLocalizedString("Durum Çubuğunda Göster", comment: ""), isOn: $showStatusInMenuBar, description: NSLocalizedString("Menü çubuğunda tünel durumunu göster", comment: ""))
                    
                    if #available(macOS 13.0, *) {
                        modernToggle(NSLocalizedString("Oturum Açıldığında Başlat", comment: ""), 
                                   isOn: Binding(get: { launchAtLogin }, set: { setLaunchAtLogin($0) }),
                                   description: NSLocalizedString("Sisteme giriş yapıldığında otomatik başlat", comment: ""))
                            .disabled(launchAtLoginLoading)
                    }
                }
            }
        }
    }
    
    private var pathsTabContent: some View {
        LazyVStack(spacing: 24) {
            // Cloudflared Paths
            modernCard(NSLocalizedString("Cloudflared Dizinleri", comment: ""), icon: "network") {
                VStack(spacing: 16) {
                    modernFormField(NSLocalizedString("Tünel Yapılandırma Dizini (.cloudflared)", comment: ""), value: $tempCloudflaredDirPath) {
                        HStack(spacing: 8) {
                            Button(NSLocalizedString("Gözat", comment: "")) { chooseCloudflaredDirectory() }
                                .buttonStyle(ModernButtonStyle(color: .cyan, size: .small))
                            
                            Button(NSLocalizedString("Kaydet", comment: "")) { saveCloudflaredDirectory() }
                                .buttonStyle(ModernButtonStyle(color: currentAccentColor, size: .small))
                                .disabled(tempCloudflaredDirPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            
                            Button(NSLocalizedString("Varsayılan", comment: "")) { resetCloudflaredDirectory() }
                                .buttonStyle(ModernButtonStyle(color: .gray, size: .small))
                        }
                    }
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text(NSLocalizedString("Tünel config dosyalarınızın (*.yml) saklandığı dizin", comment: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: { openInFinder(manager.cloudflaredDirectoryPath) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder")
                                Text(NSLocalizedString("Finder'da Aç", comment: ""))
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // MAMP Paths
            modernCard(NSLocalizedString("MAMP Yapılandırması", comment: ""), icon: "server.rack") {
                VStack(spacing: 16) {
                    modernFormField(NSLocalizedString("MAMP Ana Dizini", comment: ""), value: $tempMampPath) {
                        HStack(spacing: 8) {
                            Button(NSLocalizedString("Gözat", comment: "")) { chooseMampPath() }
                                .buttonStyle(ModernButtonStyle(color: .blue, size: .small))
                            
                            Button(NSLocalizedString("Kaydet", comment: "")) { saveMampPath() }
                                .buttonStyle(ModernButtonStyle(color: currentAccentColor, size: .small))
                                .disabled(tempMampPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    
                    Divider()
                    
                    modernFormField(NSLocalizedString("Sites Dizini (Özel)", comment: ""), value: $tempMampSitesPath) {
                        HStack(spacing: 8) {
                            Button(NSLocalizedString("Gözat", comment: "")) { chooseMampSitesPath() }
                                .buttonStyle(ModernButtonStyle(color: .green, size: .small))
                            
                            Button(NSLocalizedString("Kaydet", comment: "")) { saveMampSitesPath() }
                                .buttonStyle(ModernButtonStyle(color: currentAccentColor, size: .small))
                            
                            Button(NSLocalizedString("Varsayılan", comment: "")) { resetMampSitesPath() }
                                .buttonStyle(ModernButtonStyle(color: .gray, size: .small))
                        }
                    }
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Boş bırakılırsa: MAMP_ANA_DİZİN/sites kullanılır")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: { openInFinder(manager.mampSitesDirectoryPath) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder")
                                Text(NSLocalizedString("Finder'da Aç", comment: ""))
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal, 4)
                    
                    Divider()
                    
                    modernFormField(NSLocalizedString("Apache Config Dizini (Özel)", comment: ""), value: $tempMampApacheConfigPath) {
                        HStack(spacing: 8) {
                            Button(NSLocalizedString("Gözat", comment: "")) { chooseMampApacheConfigPath() }
                                .buttonStyle(ModernButtonStyle(color: .orange, size: .small))
                            
                            Button(NSLocalizedString("Kaydet", comment: "")) { saveMampApacheConfigPath() }
                                .buttonStyle(ModernButtonStyle(color: currentAccentColor, size: .small))
                            
                            Button(NSLocalizedString("Varsayılan", comment: "")) { resetMampApacheConfigPath() }
                                .buttonStyle(ModernButtonStyle(color: .gray, size: .small))
                        }
                    }
                    
                    Divider()
                    
                    modernFormField(NSLocalizedString("vHost Config Dosyası (Özel)", comment: ""), value: $tempMampVHostConfPath) {
                        HStack(spacing: 8) {
                            Button(NSLocalizedString("Gözat", comment: "")) { chooseMampVHostConfPath() }
                                .buttonStyle(ModernButtonStyle(color: .purple, size: .small))
                            
                            Button(NSLocalizedString("Kaydet", comment: "")) { saveMampVHostConfPath() }
                                .buttonStyle(ModernButtonStyle(color: currentAccentColor, size: .small))
                            
                            Button(NSLocalizedString("Varsayılan", comment: "")) { resetMampVHostConfPath() }
                                .buttonStyle(ModernButtonStyle(color: .gray, size: .small))
                        }
                    }
                    
                    Divider()
                    
                    modernFormField(NSLocalizedString("httpd.conf Dosyası (Özel)", comment: ""), value: $tempMampHttpdConfPath) {
                        HStack(spacing: 8) {
                            Button(NSLocalizedString("Gözat", comment: "")) { chooseMampHttpdConfPath() }
                                .buttonStyle(ModernButtonStyle(color: .red, size: .small))
                            
                            Button(NSLocalizedString("Kaydet", comment: "")) { saveMampHttpdConfPath() }
                                .buttonStyle(ModernButtonStyle(color: currentAccentColor, size: .small))
                            
                            Button(NSLocalizedString("Varsayılan", comment: "")) { resetMampHttpdConfPath() }
                                .buttonStyle(ModernButtonStyle(color: .gray, size: .small))
                        }
                    }
                    
                    Divider()
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text(NSLocalizedString("Aktif Yollar:", comment: ""))
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        pathDisplayCard(NSLocalizedString("Apache Config", comment: ""), path: manager.mampConfigDirectoryPath, icon: "folder.badge.gearshape")
                        pathDisplayCard(NSLocalizedString("Sites Directory", comment: ""), path: manager.mampSitesDirectoryPath, icon: "folder")
                        pathDisplayCard(NSLocalizedString("vHost Config", comment: ""), path: manager.mampVHostConfPath, icon: "doc.text")
                        pathDisplayCard("httpd.conf", path: manager.mampHttpdConfPath, icon: "doc.text.fill")
                    }
                }
            }
            
            // Python Project Paths
            modernCard(NSLocalizedString("Python Proje Ayarları", comment: ""), icon: "terminal") {
                VStack(spacing: 16) {
                    modernFormField(NSLocalizedString("Python Proje Dizini", comment: ""), value: $tempPythonProjectPath) {
                        HStack(spacing: 8) {
                            Button(NSLocalizedString("Gözat", comment: "")) { choosePythonProjectPath() }
                                .buttonStyle(ModernButtonStyle(color: .green, size: .small))
                            
                            Button(NSLocalizedString("Kaydet", comment: "")) { savePythonProjectPath() }
                                .buttonStyle(ModernButtonStyle(color: currentAccentColor, size: .small))
                                .disabled(tempPythonProjectPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    
                    Text("Python uygulamanızın bulunduğu ana dizin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick Access
            modernCard(NSLocalizedString("Hızlı Erişim", comment: ""), icon: "bolt.fill") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    quickAccessButton("~/.cloudflared", icon: "folder", path: manager.cloudflaredDirectoryPath)
                    quickAccessButton(NSLocalizedString("MAMP Config", comment: ""), icon: "folder.badge.gearshape", path: manager.mampConfigDirectoryPath)
                    quickAccessButton(NSLocalizedString("vHost File", comment: ""), icon: "doc.text", path: manager.mampVHostConfPath)
                    quickAccessButton("httpd.conf", icon: "doc.text.fill", path: manager.mampHttpdConfPath)
                }
            }
        }
    }
    
    private var appearanceTabContent: some View {
        LazyVStack(spacing: 24) {
            // Theme Settings
            modernCard(NSLocalizedString("Tema Ayarları", comment: ""), icon: "paintbrush") {
                VStack(spacing: 20) {
                    modernToggle(NSLocalizedString("Koyu Mod", comment: ""), isOn: $darkModeEnabled, description: NSLocalizedString("Karanlık tema kullan", comment: ""))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString("Vurgu Rengi", comment: ""))
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(accentColors, id: \.name) { colorOption in
                                colorPickerButton(colorOption)
                            }
                        }
                    }
                }
            }
            
            // Interface Options
            modernCard(NSLocalizedString("Arayüz Seçenekleri", comment: ""), icon: "rectangle.3.group") {
                VStack(spacing: 16) {
                    modernToggle(
                        NSLocalizedString("Dock'tan Gizle", comment: ""),
                        isOn: $hideFromDock,
                        description: NSLocalizedString("Uygulamayı Dock'tan gizle, sadece menü çubuğunda göster", comment: "")
                    )
                    .onChange(of: hideFromDock) { _, newValue in
                        applyDockVisibility(newValue)
                    }
                }
            }
        }
    }
    
    private var notificationsTabContent: some View {
        LazyVStack(spacing: 24) {
            modernCard(NSLocalizedString("Bildirim Ayarları", comment: ""), icon: "bell") {
                VStack(spacing: 16) {
                    modernToggle(NSLocalizedString("Bildirimleri Etkinleştir", comment: ""), isOn: $notificationsEnabled, description: NSLocalizedString("Sistem bildirimlerini göster", comment: ""))
                    
                    if notificationsEnabled {
                        VStack(spacing: 12) {
                            modernToggle(NSLocalizedString("Tünel Durumu Bildirimleri", comment: ""), isOn: .constant(true), description: NSLocalizedString("Tünel başlatma/durdurma bildirimleri", comment: ""))
                            modernToggle(NSLocalizedString("Hata Bildirimleri", comment: ""), isOn: .constant(true), description: NSLocalizedString("Hata ve uyarı bildirimleri", comment: ""))
                            modernToggle(NSLocalizedString("Başarı Bildirimleri", comment: ""), isOn: .constant(true), description: NSLocalizedString("İşlem tamamlama bildirimleri", comment: ""))
                        }
                        .padding(.leading, 20)
                    }
                }
            }
        }
    }
    
    private var advancedTabContent: some View {
        LazyVStack(spacing: 24) {
            // MAMP Operations
            modernCard(NSLocalizedString("MAMP İşlemleri", comment: ""), icon: "server.rack") {
                VStack(spacing: 12) {
                    actionButton(NSLocalizedString("MySQL Socket Düzelt", comment: ""), icon: "wrench.and.screwdriver", color: .orange) {
                        MampManager.shared.fixMySQLSocket { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success:
                                    let alert = NSAlert()
                                    alert.messageText = NSLocalizedString("Başarılı", comment: "")
                                    alert.informativeText = "MySQL socket bağlantısı düzeltildi (/tmp/mysql.sock -> MAMP)."
                                    alert.runModal()
                                case .failure(let error):
                                    // Hata durumunda manuel çözüm öner
                                    let command = "sudo mkdir -p /var/mysql && sudo ln -sf /Applications/MAMP/tmp/mysql/mysql.sock /tmp/mysql.sock && sudo ln -sf /Applications/MAMP/tmp/mysql/mysql.sock /var/mysql/mysql.sock"
                                    let alert = NSAlert()
                                    alert.messageText = NSLocalizedString("İşlem Başarısız", comment: "")
                                    alert.informativeText = "\(NSLocalizedString("Hata", comment: "")): \(error.localizedDescription)\n\nEğer MAMP açıksa ve hala bu hatayı alıyorsanız, lütfen veritabanı bağlantı ayarlarınızda 'localhost' yerine '127.0.0.1' kullanın. Bu en kesin çözümdür."
                                    alert.alertStyle = .warning
                                    alert.addButton(withTitle: NSLocalizedString("Tamam", comment: ""))
                                    alert.addButton(withTitle: NSLocalizedString("Komutu Kopyala", comment: ""))
                                    
                                    let response = alert.runModal()
                                    if response == .alertSecondButtonReturn {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(command, forType: .string)
                                    }
                                }
                            }
                        }
                    }
                    Text("MySQL 'No such file or directory' hatası alıyorsanız bunu kullanın.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    actionButton(NSLocalizedString("phpMyAdmin Config Düzelt", comment: ""), icon: "gear.badge.checkmark", color: .purple) {
                        MampManager.shared.fixPhpMyAdminConfig { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let path):
                                    let alert = NSAlert()
                                    alert.messageText = NSLocalizedString("Başarılı", comment: "")
                                    alert.informativeText = "phpMyAdmin yapılandırması güncellendi (localhost -> 127.0.0.1).\n\nDosya: \(path)"
                                    alert.runModal()
                                case .failure(let error):
                                    let alert = NSAlert()
                                    alert.messageText = NSLocalizedString("Hata", comment: "")
                                    alert.informativeText = "Düzeltme başarısız: \(error.localizedDescription)"
                                    alert.runModal()
                                }
                            }
                        }
                    }
                    Text("phpMyAdmin bağlantı hatası alıyorsanız bunu kullanın.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Cloudflare Operations
            modernCard(NSLocalizedString("Cloudflare İşlemleri", comment: ""), icon: "cloud") {
                VStack(spacing: 12) {
                    actionButton(NSLocalizedString("Cloudflare Hesabı Girişi", comment: ""), icon: "person.crop.circle.badge.checkmark", color: .blue) {
                        manager.cloudflareLogin { _ in }
                    }
                    
                    actionButton(NSLocalizedString("Tünel Durumlarını Kontrol Et", comment: ""), icon: "clock.arrow.circlepath", color: .orange) {
                        manager.checkAllManagedTunnelStatuses(forceCheck: true)
                    }
                }
            }
            
            // Bulk Operations
            modernCard(NSLocalizedString("Toplu İşlemler", comment: ""), icon: "square.3.layers.3d") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    actionButton(NSLocalizedString("Tümünü Tara", comment: ""), icon: "arrow.clockwise", color: .blue) {
                        manager.findManagedTunnels()
                    }
                    
                    actionButton(NSLocalizedString("Tümünü Başlat", comment: ""), icon: "play.circle.fill", color: .green) {
                        manager.startAllManagedTunnels()
                    }
                    
                    actionButton(NSLocalizedString("Tümünü Durdur", comment: ""), icon: "stop.circle.fill", color: .red) {
                        manager.stopAllTunnels()
                    }
                    
                    actionButton(NSLocalizedString("Ayarları Sıfırla", comment: ""), icon: "arrow.counterclockwise", color: .purple) {
                        resetSettings()
                    }
                }
            }
        }
    }
    
    private var aboutTabContent: some View {
        LazyVStack(spacing: 24) {
            modernCard(NSLocalizedString("Uygulama Bilgileri", comment: ""), icon: "info.circle") {
                VStack(spacing: 20) {
                    // App Icon
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [currentAccentColor, currentAccentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        .shadow(color: currentAccentColor.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    VStack(spacing: 8) {
                        Text("Cloudflared Manager")
                            .font(.title.bold())
                        
                        Text("\(NSLocalizedString("Version", comment: "")) 1.1.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(NSLocalizedString("Modern cloudflared tünel yönetim aracı", comment: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Divider()
                    
                    VStack(spacing: 12) {
                        infoRow(NSLocalizedString("Geliştirici", comment: ""), value: "Adil Emre Karayürek")
                        infoRow(NSLocalizedString("Platform", comment: ""), value: "macOS 13.0+")
                        infoRow(NSLocalizedString("Framework", comment: ""), value: "SwiftUI")
                        infoRow(NSLocalizedString("Son Güncelleme", comment: ""), value: "20 Kasım 2025")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func modernCard<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [currentAccentColor.opacity(0.2), currentAccentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(currentAccentColor)
                }
                
                Text(title)
                    .font(.title3.bold())
                
                Spacer()
            }
            
            content()
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: currentAccentColor.opacity(0.08), radius: 12, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    private func modernFormField<Content: View>(_ label: String, value: Binding<String>, @ViewBuilder actions: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
            
            HStack(spacing: 12) {
                TextField(label, text: value)
                    .textFieldStyle(ModernTextFieldStyle())
                
                actions()
            }
        }
    }
    
    private func modernToggle(_ title: String, isOn: Binding<Bool>, description: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(ModernToggleStyle(accentColor: currentAccentColor))
        }
    }
    
    private func pathDisplayCard(_ title: String, path: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(currentAccentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text((path as NSString).abbreviatingWithTildeInPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // İzin durumu göstergesi
                if FileManager.default.fileExists(atPath: path) {
                    let isReadable = FileManager.default.isReadableFile(atPath: path)
                    let isWritable = FileManager.default.isWritableFile(atPath: path)
                    
                    HStack(spacing: 4) {
                        Image(systemName: isReadable ? "eye" : "eye.slash")
                        Image(systemName: isWritable ? "pencil" : "pencil.slash")
                        Text(isWritable ? NSLocalizedString("Düzenlenebilir", comment: "") : NSLocalizedString("Salt Okunur", comment: ""))
                    }
                    .font(.system(size: 9))
                    .foregroundColor(isWritable ? .green : .orange)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: { openInFinder(path) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                        Text(NSLocalizedString("Aç", comment: ""))
                    }
                    .font(.caption)
                }
                .buttonStyle(.borderless)
                .disabled(!FileManager.default.fileExists(atPath: path))
                
                Button(action: { openFileInEditor(path) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.circle")
                        Text(NSLocalizedString("Düzenle", comment: ""))
                    }
                    .font(.caption)
                }
                .buttonStyle(.borderless)
                .disabled(!FileManager.default.fileExists(atPath: path))
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
    
    private func quickAccessButton(_ title: String, icon: String, path: String) -> some View {
        Button(action: {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(currentAccentColor)
                
                Text(title)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(!FileManager.default.fileExists(atPath: path))
    }
    
    private func colorPickerButton(_ colorOption: (name: String, color: Color)) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                accentColorName = colorOption.name
            }
        }) {
            Circle()
                .fill(colorOption.color)
                .frame(width: 32, height: 32)
                .overlay {
                    if accentColorName == colorOption.name {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(accentColorName == colorOption.name ? 1.2 : 1.0)
                .shadow(color: colorOption.color.opacity(0.4), radius: accentColorName == colorOption.name ? 6 : 2)
        }
        .buttonStyle(.plain)
    }
    
    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
    
    // MARK: - Helper Functions
    private func setupInitialValues() {
        tempCloudflaredPath = manager.cloudflaredExecutablePath
        tempCloudflaredDirPath = manager.cloudflaredDirectoryPath
        tempMampPath = manager.mampBasePath
        tempMampSitesPath = manager.customMampSitesPath ?? ""
        tempMampApacheConfigPath = manager.customMampApacheConfigPath ?? ""
        tempMampVHostConfPath = manager.customMampVHostConfPath ?? ""
        tempMampHttpdConfPath = manager.customMampHttpdConfPath ?? ""
        intervalString = String(Int(manager.checkInterval))
        if let appDelegate = NSApp.delegate as? AppDelegate {
            let resolvedPythonPath = appDelegate.pythonProjectDirectoryPath
            storedPythonProjectPath = resolvedPythonPath
            tempPythonProjectPath = resolvedPythonPath
        } else {
            let fallback = storedPythonProjectPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "/Users/adilemre/Documents/PANEL-main" : storedPythonProjectPath
            storedPythonProjectPath = fallback
            tempPythonProjectPath = fallback
        }
        
        // Load hideFromDock preference
        hideFromDock = UserDefaults.standard.bool(forKey: "hideFromDock")
        
        if #available(macOS 13.0, *) {
            launchAtLogin = manager.isLaunchAtLoginEnabled()
        }
    }
    
    private func chooseCloudflared() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = NSLocalizedString("cloudflared Yürütülebilir Dosyasını Seçin", comment: "")
        
        if panel.runModal() == .OK, let url = panel.url {
            tempCloudflaredPath = url.path
        }
    }
    
    private func chooseMampPath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = NSLocalizedString("MAMP Ana Dizinini Seçin", comment: "")
        
        if panel.runModal() == .OK, let url = panel.url {
            tempMampPath = url.path
        }
    }
    
    private func choosePythonProjectPath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = NSLocalizedString("Python Proje Dizinini Seçin", comment: "")
        
        if panel.runModal() == .OK, let url = panel.url {
            tempPythonProjectPath = url.path
        }
    }
    
    private func chooseCloudflaredDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = NSLocalizedString("Cloudflared Tünel Dizinini Seçin", comment: "")
        panel.message = "Tünel yapılandırma dosyalarınızın (.yml) bulunduğu dizini seçin"
        panel.prompt = "Seç"
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK, let url = panel.url {
            // Sandbox için security-scoped bookmark oluştur
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                tempCloudflaredDirPath = url.path
            } else {
                tempCloudflaredDirPath = url.path
            }
        }
    }
    
    private func saveCloudflaredDirectory() {
        let trimmed = tempCloudflaredDirPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let expanded = (trimmed as NSString).expandingTildeInPath
        manager.cloudflaredDirectoryPath = expanded
        tempCloudflaredDirPath = manager.cloudflaredDirectoryPath
    }
    
    private func resetCloudflaredDirectory() {
        let defaultPath = ("~/.cloudflared" as NSString).expandingTildeInPath
        tempCloudflaredDirPath = defaultPath
        manager.cloudflaredDirectoryPath = defaultPath
    }
    
    private func chooseMampSitesPath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = NSLocalizedString("MAMP Sites Dizinini Seçin", comment: "")
        panel.message = "Web sitelerinizin bulunduğu dizini seçin (htdocs, sites vb.)"
        panel.prompt = "Seç"
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK, let url = panel.url {
            // Sandbox için security-scoped bookmark oluştur
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                tempMampSitesPath = url.path
            } else {
                tempMampSitesPath = url.path
            }
        }
    }
    
    private func saveMampSitesPath() {
        let trimmed = tempMampSitesPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            manager.customMampSitesPath = nil
            tempMampSitesPath = ""
        } else {
            let standardized = (trimmed as NSString).standardizingPath
            manager.customMampSitesPath = standardized
            tempMampSitesPath = standardized
        }
    }
    
    private func resetMampSitesPath() {
        tempMampSitesPath = ""
        manager.customMampSitesPath = nil
    }
    
    private func chooseMampApacheConfigPath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = NSLocalizedString("Apache Config Dizinini Seçin", comment: "")
        panel.message = "Apache yapılandırma dosyalarının bulunduğu dizini seçin"
        panel.prompt = "Seç"
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK, let url = panel.url {
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                tempMampApacheConfigPath = url.path
            } else {
                tempMampApacheConfigPath = url.path
            }
        }
    }
    
    private func saveMampApacheConfigPath() {
        let trimmed = tempMampApacheConfigPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            manager.customMampApacheConfigPath = nil
            tempMampApacheConfigPath = ""
        } else {
            let standardized = (trimmed as NSString).standardizingPath
            manager.customMampApacheConfigPath = standardized
            tempMampApacheConfigPath = standardized
        }
    }
    
    private func resetMampApacheConfigPath() {
        tempMampApacheConfigPath = ""
        manager.customMampApacheConfigPath = nil
    }
    
    private func chooseMampVHostConfPath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = NSLocalizedString("vHost Config Dosyasını Seçin", comment: "")
        panel.message = "httpd-vhosts.conf dosyasını seçin"
        panel.prompt = "Seç"
        panel.allowedContentTypes = [.init(filenameExtension: "conf")].compactMap { $0 }
        panel.allowsOtherFileTypes = true
        
        if panel.runModal() == .OK, let url = panel.url {
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                tempMampVHostConfPath = url.path
            } else {
                tempMampVHostConfPath = url.path
            }
        }
    }
    
    private func saveMampVHostConfPath() {
        let trimmed = tempMampVHostConfPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            manager.customMampVHostConfPath = nil
            tempMampVHostConfPath = ""
        } else {
            let standardized = (trimmed as NSString).standardizingPath
            manager.customMampVHostConfPath = standardized
            tempMampVHostConfPath = standardized
        }
    }
    
    private func resetMampVHostConfPath() {
        tempMampVHostConfPath = ""
        manager.customMampVHostConfPath = nil
    }
    
    private func chooseMampHttpdConfPath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = NSLocalizedString("httpd.conf Dosyasını Seçin", comment: "")
        panel.message = "Ana Apache yapılandırma dosyasını seçin"
        panel.prompt = "Seç"
        panel.allowedContentTypes = [.init(filenameExtension: "conf")].compactMap { $0 }
        panel.allowsOtherFileTypes = true
        
        if panel.runModal() == .OK, let url = panel.url {
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                tempMampHttpdConfPath = url.path
            } else {
                tempMampHttpdConfPath = url.path
            }
        }
    }
    
    private func saveMampHttpdConfPath() {
        let trimmed = tempMampHttpdConfPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            manager.customMampHttpdConfPath = nil
            tempMampHttpdConfPath = ""
        } else {
            let standardized = (trimmed as NSString).standardizingPath
            manager.customMampHttpdConfPath = standardized
            tempMampHttpdConfPath = standardized
        }
    }
    
    private func resetMampHttpdConfPath() {
        tempMampHttpdConfPath = ""
        manager.customMampHttpdConfPath = nil
    }
    
    private func saveMampPath() {
        let trimmed = tempMampPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        manager.mampBasePath = trimmed
        tempMampPath = manager.mampBasePath
    }
    
    private func savePythonProjectPath() {
        let trimmed = tempPythonProjectPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let expanded = (trimmed as NSString).expandingTildeInPath
        storedPythonProjectPath = expanded
        tempPythonProjectPath = expanded
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.constructMenu()
        }
    }
    
    private func saveCloudflaredPath() {
        let path = tempCloudflaredPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else { return }
        manager.cloudflaredExecutablePath = path
    }
    
    private func applyInterval() {
        let val = Int(intervalString) ?? Int(manager.checkInterval)
        let clamped = max(5, min(300, val))
        intervalString = String(clamped)
        manager.checkInterval = TimeInterval(clamped)
    }
    
    private func setLaunchAtLogin(_ newValue: Bool) {
        guard #available(macOS 13.0, *) else { return }
        launchAtLoginLoading = true
        manager.toggleLaunchAtLogin { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let enabled):
                    launchAtLogin = enabled
                    manager.postUserNotification(
                        identifier: "launch_at_login_toggle",
                        title: NSLocalizedString("Oturum Açıldığında Başlatma", comment: ""),
                        body: enabled ? NSLocalizedString("Etkinleştirildi", comment: "") : NSLocalizedString("Devre Dışı Bırakıldı", comment: ""),
                        type: enabled ? .success : .info
                    )
                case .failure(let error):
                    launchAtLogin = manager.isLaunchAtLoginEnabled()
                    manager.postUserNotification(
                        identifier: "launch_at_login_error",
                        title: "Hata",
                        body: "Ayar değiştirilemedi: \(error.localizedDescription)",
                        type: .error
                    )
                }
                launchAtLoginLoading = false
            }
        }
    }
    
    private func applyDarkMode(_ enabled: Bool) {
        DispatchQueue.main.async {
            if enabled {
                NSApp.appearance = NSAppearance(named: .darkAqua)
            } else {
                NSApp.appearance = NSAppearance(named: .aqua)
            }
        }
    }
    
    private func applyDockVisibility(_ hide: Bool) {
        DispatchQueue.main.async {
            if hide {
                NSApp.setActivationPolicy(.accessory)
            } else {
                NSApp.setActivationPolicy(.regular)
            }
            UserDefaults.standard.set(hide, forKey: "hideFromDock")
        }
    }
    
    private func resetSettings() {
        // Reset to defaults (all behavior settings enabled)
        darkModeEnabled = false
        notificationsEnabled = true
        autoStartTunnels = false
        minimizeToTray = true
        showStatusInMenuBar = true
        accentColorName = "blue"
        
        // Ensure menu bar icon is visible immediately
        UserDefaults.standard.set(true, forKey: "showStatusInMenuBar")
        
        // Apply light mode
        applyDarkMode(false)
    }
    
    private func openInFinder(_ path: String) {
        // Sandbox güvenli açma
        let expandedPath = (path as NSString).expandingTildeInPath
        let expandedURL = URL(fileURLWithPath: expandedPath)
        
        // Önce dizinin var olup olmadığını kontrol et
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                // Dizin varsa Finder'da göster
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: expandedPath)
            } else {
                // Dosya ise parent dizini aç
                NSWorkspace.shared.selectFile(expandedPath, inFileViewerRootedAtPath: expandedURL.deletingLastPathComponent().path)
            }
        } else {
            // Dizin yoksa, oluşturmaya çalış (sandbox izni varsa)
            do {
                try FileManager.default.createDirectory(at: expandedURL, withIntermediateDirectories: true)
                NSWorkspace.shared.open(expandedURL)
            } catch {
                // Oluşturulamazsa parent dizini göster (home directory genelde erişilebilir)
                let parentURL = expandedURL.deletingLastPathComponent()
                if FileManager.default.fileExists(atPath: parentURL.path) {
                    NSWorkspace.shared.open(parentURL)
                } else {
                    // En son çare: home directory aç
                    NSWorkspace.shared.open(FileManager.default.homeDirectoryForCurrentUser)
                }
            }
        }
    }
    
    private func openFileInEditor(_ path: String) {
        let expandedPath = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        guard FileManager.default.fileExists(atPath: expandedPath) else { return }
        
        // Dosyanın okunabilir olup olmadığını kontrol et
        if FileManager.default.isReadableFile(atPath: expandedPath) {
            // Dosyayı varsayılan editör ile aç
            NSWorkspace.shared.open(url)
        } else {
            // İzin yoksa, sudo ile açmayı öner
            showPermissionAlert(for: expandedPath)
        }
    }
    
    private func showPermissionAlert(for filePath: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("İzin Gerekli", comment: "")
        alert.informativeText = """
        Bu dosyayı düzenlemek için yönetici izinleri gerekebilir:
        \(filePath)
        
        Terminalde şu komutla açabilirsiniz:
        sudo nano \(filePath)
        
        veya
        
        Dosya izinlerini değiştirin:
        sudo chmod 644 \(filePath)
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("Kapat", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Terminal'de Aç", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Kopyala", comment: ""))
        
        let response = alert.runModal()
        
        if response == .alertSecondButtonReturn {
            // Terminal'de sudo nano ile aç
            openInTerminalWithSudo(filePath)
        } else if response == .alertThirdButtonReturn {
            // Komutu panoya kopyala
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString("sudo nano \(filePath)", forType: .string)
        }
    }
    
    private func openInTerminalWithSudo(_ filePath: String) {
        // AppleScript ile Terminal'de sudo komutunu çalıştır
        let script = """
        tell application "Terminal"
            activate
            do script "sudo nano '\(filePath)'"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                print("⚠️ Terminal açma hatası: \(error)")
                // Hata durumunda komutu kopyala
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString("sudo nano \(filePath)", forType: .string)
                
                let fallbackAlert = NSAlert()
                fallbackAlert.messageText = "Terminal Açılamadı"
                fallbackAlert.informativeText = "Komut panoya kopyalandı. Terminal'i açıp yapıştırabilirsiniz."
                fallbackAlert.runModal()
            }
        }
    }
}

// MARK: - Custom Styles
struct ModernButtonStyle: ButtonStyle {
    let color: Color
    let size: ButtonSize
    
    enum ButtonSize {
        case small, medium, large
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .medium: return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
            case .large: return EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
            }
        }
        
        var font: Font {
            switch self {
            case .small: return .caption.bold()
            case .medium: return .subheadline.bold()
            case .large: return .headline.bold()
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(.white)
            .padding(size.padding)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.3), radius: configuration.isPressed ? 2 : 4, x: 0, y: configuration.isPressed ? 1 : 2)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            }
    }
}

struct ModernToggleStyle: ToggleStyle {
    let accentColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? 
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : 
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 50, height: 30)
                .overlay {
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                        .offset(x: configuration.isOn ? 10 : -10)
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

#Preview {
    SettingsView().environmentObject(TunnelManager())
}
