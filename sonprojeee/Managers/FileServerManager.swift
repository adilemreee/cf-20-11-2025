import Foundation
import Combine

class FileServerManager: ObservableObject {
    static let shared = FileServerManager()
    
    // [Port: Process] - Hangi portta hangi sunucu çalışıyor
    private var runningServers: [Int: Process] = [:]
    
    // [Port: DirectoryPath] - Hangi port hangi klasörü sunuyor
    @Published var activeFileShares: [Int: String] = [:]
    
    private init() {}
    
    func startServer(at path: String, port: Int) -> Bool {
        // Python 3'ün http.server modülünü kullanacağız
        
        // 1. Homebrew Python (Apple Silicon)
        // 2. Homebrew Python (Intel)
        // 3. System Python (Fallback - might have sandbox issues)
        let pythonPaths = [
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3"
        ]
        
        var executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        for p in pythonPaths {
            if FileManager.default.fileExists(atPath: p) {
                executableURL = URL(fileURLWithPath: p)
                print("🐍 Python bulundu: \(p)")
                break
            }
        }
        
        let process = Process()
        process.executableURL = executableURL
        
        // Use custom script if available, otherwise fallback to simple http.server
        if let scriptPath = createCustomServerScript() {
            // Run: python3 custom_script.py <PORT> <DIRECTORY>
            process.arguments = [scriptPath, String(port), path]
            print("🎨 Özel arayüzlü sunucu başlatılıyor...")
        } else {
            // Fallback
            process.arguments = ["-m", "http.server", String(port), "--bind", "127.0.0.1", "--directory", path]
        }
        
        // Ensure unbuffered output for better logging
        var env = ProcessInfo.processInfo.environment
        env["PYTHONUNBUFFERED"] = "1"
        process.environment = env
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Read output for debugging
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                print("[Python Server Port \(port)]: \(str.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
        
        process.terminationHandler = { proc in
            print("⚠️ Python sunucusu sonlandı. Kod: \(proc.terminationStatus)")
            pipe.fileHandleForReading.readabilityHandler = nil
        }
        
        do {
            try process.run()
            runningServers[port] = process
            
            DispatchQueue.main.async {
                self.activeFileShares[port] = path
            }
            
            print("📂 Dosya sunucusu başlatıldı: \(path) -> Port \(port)")
            return true
        } catch {
            print("❌ Dosya sunucusu başlatılamadı: \(error)")
            return false
        }
    }
    
    func stopServer(port: Int) {
        if let process = runningServers[port] {
            process.terminate()
            runningServers.removeValue(forKey: port)
            
            DispatchQueue.main.async {
                self.activeFileShares.removeValue(forKey: port)
            }
            print("🛑 Dosya sunucusu durduruldu: Port \(port)")
        }
    }
    
    func stopAllServers() {
        for port in runningServers.keys {
            stopServer(port: port)
        }
    }
    
    func isServerRunning(port: Int) -> Bool {
        return runningServers[port]?.isRunning == true
    }
    
    private func createCustomServerScript() -> String? {
        let scriptContent = """
import os
import sys
import http.server
import socketserver
import html
import urllib.parse
import io
import zipfile

# Arguments: 1=Port, 2=Directory
if len(sys.argv) < 3:
    sys.exit(1)

PORT = int(sys.argv[1])
DIRECTORY = sys.argv[2]

class BetterHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Parse query
        parsed = urllib.parse.urlparse(self.path)
        query = urllib.parse.parse_qs(parsed.query)
        
        if 'zip' in query:
            # Handle zip download
            path = self.translate_path(parsed.path)
            if os.path.isdir(path):
                self.serve_zip(path)
                return
                
        super().do_GET()

    def serve_zip(self, path):
        # Create zip in memory
        memory_file = io.BytesIO()
        dirname = os.path.basename(path.rstrip(os.sep))
        if not dirname: dirname = "download"
        
        with zipfile.ZipFile(memory_file, 'w', zipfile.ZIP_DEFLATED) as zf:
            for root, dirs, files in os.walk(path):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, path)
                    zf.write(file_path, arcname)
        
        memory_file.seek(0)
        self.send_response(200)
        self.send_header('Content-type', 'application/zip')
        self.send_header('Content-Disposition', 'attachment; filename="%s.zip"' % dirname)
        self.send_header('Content-Length', str(memory_file.getbuffer().nbytes))
        self.end_headers()
        self.wfile.write(memory_file.getvalue())

    def list_directory(self, path):
        try:
            list = os.listdir(path)
        except OSError:
            self.send_error(404, "No permission to list directory")
            return None
        list.sort(key=lambda a: a.lower())
        r = []
        try:
            displaypath = urllib.parse.unquote(self.path, errors='surrogatepass')
        except UnicodeDecodeError:
            displaypath = urllib.parse.unquote(self.path)
        displaypath = html.escape(displaypath, quote=False)
        enc = sys.getfilesystemencoding()
        title = 'Dosya Paylaşımı - %s' % displaypath
        
        r.append('<!DOCTYPE html>')
        r.append('<html>\\n<head>')
        r.append('<meta charset="utf-8">')
        r.append('<meta name="viewport" content="width=device-width, initial-scale=1">')
        r.append('<title>%s</title>\\n' % title)
        r.append('<style>')
        r.append('body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background-color: #f5f5f7; color: #1d1d1f; margin: 0; padding: 40px 20px; }')
        r.append('.container { max-width: 960px; margin: 0 auto; background: white; border-radius: 18px; box-shadow: 0 4px 24px rgba(0,0,0,0.05); overflow: hidden; }')
        r.append('.header { padding: 30px; background: #fff; border-bottom: 1px solid #e5e5e5; display: flex; align-items: center; justify-content: space-between; }')
        r.append('h1 { margin: 0; font-size: 20px; font-weight: 600; color: #1d1d1f; }')
        r.append('.file-list { list-style: none; margin: 0; padding: 0; }')
        r.append('.file-item { border-bottom: 1px solid #f0f0f0; transition: background 0.2s; display: flex; align-items: center; padding-right: 30px; }')
        r.append('.file-item:last-child { border-bottom: none; }')
        r.append('.file-item:hover { background-color: #f9f9f9; }')
        r.append('.file-link { display: flex; align-items: center; padding: 16px 30px; text-decoration: none; color: #1d1d1f; font-size: 15px; flex-grow: 1; }')
        r.append('.icon { margin-right: 15px; font-size: 24px; width: 30px; text-align: center; }')
        r.append('.name { flex-grow: 1; font-weight: 500; }')
        r.append('.meta { color: #86868b; font-size: 13px; margin-left: 20px; min-width: 80px; text-align: right; }')
        r.append('.download-btn { display: inline-flex; align-items: center; justify-content: center; width: 32px; height: 32px; border-radius: 50%; background-color: #f0f0f0; color: #007aff; text-decoration: none; transition: all 0.2s; margin-left: 10px; }')
        r.append('.download-btn:hover { background-color: #007aff; color: white; }')
        r.append('.footer { padding: 20px; text-align: center; color: #86868b; font-size: 12px; border-top: 1px solid #e5e5e5; background: #fafafa; }')
        r.append('</style>')
        r.append('</head>\\n<body>')
        r.append('<div class="container">')
        r.append('<div class="header"><h1>📂 %s</h1></div>' % displaypath)
        r.append('<ul class="file-list">')
        
        if self.path != '/':
            r.append('<li class="file-item"><a class="file-link" href="../"><span class="icon">↩️</span><span class="name">Üst Klasör</span></a></li>')
            
        for name in list:
            fullname = os.path.join(path, name)
            displayname = linkname = name
            is_dir = os.path.isdir(fullname)
            if is_dir:
                displayname = name + "/"
                linkname = name + "/"
                icon = "📁"
            elif os.path.islink(fullname):
                displayname = name + "@"
                icon = "🔗"
            else:
                icon = "📄"
                ext = os.path.splitext(name)[1].lower()
                if ext in ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg']: icon = "🖼️"
                elif ext in ['.mp4', '.mov', '.avi', '.mkv']: icon = "🎬"
                elif ext in ['.mp3', '.wav', '.m4a']: icon = "🎵"
                elif ext in ['.pdf']: icon = "📕"
                elif ext in ['.zip', '.rar', '.tar', '.gz', '.7z']: icon = "📦"
                elif ext in ['.txt', '.md', '.json', '.xml', '.html', '.css', '.js', '.py', '.swift']: icon = "📝"
                elif ext in ['.doc', '.docx', '.pages']: icon = "📘"
                elif ext in ['.xls', '.xlsx', '.numbers']: icon = "📊"
                elif ext in ['.ppt', '.pptx', '.key']: icon = "📽️"

            try:
                st = os.stat(fullname)
                size_str = self.format_size(st.st_size) if not is_dir else "-"
            except:
                size_str = ""

            link_url = urllib.parse.quote(linkname, errors='surrogatepass')
            download_html = ''
            if not is_dir:
                download_html = '<a class="download-btn" href="%s" download title="İndir">⬇️</a>' % link_url
            else:
                folder_url = link_url
                if not folder_url.endswith('/'): folder_url += '/'
                download_html = '<a class="download-btn" href="%s?zip=1" title="Zip Olarak İndir">📦</a>' % folder_url

            r.append('<li class="file-item"><a class="file-link" href="%s"><span class="icon">%s</span><span class="name">%s</span><span class="meta">%s</span></a>%s</li>'
                    % (link_url, icon, html.escape(displayname, quote=False), size_str, download_html))
        
        r.append('</ul>')
        r.append('<div class="footer">Cloudflared Manager ile Paylaşıldı</div>')
        r.append('</div>')
        r.append('</body>\\n</html>\\n')
        
        encoded = '\\n'.join(r).encode(enc, 'surrogateescape')
        f = io.BytesIO()
        f.write(encoded)
        f.seek(0)
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=%s" % enc)
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        return f

    def format_size(self, size):
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size < 1024:
                return f"{size:.1f} {unit}"
            size /= 1024
        return f"{size:.1f} TB"

os.chdir(DIRECTORY)
# Bind to 127.0.0.1 to match the app logic
with socketserver.TCPServer(("127.0.0.1", PORT), BetterHTTPRequestHandler) as httpd:
    print("serving at port", PORT)
    httpd.serve_forever()
"""
        let tempDir = FileManager.default.temporaryDirectory
        let scriptURL = tempDir.appendingPathComponent("custom_file_server.py")
        
        do {
            try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
            return scriptURL.path
        } catch {
            print("❌ Script dosyası oluşturulamadı: \(error)")
            return nil
        }
    }
}
