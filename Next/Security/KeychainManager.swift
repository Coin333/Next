import Foundation
import Security

// MARK: - Keychain Manager
/// Securely stores and retrieves sensitive data using iOS Keychain.
/// Used primarily for storing the AI API key.
final class KeychainManager {
    
    // MARK: - Singleton
    
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Keychain Keys
    
    private enum KeychainKey: String {
        case apiKey = "com.next.sage.apiKey"
    }
    
    // MARK: - Error Types
    
    enum KeychainError: LocalizedError {
        case duplicateItem
        case itemNotFound
        case unexpectedData
        case unhandledError(status: OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .duplicateItem:
                return "Item already exists in Keychain"
            case .itemNotFound:
                return "Item not found in Keychain"
            case .unexpectedData:
                return "Unexpected data format in Keychain"
            case .unhandledError(let status):
                return "Keychain error: \(status)"
            }
        }
    }
    
    // MARK: - API Key Management
    
    /// Stores the API key securely in Keychain
    /// - Parameter apiKey: The API key to store
    func saveAPIKey(_ apiKey: String) throws {
        let data = Data(apiKey.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: KeychainKey.apiKey.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        Logger.shared.info("API key saved to Keychain")
    }
    
    /// Retrieves the API key from Keychain
    /// - Returns: The stored API key, or nil if not found
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: KeychainKey.apiKey.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return apiKey
    }
    
    /// Deletes the API key from Keychain
    func deleteAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: KeychainKey.apiKey.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
        
        Logger.shared.info("API key deleted from Keychain")
    }
    
    /// Checks if an API key is stored
    var hasAPIKey: Bool {
        return getAPIKey() != nil
    }
}
