import Foundation

final class SyncService {
    static let shared = SyncService()
    private init() {}

    func syncRuns(completion: @escaping (Result<Void, Error>) -> Void) {
        StravaAuthService.shared.getAccessToken { tokenResult in
            switch tokenResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let token):
                // Fetch activities from the past week
                let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                
                StravaAPIClient.shared.fetchAthleteActivities(
                    accessToken: token,
                    after: oneWeekAgo,
                    perPage: 200
                ) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let activities):
                        let newRuns: [Run] = activities
                            .filter { $0.type == "Run" } // Only include running activities
                            .map { activity in
                                Run(
                                    id: String(activity.id),
                                    name: activity.name,
                                    type: activity.type,
                                    sportType: activity.sportType,
                                    date: activity.startDateLocal, // Use local date for better timezone handling
                                    distance: activity.distance / 1000.0, // Convert meters to km
                                    movingTime: activity.movingTime,
                                    averageSpeed: activity.averageSpeed,
                                    calories: activity.calories,
                                    redeemed: false
                                )
                            }
                        RunStorage.shared.appendRuns(newRuns)
                        RunStorage.shared.lastSync = Date()
                        completion(.success(()))
                    }
                }
            }
        }
    }
}


