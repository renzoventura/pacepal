import Foundation

final class ConfigurationService {
    static let shared = ConfigurationService()
    private init() {}
    
    private var configuration: [String: Any] = [:]
    
    func loadConfiguration() {
        guard let path = Bundle.main.path(forResource: "Configuration", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            fatalError("Configuration.plist not found or invalid format")
        }
        configuration = plist
    }
    
    func string(for key: String) -> String {
        guard let value = configuration[key] as? String else {
            fatalError("Configuration key '\(key)' not found or not a string")
        }
        return value
    }
    
    func url(for key: String) -> URL {
        let stringValue = string(for: key)
        guard let url = URL(string: stringValue) else {
            fatalError("Configuration key '\(key)' is not a valid URL: \(stringValue)")
        }
        return url
    }
    
    // MARK: - Strava Configuration
    var stravaClientId: String {
        return string(for: "StravaClientId")
    }
    
    var stravaClientSecret: String {
        return string(for: "StravaClientSecret")
    }
    
    var stravaRedirectScheme: String {
        return string(for: "StravaRedirectScheme")
    }
    
    var stravaRedirectHost: String {
        return string(for: "StravaRedirectHost")
    }
    
    var stravaRedirectPath: String {
        return string(for: "StravaRedirectPath")
    }
    
    var stravaBaseURL: URL {
        return url(for: "StravaBaseURL")
    }
    
    var stravaAuthURL: URL {
        return url(for: "StravaAuthURL")
    }
    
    // MARK: - Keychain Keys
    var keychainAccessTokenKey: String {
        return string(for: "KeychainAccessTokenKey")
    }
    
    var keychainRefreshTokenKey: String {
        return string(for: "KeychainRefreshTokenKey")
    }
    
    var keychainExpiresAtKey: String {
        return string(for: "KeychainExpiresAtKey")
    }
}
