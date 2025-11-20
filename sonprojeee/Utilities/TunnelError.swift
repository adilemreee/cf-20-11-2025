import Foundation

enum TunnelError: LocalizedError {
    case cloudflaredNotFound(path: String)
    case configFileNotFound(path: String)
    case portConflict(port: Int, conflictingProcess: String?)
    case mampPermissionDenied(file: String)
    case mampFileNotFound(path: String)
    case tunnelAlreadyRunning(name: String)
    case tunnelCreationFailed(reason: String)
    case processStartFailed(reason: String)
    case invalidConfiguration(reason: String)
    case networkError(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .cloudflaredNotFound(let path):
            return "cloudflared bulunamadı: \(path)"
        case .configFileNotFound(let path):
            return "Yapılandırma dosyası bulunamadı: \(path)"
        case .portConflict(let port, let process):
            if let process = process {
                return "Port \(port) zaten kullanımda: \(process)"
            }
            return "Port \(port) zaten kullanımda"
        case .mampPermissionDenied(let file):
            return "MAMP dosyasına yazma izni yok: \(file)"
        case .mampFileNotFound(let path):
            return "MAMP dosyası bulunamadı: \(path)"
        case .tunnelAlreadyRunning(let name):
            return "Tünel '\(name)' zaten çalışıyor"
        case .tunnelCreationFailed(let reason):
            return "Tünel oluşturulamadı: \(reason)"
        case .processStartFailed(let reason):
            return "İşlem başlatılamadı: \(reason)"
        case .invalidConfiguration(let reason):
            return "Geçersiz yapılandırma: \(reason)"
        case .networkError(let reason):
            return "Ağ hatası: \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .cloudflaredNotFound(let path):
            return """
            Çözüm Adımları:
            1. cloudflared'i indirin: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/
            2. Settings → Paths bölümünden doğru yolu ayarlayın
            3. Veya Terminal'de: brew install cloudflare/cloudflare/cloudflared
            
            Beklenen konum: \(path)
            """
        case .configFileNotFound:
            return "Yapılandırma dosyasının mevcut olduğundan emin olun."
        case .portConflict(let port, let process):
            var suggestion = """
            Çözüm Seçenekleri:
            1. Farklı bir port kullanın (örn: \(port + 1))
            2. Çakışan servisi durdurun
            """
            if process != nil {
                suggestion += "\n3. Terminal'de: lsof -ti:\(port) | xargs kill -9"
            }
            return suggestion
        case .mampPermissionDenied(let file):
            return """
            Çözüm Adımları:
            1. Terminal'i açın
            2. Komutu çalıştırın:
               sudo chmod 644 '\(file)'
            3. Admin şifrenizi girin
            4. Uygulamayı tekrar deneyin
            
            Alternatif: 'Manuel Yapılandırma' seçeneğini kullanın
            """
        case .mampFileNotFound(let path):
            return """
            MAMP düzgün kurulmamış olabilir.
            
            Kontrol Edilecekler:
            1. MAMP yüklü mü? → /Applications/MAMP
            2. Settings → Paths → MAMP yolunu kontrol edin
            3. Dosya mevcut mu? → \(path)
            """
        case .tunnelAlreadyRunning:
            return "Tüneli durdurup tekrar başlatmayı deneyin."
        case .tunnelCreationFailed(let reason):
            return "Hata detayı: \(reason)\nCloudflare hesabınızı ve ağ bağlantınızı kontrol edin."
        case .processStartFailed:
            return "Sistem kaynaklarını kontrol edin ve tekrar deneyin."
        case .invalidConfiguration:
            return "Yapılandırma dosyasını kontrol edin veya yeniden oluşturun."
        case .networkError:
            return "İnternet bağlantınızı kontrol edin ve tekrar deneyin."
        }
    }
}
