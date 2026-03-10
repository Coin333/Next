import Foundation
import Network

// MARK: - Network Monitor
/// Monitors network connectivity status.
/// Provides real-time updates on connection availability.
final class NetworkMonitor: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = NetworkMonitor()
    
    // MARK: - Published Properties
    
    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    // MARK: - Connection Type
    
    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
    }
    
    // MARK: - Private Properties
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.next.networkmonitor")
    
    // MARK: - Initialization
    
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring
    
    /// Starts monitoring network connectivity
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
                
                Logger.shared.debug("Network status: \(path.status == .satisfied ? "connected" : "disconnected")")
            }
        }
        
        monitor.start(queue: queue)
        Logger.shared.info("Network monitoring started")
    }
    
    /// Stops monitoring network connectivity
    func stopMonitoring() {
        monitor.cancel()
        Logger.shared.info("Network monitoring stopped")
    }
    
    // MARK: - Helper Methods
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        }
        return .unknown
    }
    
    /// Checks if the network is currently available
    func checkConnection() -> Bool {
        return isConnected
    }
}
