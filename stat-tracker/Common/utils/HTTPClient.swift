//
//  HTTPClient.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 3.4.2025.
//

import Foundation

enum NetworkError: Error {
    case badRequest
    case serverError(String)
    case decodingError(Error)
    case invalidResponse
    case invalidURL
    case offline
    case httpError(Int, String?)
    case unauthorized(String?)
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .badRequest:
            return "The server couldn't process that request."
        case let .serverError(errorMessage):
            return errorMessage
        case .decodingError:
            return "We couldn't read the server's response."
        case .invalidResponse:
            return "The server sent back an empty or invalid response."
        case .invalidURL:
            return "The request URL is invalid. Check the backend URL in Settings."
        case .offline:
            return "Can't reach the server. Check your connection or the backend URL in Settings."
        case let .httpError(statusCode, body):
            if let body, !body.isEmpty {
                return body
            }
            switch statusCode {
            case 400: return "Some required information is missing or invalid."
            case 403: return "You don't have permission to do that."
            case 404: return "Not found."
            case 409: return "Conflict – that action collides with existing data."
            case 500 ..< 600: return "The server ran into a problem (\(statusCode))."
            default: return "Request failed with status \(statusCode)."
            }
        case let .unauthorized(body):
            if let body, !body.isEmpty { return body }
            return "Your session has expired. Please log in again."
        }
    }
}

private struct ServerErrorBody: Decodable {
    let error: String?
    let message: String?
    var text: String? {
        let candidates = [error, message].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        return candidates.first(where: { !$0.isEmpty })
    }
}

private func extractServerMessage(from data: Data) -> String? {
    if let parsed = try? JSONDecoder().decode(ServerErrorBody.self, from: data),
       let text = parsed.text
    {
        return text
    }
    if let raw = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
       !raw.isEmpty,
       raw.count < 240
    {
        return raw
    }
    return nil
}

enum HTTPMethod {
    case get([URLQueryItem])
    case post(Data?)
    case delete

    var name: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        case .delete: return "DELETE"
        }
    }
}

struct Resource<T: Decodable> {
    let url: URL
    var method: HTTPMethod = .get([])
    var modelType: T.Type
}

/// Marker for endpoints that don't return a body (e.g. 204 No Content).
public struct EmptyResponse: Decodable {}

struct HTTPClient {
    static let shared = HTTPClient()
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
    }

    func load<T: Decodable>(_ resource: Resource<T>) async throws -> T {
        guard var request = URLSession.shared.constructRequest(
            with: resource.url.path,
            httpMethod: resource.method.name
        ) else {
            throw NetworkError.invalidURL
        }

        switch resource.method {
        case let .get(queryItems):
            if !queryItems.isEmpty {
                var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
                components?.queryItems = queryItems
                guard let finalURL = components?.url else {
                    throw NetworkError.invalidURL
                }
                request.url = finalURL
            }

        case let .post(data):
            request.httpBody = data

        case .delete:
            break
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            AppLogger.error("URLError \(urlError.code.rawValue) for \(resource.url.path): \(urlError.localizedDescription)", category: "Network")
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost,
                 .cannotConnectToHost, .timedOut, .dnsLookupFailed:
                throw NetworkError.offline
            default:
                throw NetworkError.serverError(urlError.localizedDescription)
            }
        }

        if let responseString = String(data: data, encoding: .utf8) {
            AppLogger.debug("HTTP \(resource.method.name) \(resource.url.path) → \(responseString)", category: "Network")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            let serverMessage = extractServerMessage(from: data)
            AppLogger.error("401 Unauthorized for \(resource.url.path): \(serverMessage ?? "no body")", category: "Network")
            throw NetworkError.unauthorized(serverMessage)
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let serverMessage = extractServerMessage(from: data)
            throw NetworkError.httpError(httpResponse.statusCode, serverMessage)
        }

        // Empty / 204 responses – return EmptyResponse() if the caller asked for it.
        if T.self == EmptyResponse.self {
            // swiftlint:disable:next force_cast
            return EmptyResponse() as! T
        }

        if data.isEmpty {
            throw NetworkError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .customISO8601
            return try decoder.decode(resource.modelType, from: data)
        } catch {
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case let .dataCorrupted(context):
                    AppLogger.error("Decoding – data corrupted: \(context.debugDescription) (path: \(context.codingPath))", category: "Decoding")
                case let .keyNotFound(key, context):
                    AppLogger.error("Decoding – key '\(key.stringValue)' missing: \(context.debugDescription) (path: \(context.codingPath))", category: "Decoding")
                case let .valueNotFound(type, context):
                    AppLogger.error("Decoding – value of '\(type)' missing: \(context.debugDescription) (path: \(context.codingPath))", category: "Decoding")
                case let .typeMismatch(type, context):
                    AppLogger.error("Decoding – type mismatch '\(type)': \(context.debugDescription) (path: \(context.codingPath))", category: "Decoding")
                @unknown default:
                    AppLogger.error("Decoding – unknown: \(error.localizedDescription)", category: "Decoding")
                }
            } else {
                AppLogger.error("Decoding error: \(error.localizedDescription)", category: "Decoding")
            }
            throw NetworkError.decodingError(error)
        }
    }
}

// MARK: - URLSession helpers

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
}

public protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSession: URLSessionProtocol {
    public func dataTask(with request: URLRequest,
                         completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
    {
        return (dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }

    public func constructRequest(with urlString: String, httpMethod: String = "GET") -> URLRequest? {
        guard let url = URL(string: Constants.API.URL + urlString) else {
            AppLogger.error("Failed to build URL from \(urlString)", category: "Network")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = AuthenticationManagerImpl.shared.authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

// MARK: - Error decoding

struct APIError: Codable, Error {
    let message: String?
    let error: String?
}
