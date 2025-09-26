import Foundation

struct StravaAthlete: Codable {
    let id: Int
    let firstname: String?
    let lastname: String?
}

struct StravaActivity: Codable {
    let id: Int
    let name: String
    let distance: Double
    let movingTime: Int
    let type: String
    let sportType: String
    let startDate: Date
    let startDateLocal: Date
    let timezone: String?
    let averageSpeed: Double?
    let maxSpeed: Double?
    let calories: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, distance, type, timezone, calories
        case movingTime = "moving_time"
        case startDate = "start_date"
        case startDateLocal = "start_date_local"
        case sportType = "sport_type"
        case averageSpeed = "average_speed"
        case maxSpeed = "max_speed"
    }
}

struct StravaSummaryStats: Codable {
    let allRunTotals: StravaTotals?
    let allRideTotals: StravaTotals?

    enum CodingKeys: String, CodingKey {
        case allRunTotals = "all_run_totals"
        case allRideTotals = "all_ride_totals"
    }
}

struct StravaTotals: Codable {
    let count: Int
    let distance: Double
    let movingTime: Int

    enum CodingKeys: String, CodingKey {
        case count, distance
        case movingTime = "moving_time"
    }
}

final class StravaAPIClient {
    static let shared = StravaAPIClient()
    private init() {}
    
    private let config = ConfigurationService.shared

    private var baseURL: URL {
        return config.stravaBaseURL
    }

    private func makeRequest(path: String, accessToken: String, queryItems: [URLQueryItem] = []) -> URLRequest {
        var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty { comps.queryItems = queryItems }
        var request = URLRequest(url: comps.url!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    func fetchAthleteStats(athleteId: Int, accessToken: String, completion: @escaping (Result<StravaSummaryStats, Error>) -> Void) {
        let request = makeRequest(path: "athletes/\(athleteId)/stats", accessToken: accessToken)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { return completion(.failure(error)) }
            guard let data = data else { return completion(.failure(NSError(domain: "api", code: -1))) }
            do {
                let decoder = JSONDecoder()
                let stats = try decoder.decode(StravaSummaryStats.self, from: data)
                completion(.success(stats))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchRecentActivities(accessToken: String, perPage: Int = 30, completion: @escaping (Result<[StravaActivity], Error>) -> Void) {
        var query: [URLQueryItem] = [URLQueryItem(name: "per_page", value: String(perPage))]
        let request = makeRequest(path: "athlete/activities", accessToken: accessToken, queryItems: query)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { return completion(.failure(error)) }
            guard let data = data else { return completion(.failure(NSError(domain: "api", code: -2))) }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let activities = try decoder.decode([StravaActivity].self, from: data)
                completion(.success(activities))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// Fetches athlete activities with date filtering
    /// - Parameters:
    ///   - accessToken: Strava access token
    ///   - before: Unix timestamp for activities before this date (optional)
    ///   - after: Unix timestamp for activities after this date (optional)
    ///   - perPage: Number of activities per page (max 200)
    ///   - page: Page number (default 1)
    ///   - completion: Completion handler with activities or error
    func fetchAthleteActivities(accessToken: String, before: Date? = nil, after: Date? = nil, perPage: Int = 200, page: Int = 1, completion: @escaping (Result<[StravaActivity], Error>) -> Void) {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "per_page", value: String(min(perPage, 200))),
            URLQueryItem(name: "page", value: String(page))
        ]
        
        if let before = before {
            queryItems.append(URLQueryItem(name: "before", value: String(Int(before.timeIntervalSince1970))))
        }
        
        if let after = after {
            queryItems.append(URLQueryItem(name: "after", value: String(Int(after.timeIntervalSince1970))))
        }
        
        let request = makeRequest(path: "athlete/activities", accessToken: accessToken, queryItems: queryItems)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                return completion(.failure(error))
            }
            
            guard let data = data else {
                return completion(.failure(NSError(domain: "api", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let activities = try decoder.decode([StravaActivity].self, from: data)
                completion(.success(activities))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}


