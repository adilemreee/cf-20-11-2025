import SwiftUI

struct FileShareView: View {
    @EnvironmentObject var tunnelManager: TunnelManager
    @ObservedObject var fileServerManager = FileServerManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFolder: String = ""
    @State private var isSharing: Bool = false
    @State private var serverPort: Int?
    @State private var quickTunnelId: UUID?
    @State private var publicUrl: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("Hızlı Dosya Paylaşımı", comment: ""))
                        .font(.title2)
                        .bold()
                    Text(NSLocalizedString("Klasör seçin ve anında internete açın", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            // Folder Selection
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Paylaşılacak Klasör", comment: ""))
                    .font(.headline)
                
                HStack {
                    TextField(NSLocalizedString("Klasör Yolu", comment: ""), text: $selectedFolder)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(true)
                    
                    Button(action: selectFolder) {
                        Image(systemName: "folder")
                    }
                    .disabled(isSharing)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            // Status & Actions
            if isSharing {
                VStack(spacing: 16) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .animatePulse()
                        Text(NSLocalizedString("Yayında", comment: ""))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    if let url = publicUrl {
                        VStack(spacing: 8) {
                            Text(NSLocalizedString("Public URL", comment: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(url)
                                    .font(.title3)
                                    .bold()
                                    .textSelection(.enabled)
                                
                                Button(action: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(url, forType: .string)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(.plain)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    } else {
                        ProgressView(NSLocalizedString("Tünel oluşturuluyor...", comment: ""))
                    }
                    
                    Button(action: stopSharing) {
                        Text(NSLocalizedString("Paylaşımı Durdur", comment: ""))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Button(action: startSharing) {
                    HStack {
                        Image(systemName: "network")
                        Text(NSLocalizedString("Paylaşımı Başlat", comment: ""))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedFolder.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(selectedFolder.isEmpty)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 450, height: 500)
        .onChange(of: tunnelManager.quickTunnels) { _, tunnels in
            if let id = quickTunnelId, let tunnel = tunnels.first(where: { $0.id == id }), let url = tunnel.publicURL {
                self.publicUrl = url
            }
        }
    }
    
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = NSLocalizedString("Paylaşılacak Klasörü Seçin", comment: "")
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                self.selectedFolder = url.path
            }
        }
    }
    
    func startSharing() {
        guard !selectedFolder.isEmpty else { return }
        
        // 1. Find free port
        guard let port = PortChecker.shared.findFreePort() else { return }
        self.serverPort = port
        
        // 2. Start Python Server
        if fileServerManager.startServer(at: selectedFolder, port: port) {
            isSharing = true
            
            // 3. Start Quick Tunnel
            // Use 127.0.0.1 to match the server binding
            tunnelManager.startQuickTunnel(localURL: "http://127.0.0.1:\(port)") { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let id):
                        self.quickTunnelId = id
                    case .failure(let error):
                        print(NSLocalizedString("Hızlı tünel başlatılamadı", comment: "") + ": \(error.localizedDescription)")
                        // Hata durumunda sunucuyu da durdur
                        self.stopSharing()
                    }
                }
            }
        }
    }
    
    func stopSharing() {
        if let port = serverPort {
            fileServerManager.stopServer(port: port)
        }
        
        if let id = quickTunnelId {
            tunnelManager.stopQuickTunnel(id: id)
        }
        
        isSharing = false
        publicUrl = nil
        serverPort = nil
        quickTunnelId = nil
    }
}

extension View {
    func animatePulse() -> some View {
        self.modifier(PulseEffect())
    }
}

struct PulseEffect: ViewModifier {
    @State private var isOn = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isOn ? 1 : 0.5)
            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isOn)
            .onAppear {
                isOn = true
            }
    }
}
