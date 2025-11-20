import Foundation
import AppKit

class MampManager {
    static let shared = MampManager()
    
    private init() {}
    
    // MARK: - Paths
    
    // These should be passed from TunnelManager or stored here if we move state.
    // For now, we'll accept paths as arguments to keep it stateless-ish.
    
    func scanMampSitesFolder(mampSitesDirectoryPath: String) -> [String] {
        guard FileManager.default.fileExists(atPath: mampSitesDirectoryPath) else {
            print("❌ MAMP site dizini bulunamadı: \(mampSitesDirectoryPath)")
            return []
        }
        var siteFolders: [String] = []
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: mampSitesDirectoryPath)
            for item in items {
                var isDirectory: ObjCBool = false
                let fullPath = "\(mampSitesDirectoryPath)/\(item)"
                if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory), isDirectory.boolValue, !item.starts(with: ".") {
                    siteFolders.append(item)
                }
            }
        } catch { print("❌ MAMP site dizini taranamadı: \(mampSitesDirectoryPath) - \(error)") }
        return siteFolders.sorted()
    }
    
    func fixMySQLSocket(completion: @escaping (Result<Void, Error>) -> Void) {
        let socketPath = "/Applications/MAMP/tmp/mysql/mysql.sock"
        
        // 1. MAMP MySQL Socket dosyasının varlığını kontrol et
        if !FileManager.default.fileExists(atPath: socketPath) {
            // Dosya yoksa, MAMP çalışmıyor olabilir.
            completion(.failure(NSError(domain: "MampManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "MAMP MySQL socket dosyası bulunamadı (\(socketPath)).\n\nOlası Nedenler:\n1. MAMP uygulaması açık değil.\n2. MAMP içinde MySQL sunucusu başlatılmamış (Start Servers'a basın).\n3. MAMP farklı bir klasöre kurulu."])))
            return
        }
        
        // 2. Hem /tmp hem de /var/mysql dizinlerine symlink oluşturmayı dene
        let script = """
        do shell script "mkdir -p /var/mysql && ln -sf \(socketPath) /tmp/mysql.sock && ln -sf \(socketPath) /var/mysql/mysql.sock" with administrator privileges
        """
        
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: script) {
                scriptObject.executeAndReturnError(&error)
                if let error = error {
                    let errorMsg = error["NSAppleScriptErrorMessage"] as? String ?? "Bilinmeyen hata"
                    completion(.failure(NSError(domain: "MampManager", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                } else {
                    completion(.success(()))
                }
            } else {
                completion(.failure(NSError(domain: "MampManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "AppleScript oluşturulamadı"])))
            }
        }
    }
    
    func updateMampVHost(mampVHostConfPath: String, serverName: String, documentRoot: String, port: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard FileManager.default.fileExists(atPath: documentRoot) else {
            completion(.failure(NSError(domain: "VHostError", code: 20, userInfo: [NSLocalizedDescriptionKey: "DocumentRoot bulunamadı: \(documentRoot)"]))); return
        }
        guard !serverName.isEmpty && serverName.contains(".") else {
            completion(.failure(NSError(domain: "VHostError", code: 21, userInfo: [NSLocalizedDescriptionKey: "Geçersiz ServerName: \(serverName)"]))); return
        }
        guard let portInt = Int(port), (1...65535).contains(portInt) else {
            completion(.failure(NSError(domain: "VHostError", code: 25, userInfo: [NSLocalizedDescriptionKey: "Geçersiz Port Numarası: \(port)"]))); return
        }
        let listenDirective = "*:\(port)"

        let vhostDir = (mampVHostConfPath as NSString).deletingLastPathComponent
        var isDir : ObjCBool = false
        if !FileManager.default.fileExists(atPath: vhostDir, isDirectory: &isDir) || !isDir.boolValue {
            print("⚠️ MAMP vHost dizini bulunamadı, oluşturuluyor: \(vhostDir)")
            do { try FileManager.default.createDirectory(atPath: vhostDir, withIntermediateDirectories: true, attributes: nil) } catch {
                 completion(.failure(NSError(domain: "VHostError", code: 22, userInfo: [NSLocalizedDescriptionKey: "MAMP vHost dizini oluşturulamadı: \(vhostDir)\n\(error.localizedDescription)"]))); return
            }
        }

        let vhostEntry = """

        # Added by Cloudflared Manager App for \(serverName) on port \(port)
        <VirtualHost \(listenDirective)>
            ServerName \(serverName)
            DocumentRoot "\(documentRoot)"
            # Optional Logs:
            # ErrorLog "/Applications/MAMP/logs/apache_\(serverName.replacingOccurrences(of: ".", with: "_"))_error.log"
            # CustomLog "/Applications/MAMP/logs/apache_\(serverName.replacingOccurrences(of: ".", with: "_"))_access.log" common
            <Directory "\(documentRoot)">
                Options Indexes FollowSymLinks MultiViews ExecCGI
                AllowOverride All
                Require all granted
            </Directory>
        </VirtualHost>

        """
        do {
            var currentContent = ""
            if FileManager.default.fileExists(atPath: mampVHostConfPath) {
                currentContent = try String(contentsOfFile: mampVHostConfPath, encoding: .utf8)
            } else {
                print("⚠️ vHost dosyası bulunamadı, yeni dosya oluşturulacak: \(mampVHostConfPath)")
                currentContent = "# Virtual Hosts\nNameVirtualHost \(listenDirective)\n\n"
            }

            let serverNamePattern = #"ServerName\s+\Q\#(serverName)\E"#
            let vhostBlockPattern = #"<VirtualHost\s+\*\:\#(port)>.*?\#(serverNamePattern).*?</VirtualHost>"#

            do {
                let regex = try NSRegularExpression(
                    pattern: vhostBlockPattern,
                    options: [.dotMatchesLineSeparators]
                )

                let searchRange = NSRange(currentContent.startIndex..<currentContent.endIndex, in: currentContent)
                if regex.firstMatch(in: currentContent, options: [], range: searchRange) != nil {
                    print("ℹ️ MAMP vHost dosyası zaten '\(serverName)' için \(listenDirective) portunda giriş içeriyor. Güncelleme yapılmadı.")
                    completion(.success(()))
                    return
                }
            } catch {
                print("❌ Regex Hatası: \(error.localizedDescription) - Desen: \(vhostBlockPattern)")
                completion(.failure(NSError(domain: "VHostError", code: 26, userInfo: [NSLocalizedDescriptionKey: "vHost kontrolü için regex oluşturulamadı: \(error.localizedDescription)"])))
                return
            }

            if !currentContent.contains("NameVirtualHost \(listenDirective)") && !currentContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if !currentContent.contains("NameVirtualHost ") {
                    currentContent = "# Virtual Hosts\nNameVirtualHost \(listenDirective)\n\n" + currentContent
                } else {
                    print("⚠️ Uyarı: vHost dosyasında başka NameVirtualHost direktifleri var. '\(listenDirective)' için direktif eklenmiyor. Manuel kontrol gerekebilir.")
                }
            }

            let newContent = currentContent + vhostEntry
            try newContent.write(toFile: mampVHostConfPath, atomically: true, encoding: .utf8)
            print("✅ MAMP vHost dosyası güncellendi: \(mampVHostConfPath) (Port: \(port))")
            completion(.success(()))

        } catch {
            print("❌ MAMP vHost dosyası güncellenirken HATA: \(error)")
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileWriteNoPermissionError {
                 completion(.failure(NSError(domain: "VHostError", code: 23, userInfo: [NSLocalizedDescriptionKey: "Yazma izni hatası: MAMP vHost dosyası güncellenemedi (\(mampVHostConfPath)). Lütfen dosya izinlerini kontrol edin veya manuel olarak ekleyin.\n\(error.localizedDescription)"])))
            } else {
                 completion(.failure(NSError(domain: "VHostError", code: 24, userInfo: [NSLocalizedDescriptionKey: "MAMP vHost dosyasına yazılamadı:\n\(error.localizedDescription)"])))
            }
        }
    }
    
    func updateMampHttpdConfListen(mampHttpdConfPath: String, port: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let portInt = Int(port), (1...65535).contains(portInt) else {
            completion(.failure(NSError(domain: "HttpdConfError", code: 30, userInfo: [NSLocalizedDescriptionKey: "Geçersiz Port Numarası: \(port)"])))
            return
        }
        let listenDirective = "Listen \(port)"
        let httpdPath = mampHttpdConfPath

        guard FileManager.default.fileExists(atPath: httpdPath) else {
            completion(.failure(NSError(domain: "HttpdConfError", code: 31, userInfo: [NSLocalizedDescriptionKey: "MAMP httpd.conf dosyası bulunamadı: \(httpdPath)"])))
            return
        }

        guard FileManager.default.isWritableFile(atPath: httpdPath) else {
             completion(.failure(NSError(domain: "HttpdConfError", code: 32, userInfo: [NSLocalizedDescriptionKey: "Yazma izni hatası: MAMP httpd.conf dosyası güncellenemedi (\(httpdPath)). İzinleri kontrol edin."])))
             return
        }

        do {
            var currentContent = try String(contentsOfFile: httpdPath, encoding: .utf8)

            let pattern = #"^\s*Listen\s+\#(portInt)\s*(?:#.*)?$"#
            if currentContent.range(of: pattern, options: .regularExpression) != nil {
                print("ℹ️ MAMP httpd.conf zaten '\(listenDirective)' içeriyor.")
                completion(.success(()))
                return
            }

            var insertionPoint = currentContent.endIndex
            let lastListenPattern = #"^\s*Listen\s+\d+"#
            if let lastListenMatchRange = currentContent.range(of: lastListenPattern, options: [.regularExpression, .backwards]) {
                if let lineEndRange = currentContent.range(of: "\n", options: [], range: lastListenMatchRange.upperBound..<currentContent.endIndex) {
                    insertionPoint = lineEndRange.upperBound
                } else {
                    if !currentContent.hasSuffix("\n") { currentContent += "\n" }
                    insertionPoint = currentContent.endIndex
                }
            } else {
                print("⚠️ MAMP httpd.conf içinde 'Listen' direktifi bulunamadı. Sona ekleniyor.")
                if !currentContent.hasSuffix("\n") { currentContent += "\n" }
                insertionPoint = currentContent.endIndex
            }

            let contentToInsert = "\n# Added by Cloudflared Manager App for port \(port)\n\(listenDirective)\n"
            currentContent.insert(contentsOf: contentToInsert, at: insertionPoint)

            try currentContent.write(toFile: httpdPath, atomically: true, encoding: .utf8)
            print("✅ MAMP httpd.conf güncellendi: '\(listenDirective)' direktifi eklendi.")
            completion(.success(()))

        } catch {
            print("❌ MAMP httpd.conf güncellenirken HATA: \(error)")
            completion(.failure(NSError(domain: "HttpdConfError", code: 33, userInfo: [NSLocalizedDescriptionKey: "MAMP httpd.conf okuma/yazma hatası: \(error.localizedDescription)"])))
        }
    }
    
    func fixPhpMyAdminConfig(completion: @escaping (Result<String, Error>) -> Void) {
        let binPath = "/Applications/MAMP/bin"
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: binPath) else {
            completion(.failure(NSError(domain: "MampManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "MAMP bin dizini bulunamadı."])))
            return
        }
        
        do {
            // phpMyAdmin klasörünü bul (phpMyAdmin5, phpMyAdmin vb.)
            let items = try fileManager.contentsOfDirectory(atPath: binPath)
            guard let phpMyAdminFolder = items.first(where: { $0.lowercased().contains("phpmyadmin") }) else {
                completion(.failure(NSError(domain: "MampManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "phpMyAdmin klasörü bulunamadı."])))
                return
            }
            
            let configPath = "\(binPath)/\(phpMyAdminFolder)/config.inc.php"
            guard fileManager.fileExists(atPath: configPath) else {
                completion(.failure(NSError(domain: "MampManager", code: 6, userInfo: [NSLocalizedDescriptionKey: "phpMyAdmin yapılandırma dosyası bulunamadı:\n\(configPath)"])))
                return
            }
            
            // Dosyayı oku
            var content = try String(contentsOfFile: configPath, encoding: .utf8)
            
            // Değişikliği yap: 'localhost' -> '127.0.0.1'
            // Hedef satır genellikle: $cfg['Servers'][$i]['host'] = 'localhost';
            if content.contains("'localhost'") {
                content = content.replacingOccurrences(of: "$cfg['Servers'][$i]['host'] = 'localhost';", with: "$cfg['Servers'][$i]['host'] = '127.0.0.1';")
                
                // Yazma izni kontrolü
                if fileManager.isWritableFile(atPath: configPath) {
                    try content.write(toFile: configPath, atomically: true, encoding: .utf8)
                    completion(.success(configPath))
                } else {
                    // İzin yoksa AppleScript ile dene
                    let script = """
                    do shell script "sed -i '' \\"s/\\$cfg\\['Servers'\\]\\[\\$i\\]\\['host'\\] = 'localhost';/\\$cfg\\['Servers'\\]\\[\\$i\\]\\['host'\\] = '127.0.0.1';/g\\" '\(configPath)'" with administrator privileges
                    """
                    DispatchQueue.global(qos: .userInitiated).async {
                        var error: NSDictionary?
                        if let scriptObject = NSAppleScript(source: script) {
                            scriptObject.executeAndReturnError(&error)
                            if let error = error {
                                let errorMsg = error["NSAppleScriptErrorMessage"] as? String ?? "Bilinmeyen hata"
                                completion(.failure(NSError(domain: "MampManager", code: 7, userInfo: [NSLocalizedDescriptionKey: "Yazma izni yoktu, yönetici olarak denendi ama başarısız oldu:\n\(errorMsg)"])))
                            } else {
                                completion(.success(configPath))
                            }
                        } else {
                            completion(.failure(NSError(domain: "MampManager", code: 8, userInfo: [NSLocalizedDescriptionKey: "AppleScript hatası."])))
                        }
                    }
                }
            } else if content.contains("'127.0.0.1'") {
                completion(.success(configPath)) // Zaten yapılmış
            } else {
                completion(.failure(NSError(domain: "MampManager", code: 9, userInfo: [NSLocalizedDescriptionKey: "Yapılandırma dosyasında değiştirilecek 'localhost' satırı bulunamadı. Manuel kontrol gerekebilir."])))
            }
            
        } catch {
            completion(.failure(error))
        }
    }
    
    func startMampServers(mampBasePath: String) {
        let scriptPath = "\(mampBasePath)/bin/start.sh" // Standard MAMP start script
        // Note: MAMP PRO might use different mechanisms. This is for standard MAMP.
        // Also, MAMP often requires password or runs as user.
        // A better approach for MAMP is often just opening the app or using `open -a MAMP`
        
        // Trying to open MAMP application first as it handles servers better
        let mampAppUrl = URL(fileURLWithPath: "/Applications/MAMP/MAMP.app")
        if FileManager.default.fileExists(atPath: mampAppUrl.path) {
            NSWorkspace.shared.open(mampAppUrl)
            print("🚀 MAMP uygulaması başlatıldı.")
        } else {
            // Fallback to script if app not found (unlikely for standard install)
            if FileManager.default.fileExists(atPath: scriptPath) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/sh")
                process.arguments = [scriptPath]
                try? process.run()
                print("🚀 MAMP start.sh çalıştırıldı.")
            } else {
                print("⚠️ MAMP başlatılamadı: Ne uygulama ne de script bulundu.")
            }
        }
    }
    
    func stopMampServers(mampBasePath: String) {
        let scriptPath = "\(mampBasePath)/bin/stop.sh"
        
        // Try script first for stopping
        if FileManager.default.fileExists(atPath: scriptPath) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = [scriptPath]
            try? process.run()
            print("🛑 MAMP stop.sh çalıştırıldı.")
        } else {
            // Fallback: Kill MAMP app
            let runningApps = NSWorkspace.shared.runningApplications
            for app in runningApps {
                if app.localizedName == "MAMP" {
                    app.terminate()
                    print("🛑 MAMP uygulaması kapatıldı.")
                }
            }
        }
    }
}
