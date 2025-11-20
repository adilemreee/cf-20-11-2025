import Foundation
import Combine

struct TunnelMetrics {
    var bytesIn: Double = 0
    var bytesOut: Double = 0
    var totalRequests: Int = 0
    var activeConnections: Int = 0
    var timestamp: Date = Date()
}

class MetricsManager: ObservableObject {
    static let shared = MetricsManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    // Cache for metrics per tunnel ID
    @Published var metrics: [UUID: TunnelMetrics] = [:]
    
    private init() {}
    
    func fetchMetrics(for tunnelId: UUID, port: Int) {
        guard let url = URL(string: "http://127.0.0.1:\(port)/metrics") else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .replaceError(with: Data())
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] data in
                guard let self = self else { return }
                
                if let content = String(data: data, encoding: .utf8), !content.isEmpty {
                    // print("📊 Metrics received for port \(port): \(content.count) bytes") // Debug log
                    let parsed = self.parsePrometheusMetrics(content)
                    DispatchQueue.main.async {
                        self.metrics[tunnelId] = parsed
                    }
                } else {
                    print("⚠️ Metrics fetch failed or empty for port \(port)")
                }
            }
            .store(in: &cancellables)
    }
    
    private func parsePrometheusMetrics(_ content: String) -> TunnelMetrics {
        var metrics = TunnelMetrics()
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            if line.hasPrefix("#") { continue }
            let parts = line.components(separatedBy: " ")
            guard parts.count >= 2, let value = Double(parts.last ?? "") else { continue }
            
            // Handle cloudflared_tunnel_total_bytes with direction label (newer versions)
            if line.contains("cloudflared_tunnel_total_bytes") {
                if line.contains("direction=\"rx\"") || line.contains("direction=\"in\"") {
                    metrics.bytesIn += value
                } else if line.contains("direction=\"tx\"") || line.contains("direction=\"out\"") {
                    metrics.bytesOut += value
                }
            }
            // Fallback for older metric names (explicit _in / _out)
            else if line.contains("cloudflared_tunnel_total_bytes_in") {
                metrics.bytesIn += value
            } else if line.contains("cloudflared_tunnel_total_bytes_out") {
                metrics.bytesOut += value
            }
            
            // Total Requests
            if line.contains("cloudflared_tunnel_total_requests") || line.contains("cloudflared_tunnel_requests") {
                metrics.totalRequests += Int(value)
            }
            
            // Active Connections / Streams
            if line.contains("cloudflared_tunnel_active_streams") || 
               line.contains("cloudflared_tunnel_concurrent_requests") ||
               line.contains("cloudflared_tunnel_active_requests") {
                metrics.activeConnections += Int(value)
            }
        }
        
        return metrics
    }
}
