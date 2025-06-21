//
//  HTTPClient.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 3.4.2025.
//

import Foundation

enum NetworkError: Error {
    case badRequest
    case serverError(String)
    case decodingError(Error)
    case invalidResponse
    case invalidURL
    case httpError(Int)
    case unauthorized
}

extension NetworkError: LocalizedError {

    var errorDescription: String? {
        switch self {
            case .badRequest:
                return NSLocalizedString("Unable to perform request", comment: "badRequestError")
            case .serverError(let errorMessage):
                return NSLocalizedString(errorMessage, comment: "serverError")
            case .decodingError:
                return NSLocalizedString("Unable to decode successfully.", comment: "decodingError")
            case .invalidResponse:
                return NSLocalizedString("Invalid response", comment: "invalidResponse")
            case .invalidURL:
                return NSLocalizedString("Invalid URL", comment: "invalidURL")
            case .httpError(let statusCode):
                return NSLocalizedString("HTTP Error \(statusCode)", comment: "httpError")
            case .unauthorized:
                return NSLocalizedString("Authentication required or expired.", comment: "unauthorizedError")
        }
    }
}

enum HTTPMethod {
    case get([URLQueryItem])
    case post(Data?)
    case delete
    
    var name: String {
        switch self {
            case .get:
                return "GET"
            case .post:
                return "POST"
            case .delete:
                return "DELETE"
        }
    }
}

struct Resource<T: Codable> {
    let url: URL
    var method: HTTPMethod = .get([])
    var modelType: T.Type
}

struct HTTPClient {
    
    static let shared = HTTPClient()
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        // Removed default "Content-Type" here as constructRequest will add it
        self.session = URLSession(configuration: configuration)
    }
    
    func load<T: Codable>(_ resource: Resource<T>) async throws -> T {
        guard var request = URLSession.shared.constructRequest(with: resource.url.path, httpMethod: resource.method.name) else {
            if AuthenticationManagerImpl.shared.authToken == nil {
                throw NetworkError.unauthorized
            }
            throw NetworkError.badRequest
        }
        
        switch resource.method {
            case .get(let queryItems):
                var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                components?.queryItems = queryItems
                guard let finalURL = components?.url else {
                    throw NetworkError.invalidURL
                }
                request.url = finalURL
                
            case .post(let data):
                request.httpBody = data
              
            case .delete:
                break
        }
            
        let (data, response) = try await session.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            AppLogger.debug("Raw HTTP Response Data for \(resource.url.absoluteString):\n\(responseString)", category: "Network")
        } else {
            AppLogger.debug("Raw HTTP Response Data for \(resource.url.absoluteString): (Unable to decode as UTF-8 string)", category: "Network")
            AppLogger.debug("Raw bytes: \(data as NSData)", category: "Network")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
        }
            
        if httpResponse.statusCode == 401 {
            AppLogger.error("Received 401 Unauthorized for URL: \(resource.url.absoluteString)", category: "Network")
            throw NetworkError.unauthorized
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
            
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .customISO8601
            let result = try decoder.decode(resource.modelType, from: data)
            return result
        } catch {
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    AppLogger.error("Decoding error - Data corrupted: \(context.debugDescription) (Coding path: \(context.codingPath))", category: "Decoding")
                case .keyNotFound(let key, let context):
                    AppLogger.error("Decoding error - Key '\(key.stringValue)' not found: \(context.debugDescription) (Coding path: \(context.codingPath))", category: "Decoding")
                case .valueNotFound(let type, let context):
                    AppLogger.error("Decoding error - Value of type '\(type)' not found: \(context.debugDescription) (Coding path: \(context.codingPath))", category: "Decoding")
                case .typeMismatch(let type, let context):
                    AppLogger.error("Decoding error - Type mismatch for type '\(type)': \(context.debugDescription) (Coding path: \(context.codingPath))", category: "Decoding")
                @unknown default:
                    AppLogger.error("Decoding error - Unknown error: \(error.localizedDescription)", category: "Decoding")
                }
            } else {
                AppLogger.error("Decoding error: \(error.localizedDescription)", category: "Decoding")
            }
            throw NetworkError.decodingError(error)
        }
    }
}

// MARK: - Protocols for URLSession (No changes here, keeping as provided)

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
}

public protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSession: URLSessionProtocol {
    public func dataTask(with request: URLRequest,
                             completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        return (dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }
    
    public func constructRequest(with urlString: String, httpMethod: String = "GET") -> URLRequest? {
        guard let url = URL(string: Constants.API.URL + urlString) else {
            AppLogger.error("Failed to create URL from string: \(urlString)", category: "Network")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = AuthenticationManagerImpl.shared.authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            // Only return nil (failure to construct) if it's an authenticated endpoint
            // and no token is present, BUT NOT for the login endpoint itself.
            if !urlString.contains(Constants.API.Auth.login) {
                AppLogger.error("Attempted to construct authenticated request for \(urlString) without an auth token.", category: "Network")
                return nil
            }
        }
        return request
    }
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

// MARK: Error

struct APIError: Codable, Error {
    let message: String
}
