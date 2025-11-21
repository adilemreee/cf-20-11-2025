import SwiftUI
import AppKit

struct CreateFromDockerView: View {
    @EnvironmentObject var tunnelManager: TunnelManager
    @StateObject private var dockerManager = DockerManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedContainer: DockerContainer?
    @State private var selectedPort: String = ""
    @State private var hostname: String = ""
    @State private var tunnelName: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Docker Konteynerleri")
                        .font(.title2.bold())
                    Text(NSLocalizedString("Çalışan konteynerlerden tünel oluşturun", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { dockerManager.fetchContainers() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            HStack(spacing: 0) {
                // List
                VStack {
                    if dockerManager.containers.isEmpty {
                        VStack(spacing: 12) {
                            if dockerManager.isDockerRunning {
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text(NSLocalizedString("Çalışan konteyner bulunamadı.", comment: ""))
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                Text(NSLocalizedString("Docker çalışmıyor veya bulunamadı.", comment: ""))
                                    .foregroundColor(.primary)
                                Text(NSLocalizedString("Lütfen Docker Desktop uygulamasını başlatın.", comment: ""))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            Button("Yenile") {
                                dockerManager.checkDockerStatus { _ in
                                    dockerManager.fetchContainers()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(dockerManager.containers, selection: $selectedContainer) { container in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(container.name)
                                        .font(.headline)
                                    Text(container.image)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if !container.ports.isEmpty {
                                    Text(container.ports.joined(separator: ", "))
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.vertical, 4)
                            .tag(container)
                        }
                        .listStyle(.inset)
                    }
                }
                .frame(width: 250)
                
                Divider()
                
                // Configuration
                VStack(alignment: .leading, spacing: 20) {
                    if let container = selectedContainer {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(NSLocalizedString("Yapılandırma: ", comment: "") + "\(container.name)")
                                    .font(.headline)
                                
                                Group {
                                    Text("Tünel Adı")
                                        .font(.caption).bold()
                                    TextField("Tünel Adı", text: $tunnelName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                Group {
                                    Text("Port")
                                        .font(.caption).bold()
                                    if container.ports.count > 1 {
                                        Picker("", selection: $selectedPort) {
                                            ForEach(container.ports, id: \.self) { port in
                                                Text(port).tag(port)
                                            }
                                        }
                                    } else {
                                        TextField("Port", text: $selectedPort)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                }
                                
                                Group {
                                    Text("Hostname")
                                        .font(.caption).bold()
                                    TextField("örn: app.alanadiniz.com", text: $hostname)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                if let error = errorMessage {
                                    Text(error)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                                
                                if showSuccess {
                                    Text(NSLocalizedString("✅ Tünel başarıyla oluşturuldu!", comment: ""))
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                                
                                Spacer()
                                
                                Button(action: createTunnel) {
                                    if isLoading {
                                        ProgressView().scaleEffect(0.5)
                                    } else {
                                        Text("Tünel Oluştur")
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(hostname.isEmpty || selectedPort.isEmpty || tunnelName.isEmpty || isLoading)
                            }
                            .padding()
                        }
                    } else {
                        VStack {
                            Text(NSLocalizedString("Soldan bir konteyner seçin", comment: ""))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            }
        }
        .frame(width: 600, height: 400)
        .onAppear {
            dockerManager.checkDockerStatus { _ in
                dockerManager.fetchContainers()
            }
        }
        .onChange(of: selectedContainer) { _, newValue in
            if let container = newValue {
                tunnelName = container.name
                if let firstPort = container.ports.first {
                    selectedPort = firstPort
                } else {
                    selectedPort = ""
                }
                errorMessage = nil
                showSuccess = false
            }
        }
    }
    
    private func createTunnel() {
        guard selectedContainer != nil else { return }
        isLoading = true
        errorMessage = nil
        
        // 1. Create Tunnel
        tunnelManager.createTunnel(name: tunnelName) { result in
            switch result {
            case .success(let data):
                // 2. Create Config File
                let configName = "\(tunnelName).yml"
                tunnelManager.createConfigFile(
                    configName: configName,
                    tunnelUUID: data.uuid,
                    credentialsPath: data.jsonPath,
                    hostname: hostname,
                    port: selectedPort,
                    documentRoot: nil
                ) { configResult in
                    DispatchQueue.main.async {
                        isLoading = false
                        switch configResult {
                        case .success:
                            showSuccess = true
                            // Refresh list
                            tunnelManager.findManagedTunnels()
                            // Close window after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        case .failure(let error):
                            errorMessage = "Config hatası: \(error.localizedDescription)"
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Tünel oluşturma hatası: \(error.localizedDescription)"
                }
            }
        }
    }
}
