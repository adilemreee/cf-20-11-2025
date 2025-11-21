import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var manager: TunnelManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentStep = 0
    @Environment(\.presentationMode) var presentationMode
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    var body: some View {
        VStack {
            // Header / Progress
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Capsule()
                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .animation(.spring(), value: currentStep)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 40)
            
            // Content
            ZStack {
                if currentStep == 0 {
                    WelcomeStepView()
                } else if currentStep == 1 {
                    CloudflaredStepView()
                } else if currentStep == 2 {
                    MampStepView(currentStep: $currentStep)
                } else if currentStep == 3 {
                    FinishStepView(onFinish: completeOnboarding)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut, value: currentStep)
            
            // Navigation Buttons
            HStack {
                if currentStep > 0 {
                    Button("Geri") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
                
                Spacer()
                
                if currentStep < 3 {
                    Button(action: {
                        withAnimation { currentStep += 1 }
                    }) {
                        Text(NSLocalizedString("İleri", comment: ""))
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 600, height: 450)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(appVersion, forKey: "lastAppVersion")
        print("✅ Onboarding tamamlandı - Version: \(appVersion) kaydedildi")
        
        // Close window
        if let window = NSApp.windows.first(where: { $0.contentView?.subviews.first?.className.contains("OnboardingView") ?? false }) {
            window.close()
        } else {
            // Fallback: close key window
            NSApp.keyWindow?.close()
        }
        
        // Open Settings or Dashboard via AppDelegate if possible, 
        // but since we are in SwiftUI, we might rely on the user opening it from menu bar
        // or we can post a notification to AppDelegate to open the main window.
        NotificationCenter.default.post(name: Notification.Name("OpenDashboardRequested"), object: nil)
    }
}

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            Text(NSLocalizedString("Cloudflared Manager'a Hoşgeldiniz", comment: ""))
                .font(.title)
                .bold()
            
            Text(NSLocalizedString("Cloudflare tünellerinizi kolayca yönetin, MAMP projelerinizi internete açın ve loglarınızı takip edin.", comment: ""))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct CloudflaredStepView: View {
    @EnvironmentObject var manager: TunnelManager
    @State private var statusMessage: String = ""
    @State private var statusColor: Color = .secondary
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(NSLocalizedString("Cloudflared Yapılandırması", comment: ""))
                .font(.title2)
                .bold()
            
            Text(NSLocalizedString("Uygulamanın çalışması için 'cloudflared' komut satırı aracı gereklidir.", comment: ""))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading) {
                Text(NSLocalizedString("Cloudflared Yolu:", comment: ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Yol...", text: $manager.cloudflaredExecutablePath)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(NSLocalizedString("Seç", comment: "")) {
                        selectFile()
                    }
                }
            }
            .padding(.horizontal, 40)
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(statusColor)
                    .font(.caption)
            }
            
            Button("Yolu Kontrol Et") {
                checkPath()
            }
        }
        .padding()
        .onAppear {
            checkPath(silent: true)
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = NSLocalizedString("Seç", comment: "")
        
        if panel.runModal() == .OK, let url = panel.url {
            manager.cloudflaredExecutablePath = url.path
            checkPath()
        }
    }
    
    private func checkPath(silent: Bool = false) {
        let path = manager.cloudflaredExecutablePath.trimmingCharacters(in: .whitespacesAndNewlines)
        if FileManager.default.isExecutableFile(atPath: path) {
            statusMessage = NSLocalizedString("Cloudflared bulundu ve çalıştırılabilir.", comment: "")
            statusColor = .green
        } else {
            if !silent {
                statusMessage = NSLocalizedString("Belirtilen yolda çalıştırılabilir dosya bulunamadı.", comment: "")
                statusColor = .red
            }
        }
    }
}

struct MampStepView: View {
    @EnvironmentObject var manager: TunnelManager
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 50))
                .foregroundColor(.purple)
            
            Text(NSLocalizedString("MAMP Entegrasyonu", comment: ""))
                .font(.title2)
                .bold()
            
            Text(NSLocalizedString("MAMP kullanıyorsanız, projelerinizi otomatik algılamak için MAMP klasörünü seçin.", comment: ""))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading) {
                Text(NSLocalizedString("MAMP Ana Dizini:", comment: ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("/Applications/MAMP", text: $manager.mampBasePath)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(NSLocalizedString("Seç", comment: "")) {
                        selectFolder()
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Button(action: {
                withAnimation { currentStep += 1 }
            }) {
                Text(NSLocalizedString("MAMP Kullanmıyorum (Atla)", comment: ""))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .underline()
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
        .padding()
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = NSLocalizedString("Seç", comment: "")
        
        if panel.runModal() == .OK, let url = panel.url {
            manager.mampBasePath = url.path
        }
    }
}

struct FinishStepView: View {
    var onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text(NSLocalizedString("Kurulum Tamamlandı!", comment: ""))
                .font(.title)
                .bold()
            
            Text(NSLocalizedString("Artık tünellerinizi oluşturmaya ve yönetmeye başlayabilirsiniz.", comment: ""))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: onFinish) {
                Text(NSLocalizedString("Uygulamayı Başlat", comment: ""))
                    .font(.headline)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
        }
        .padding()
    }
}
