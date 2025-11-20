import Foundation

// MARK: - Port Conflict Detection

class PortChecker {
    static let shared = PortChecker()
    
    private init() {}
    
    /// Check if a port is available
    func isPortAvailable(_ port: Int) -> Bool {
        let socketFD = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFD != -1 else { return false }
        
        defer { close(socketFD) }
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(port).bigEndian
        addr.sin_addr.s_addr = INADDR_ANY
        
        let bindResult = withUnsafePointer(to: &addr) { ptr -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(socketFD, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        return bindResult == 0
    }
    
    /// Find process using a port
    func findProcessUsingPort(_ port: Int) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-i", ":\(port)", "-sTCP:LISTEN"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                // Parse lsof output to get process name
                let lines = output.components(separatedBy: "\n")
                if lines.count > 1 {
                    let fields = lines[1].components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if fields.count > 0 {
                        return fields[0] // Process name
                    }
                }
            }
        } catch {
            print("⚠️ Port kontrolü yapılamadı: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Check port and return detailed result
    func checkPort(_ port: Int) -> Result<Void, TunnelError> {
        if isPortAvailable(port) {
            return .success(())
        } else {
            let conflictingProcess = findProcessUsingPort(port)
            return .failure(.portConflict(port: port, conflictingProcess: conflictingProcess))
        }
    }
    
    /// Find next available port starting from given port
    func findAvailablePort(startingFrom port: Int, maxAttempts: Int = 100) -> Int? {
        for testPort in port..<(port + maxAttempts) {
            if isPortAvailable(testPort) {
                return testPort
            }
        }
        return nil
    }
    
    /// Find the first available port starting from a given number
    func findFreePort(startingFrom startPort: Int = 50000) -> Int? {
        for port in startPort...65535 {
            if isPortAvailable(port) {
                return port
            }
        }
        return nil
    }
    
    /// Find a free port in a range
    func findFreePort(startPort: Int = 8000, endPort: Int = 9000) -> Int? {
        for port in startPort...endPort {
            if isPortAvailable(port) {
                return port
            }
        }
        return nil
    }
}
