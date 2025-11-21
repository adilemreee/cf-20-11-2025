import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var tunnelManager: TunnelManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    @State private var isAttemptingCloudflareLogin = false
    @State private var onboardingMessage: String?
    
    private var appDelegate: AppDelegate? {
        NSApp.delegate as? AppDelegate
    }
    
    private var cloudflaredReady: Bool {
        FileManager.default.isExecutableFile(atPath: tunnelManager.cloudflaredExecutablePath)
    }
    
    private var mampExists: Bool {
        FileManager.default.fileExists(atPath: tunnelManager.mampBasePath)
    }
    
    var body: some View {
        ZStack {
            // Enhanced background with animated gradient
            Color(.windowBackgroundColor)
                .ignoresSafeArea()
                .animatedGradient(colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.05),
                    Color.orange.opacity(0.05),
                    Color.pink.opacity(0.05)
                ])
            
            VStack(spacing: 32) {
                // Modern Logo Section with enhanced animations
                VStack(spacing: 16) {
                    ZStack {
                        // Background circle with enhanced gradient and glassmorphism
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                            .overlay {
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.4), Color.clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            }
                            .shadow(color: .blue.opacity(0.4), radius: 25, x: 0, y: 12)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .pulsing(minScale: 1.0, maxScale: 1.05, duration: 2)
                        
                        // Icon with enhanced effects
                        Image(systemName: "cloud.fill")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(rotationAngle))
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .scaleIn(delay: 0.2, duration: 0.8)
                    
                    VStack(spacing: 8) {
                        Text("Cloudflared Manager")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .fadeIn(delay: 0.6, duration: 0.8)
                        
                        Text(NSLocalizedString("Modern Tünel Yönetim Aracı", comment: ""))
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .fadeIn(delay: 0.8, duration: 0.8)
                    }
                }
                
                // Live status indicators
                VStack(spacing: 12) {
                    ModernStatusIndicator(
                        status: cloudflaredReady ? .online : .warning,
                        title: cloudflaredReady ? NSLocalizedString("cloudflared hazır", comment: "") : NSLocalizedString("cloudflared eksik", comment: ""),
                        subtitle: tunnelManager.cloudflaredExecutablePath
                    )
                    .fadeIn(delay: 0.8, duration: 0.8)

                    ModernStatusIndicator(
                        status: mampExists ? .online : .warning,
                        title: NSLocalizedString("MAMP Dizini", comment: ""),
                        subtitle: tunnelManager.mampBasePath
                    )
                    .fadeIn(delay: 0.9, duration: 0.8)
                }

                // Feature Cards with staggered animations
                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "rectangle.grid.2x2.fill",
                        title: NSLocalizedString("Gösterge Paneli", comment: ""),
                        description: NSLocalizedString("Tünelleri ve durum özetini tek ekranda takip edin", comment: ""),
                        color: .blue
                    ) {
                        openDashboard()
                    }
                    .slideIn(from: .left, delay: 1.0, duration: 0.6)

                    FeatureCard(
                        icon: "bolt.fill",
                        title: NSLocalizedString("Hızlı Tünel Oluştur", comment: ""),
                        description: NSLocalizedString("Yerel projelerinizi saniyeler içinde paylaşın", comment: ""),
                        color: .purple
                    ) {
                        openQuickTunnel()
                    }
                    .slideIn(from: .right, delay: 1.1, duration: 0.6)

                    FeatureCard(
                        icon: "gearshape.fill",
                        title: NSLocalizedString("Ayarları Yapılandır", comment: ""),
                        description: NSLocalizedString("cloudflared, MAMP ve diğer yolları özelleştirin", comment: ""),
                        color: .green
                    ) {
                        openSettings()
                    }
                    .slideIn(from: .left, delay: 1.2, duration: 0.6)
                }

                ModernInfoPanel(
                    title: NSLocalizedString("Temel Bilgiler", comment: ""),
                    items: [
                        .init(label: "cloudflared", value: tunnelManager.cloudflaredExecutablePath, icon: "terminal"),
                        .init(label: NSLocalizedString("MAMP Dizini", comment: ""), value: tunnelManager.mampBasePath, icon: "folder"),
                        .init(label: NSLocalizedString("Durum Kontrol Aralığı", comment: ""), value: "\(Int(tunnelManager.checkInterval)) sn", icon: "clock")
                    ],
                    color: .blue
                )
                .fadeIn(delay: 1.3, duration: 0.6)

                onboardingChecklist

                if let message = onboardingMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }

                ModernActionButton(
                    title: NSLocalizedString("Hazırım, Devam Et", comment: ""),
                    subtitle: NSLocalizedString("Uygulama menü çubuğunda çalışmaya devam edecek", comment: ""),
                    icon: "checkmark.circle.fill",
                    color: .blue
                ) {
                    finishOnboarding()
                }
                .padding(.top, 12)
            }
            .padding(32)
        }
        .frame(maxWidth: 600, maxHeight: 500)
        .onAppear {
            startAnimations()
        }
    }

    private var onboardingChecklist: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Başlangıç Kontrol Listesi", comment: ""))
                .font(.title3.bold())
            
            onboardingRow(
                icon: cloudflaredReady ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                iconColor: cloudflaredReady ? .green : .orange,
                title: NSLocalizedString("cloudflared yolunu doğrulayın", comment: ""),
                subtitle: cloudflaredReady ? NSLocalizedString("Hepsi hazır.", comment: "") : NSLocalizedString("Ayarlar'dan farklı bir yol seçebilirsiniz.", comment: ""),
                actionTitle: NSLocalizedString("Kontrol Et", comment: "")
            ) {
                tunnelManager.checkCloudflaredExecutable()
                onboardingMessage = NSLocalizedString("cloudflared yolu kontrol ediliyor...", comment: "")
            }
            
            onboardingRow(
                icon: isAttemptingCloudflareLogin ? "arrow.triangle.2.circlepath.circle" : "person.crop.circle.badge.checkmark",
                iconColor: .purple,
                title: NSLocalizedString("Cloudflare hesabınıza giriş yapın", comment: ""),
                subtitle: NSLocalizedString("Tarayıcıda açılan pencereyi takip edin.", comment: ""),
                actionTitle: isAttemptingCloudflareLogin ? nil : NSLocalizedString("Giriş Yap", comment: ""),
                actionColor: .purple
            ) {
                startCloudflareLogin()
            }
            
            onboardingRow(
                icon: mampExists ? "checkmark.circle.fill" : "folder.badge.questionmark",
                iconColor: mampExists ? .green : .orange,
                title: NSLocalizedString("MAMP proje klasörünü kontrol edin", comment: ""),
                subtitle: mampExists ? NSLocalizedString("MAMP dizini bulundu.", comment: "") : NSLocalizedString("MAMP dizini bulunamadı, yolu Ayarlar'dan güncelleyin.", comment: ""),
                actionTitle: NSLocalizedString("Klasörü Aç", comment: ""),
                actionColor: .orange
            ) {
                openMampFolder()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func startAnimations() {
        // Pulsing animation
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
        
        // Rotation animation
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }

    private func onboardingRow(icon: String, iconColor: Color, title: String, subtitle: String, actionTitle: String?, actionColor: Color = .blue, action: (() -> Void)?) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .padding(4)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle) {
                    action()
                }
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(actionColor.opacity(0.15))
                .foregroundColor(actionColor)
                .clipShape(Capsule())
            }
        }
    }

    private func openDashboard() {
        appDelegate?.openDashboardWindowAction()
        onboardingMessage = NSLocalizedString("Gösterge Paneli açılıyor...", comment: "")
    }
    
    private func openQuickTunnel() {
        appDelegate?.openQuickTunnelWindow()
        onboardingMessage = NSLocalizedString("Hızlı tünel penceresi açılıyor...", comment: "")
    }
    
    private func openSettings() {
        appDelegate?.openSettingsWindowAction()
        onboardingMessage = NSLocalizedString("Ayarlar penceresi açıldı.", comment: "")
    }
    
    private func openMampFolder() {
        let path = (tunnelManager.mampBasePath as NSString).expandingTildeInPath
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
        onboardingMessage = NSLocalizedString("MAMP dizini Finder'da açıldı.", comment: "")
    }
    

    private func finishOnboarding() {
        hasCompletedOnboarding = true
        onboardingMessage = NSLocalizedString("Cloudflared Manager menü çubuğunda çalışıyor.", comment: "")
    }
    
    private func startCloudflareLogin() {
        guard !isAttemptingCloudflareLogin else { return }
        isAttemptingCloudflareLogin = true
        onboardingMessage = NSLocalizedString("Cloudflare giriş kontrolü başlatıldı...", comment: "")
        tunnelManager.cloudflareLogin { result in
            DispatchQueue.main.async {
                self.isAttemptingCloudflareLogin = false
                switch result {
                case .success:
                    self.onboardingMessage = NSLocalizedString("Tarayıcıda açılan Cloudflare girişini tamamlayın.", comment: "")
                case .failure(let error):
                    self.onboardingMessage = NSLocalizedString("Cloudflare giriş hatası", comment: "") + ": \(error.localizedDescription)"
                }
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: (() -> Void)?
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    init(icon: String, title: String, description: String, color: Color, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.description = description
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 16) {
                // Icon with enhanced glassmorphism
                ZStack {
                    // Background with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: color.opacity(0.3), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Enhanced Arrow with animation
                ZStack {
                    Circle()
                        .fill(color.opacity(isHovered ? 0.2 : 0.1))
                        .frame(width: 32, height: 32)
                        .scaleEffect(isHovered ? 1.1 : 1.0)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                        .offset(x: isHovered ? 2 : 0)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isHovered ? 0.4 : 0.2),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: .black.opacity(isHovered ? 0.15 : 0.08), 
                        radius: isHovered ? 12 : 6, 
                        x: 0, 
                        y: isHovered ? 6 : 3
                    )
            )
            .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.02 : 1))
            .rotation3DEffect(
                .degrees(isHovered ? 2 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    ContentView()
}
