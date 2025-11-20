import Foundation

struct DockerContainer: Identifiable, Hashable {
    let id: String
    let name: String
    let image: String
    let status: String
    let ports: [String]
}

class DockerManager: ObservableObject {
    static let shared = DockerManager()
    @Published var containers: [DockerContainer] = []
    @Published var isDockerRunning: Bool = false
    
    private init() {}
    
    func checkDockerStatus(completion: @escaping (Bool) -> Void) {
        // Check if docker command exists and daemon is running
        runDockerCommand(arguments: ["info"]) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.isDockerRunning = true
                    completion(true)
                case .failure:
                    self.isDockerRunning = false
                    completion(false)
                }
            }
        }
    }
    
    func fetchContainers() {
        // Format: ID|Names|Image|Status|Ports
        let format = "{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}"
        runDockerCommand(arguments: ["ps", "--format", format]) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let output):
                    self?.parseContainers(output)
                case .failure(let error):
                    print("Docker fetch error: \(error)")
                    self?.containers = []
                }
            }
        }
    }
    
    private func parseContainers(_ output: String) {
        var newContainers: [DockerContainer] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines where !line.isEmpty {
            let parts = line.components(separatedBy: "|")
            if parts.count >= 5 {
                let id = parts[0]
                let name = parts[1]
                let image = parts[2]
                let status = parts[3]
                let portsRaw = parts[4]
                
                // Parse ports (e.g., "0.0.0.0:6379->6379/tcp")
                // We want to extract the public facing port (e.g. 6379)
                let ports = self.extractPorts(portsRaw)
                
                newContainers.append(DockerContainer(id: id, name: name, image: image, status: status, ports: ports))
            }
        }
        self.containers = newContainers
    }
    
    private func extractPorts(_ raw: String) -> [String] {
        // Example: "0.0.0.0:80->80/tcp, :::80->80/tcp"
        // We want "80"
        var ports: [String] = []
        let items = raw.components(separatedBy: ",")
        for item in items {
            if let arrowIndex = item.range(of: "->")?.lowerBound {
                let leftSide = item[..<arrowIndex] // "0.0.0.0:80" or ":::80"
                if let colonIndex = leftSide.lastIndex(of: ":") {
                    let port = String(leftSide[leftSide.index(after: colonIndex)...])
                    if !ports.contains(port) {
                        ports.append(port)
                    }
                }
            }
        }
        return ports
    }
    
    private func runDockerCommand(arguments: [String], completion: @escaping (Result<String, Error>) -> Void) {
        let possiblePaths = ["/usr/local/bin/docker", "/opt/homebrew/bin/docker", "/usr/bin/docker"]
        guard let dockerPath = possiblePaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            completion(.failure(NSError(domain: "DockerManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Docker executable not found"])))
            return
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: dockerPath)
        process.arguments = arguments
        
        // Environment is important for Docker
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = env
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe // Capture error too
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if process.terminationStatus == 0 {
                completion(.success(output))
            } else {
                completion(.failure(NSError(domain: "DockerManager", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output])))
            }
        } catch {
            completion(.failure(error))
        }
    }
}
