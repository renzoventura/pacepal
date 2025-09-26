import Foundation
import AuthenticationServices

struct StravaTokenResponse: Codable {
    let tokenType: String?
    let accessToken: String
    let expiresAt: TimeInterval
    let refreshToken: String
    let athlete: StravaAthlete?

    enum CodingKeys: String, CodingKey {
        case tokenType = "token_type"
        case accessToken = "access_token"
        case expiresAt = "expires_at"
        case refreshToken = "refresh_token"
        case athlete
    }
}

final class StravaAuthService: NSObject {
    static let shared = StravaAuthService()
    
    private let config = ConfigurationService.shared

    var clientId: String {
        return config.stravaClientId
    }
    
    var clientSecret: String {
        return config.stravaClientSecret
    }
    
    var redirectScheme: String {
        return config.stravaRedirectScheme
    }
    
    var redirectHost: String {
        return config.stravaRedirectHost
    }
    
    var redirectPath: String {
        return config.stravaRedirectPath
    }

    private var keyAccessToken: String {
        return config.keychainAccessTokenKey
    }
    
    private var keyRefreshToken: String {
        return config.keychainRefreshTokenKey
    }
    
    private var keyExpiresAt: String {
        return config.keychainExpiresAtKey
    }

    private var currentSession: ASWebAuthenticationSession?

    var redirectURI: String {
        //your_app_scheme://<Authorization Callback Domain>
        return "pacepal://127.0.0.1"
        return "pacepal://pacepal"
        return "\(redirectScheme)://\(redirectHost)\(redirectPath)"
    }

    func authorize(completion: @escaping (Result<Void, Error>) -> Void) {
        let scope = "activity:read_all"
        let state = UUID().uuidString
        var comps = URLComponents(string: "https://www.strava.com/oauth/mobile/authorize")!
        comps.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "state", value: state)
        ]

        guard let url = comps.url else { return completion(.failure(NSError(domain: "auth", code: -1))) }

        currentSession = ASWebAuthenticationSession(url: url, callbackURLScheme: redirectScheme) { [weak self] callbackURL, error in
            guard error == nil, let callbackURL else {
                return completion(.failure(error ?? NSError(domain: "auth", code: -2)))
            }
            self?.handleCallback(url: callbackURL, completion: completion)
        }
        currentSession?.presentationContextProvider = self
        currentSession?.start()
    }

    func handleCallback(url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = comps.queryItems,
              let code = items.first(where: { $0.name == "code" })?.value else {
            return completion(.failure(NSError(domain: "auth", code: -3)))
        }
        exchangeCodeForToken(code: code, completion: completion)
    }

    private func exchangeCodeForToken(code: String, completion: @escaping (Result<Void, Error>) -> Void) {
        var request = URLRequest(url: config.stravaAuthURL)
        request.httpMethod = "POST"
        let body: [String: Any] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { return completion(.failure(error)) }
            guard let data = data else { return completion(.failure(NSError(domain: "auth", code: -4))) }
            do {
                let token = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
                try KeychainService.shared.set(token.accessToken, for: self.keyAccessToken)
                try KeychainService.shared.set(token.refreshToken, for: self.keyRefreshToken)
                UserDefaults.standard.set(token.expiresAt, forKey: self.keyExpiresAt)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func getAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        do {
            if let token = try KeychainService.shared.get(keyAccessToken) {
                let expiresAt = UserDefaults.standard.double(forKey: keyExpiresAt)
                if Date().timeIntervalSince1970 < expiresAt - 60 {
                    return completion(.success(token))
                }
            }
            refreshToken(completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    private func refreshToken(completion: @escaping (Result<String, Error>) -> Void) {
        do {
            guard let refreshToken = try KeychainService.shared.get(keyRefreshToken) else {
                return completion(.failure(NSError(domain: "auth", code: -5)))
            }

            var request = URLRequest(url: config.stravaAuthURL)
            request.httpMethod = "POST"
            let body: [String: Any] = [
                "client_id": clientId,
                "client_secret": clientSecret,
                "grant_type": "refresh_token",
                "refresh_token": refreshToken
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error { return completion(.failure(error)) }
                guard let data = data else { return completion(.failure(NSError(domain: "auth", code: -7))) }
                do {
                    let token = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
                    try KeychainService.shared.set(token.accessToken, for: self.keyAccessToken)
                    try KeychainService.shared.set(token.refreshToken, for: self.keyRefreshToken)
                    UserDefaults.standard.set(token.expiresAt, forKey: self.keyExpiresAt)
                    completion(.success(token.accessToken))
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }

    func logout() {
        try? KeychainService.shared.delete(keyAccessToken)
        try? KeychainService.shared.delete(keyRefreshToken)
        UserDefaults.standard.removeObject(forKey: keyExpiresAt)
    }
    
    // For testing: Clear all app data including Keychain
    func clearAllData() {
        logout()
        // Clear all UserDefaults
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
        // Clear all Keychain items (this is more aggressive)
        let secItemClasses = [kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity]
        for secItemClass in secItemClasses {
            let dictionary = [kSecClass as String: secItemClass]
            SecItemDelete(dictionary as CFDictionary)
        }
    }

    // Checks if there is a currently valid session. Will attempt refresh if needed.
    func hasValidSession(completion: @escaping (Bool) -> Void) {
        getAccessToken { result in
            switch result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
        }
    }
}

extension StravaAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}


