//
//  PlayerManager.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import Foundation

protocol UserManager {
    func saveGame(_ game: Game) async throws
    func fetchGamesForPlayer() -> [Game]?
    func fetchOwnUser()
}

final class UserManagerImpl: UserManager {
    private let urlSession: URLSessionProtocol = URLSession.shared
    
    func saveGame(_ game: Game) {
        // todo
    }
    
    func fetchGamesForPlayer() -> [Game]? {
        return nil
    }
    
    public func fetchOwnUser() {
        guard let request = constructRequest(with: Constants.API.URL + Constants.API.User.getOwnUser) else {
            AppLogger.debug("Error creating request")
            return
        }
        
        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                AppLogger.debug("error fetching user information: " + error.localizedDescription)
                return
            }
            
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                return
            }
            
            AppLogger.debug("HTTP response: \(httpResponse.allHeaderFields)", category: "Network")
            
            if httpResponse.statusCode == 200 {
                
            }
            
        }
    }
}

// MARK: Helper functions

extension UserManagerImpl {
    private func constructRequest(with path: String) -> URLRequest? {
        guard let url = URL(string: path) else {
            AppLogger.debug("Error creating URL")
            return nil
        }
        
        guard let token = UserDefaults.value(forKey: Constants.UserDefaultsKeys.authToken) else {
            AppLogger.debug("No auth token found")
            return nil
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: token) else {
            AppLogger.debug("Error serializing JSON")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        return request
    }
}
