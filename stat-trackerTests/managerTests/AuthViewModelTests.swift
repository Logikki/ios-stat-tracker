import XCTest
import Combine
@testable import stat_tracker

// MARK: - Mocking URLSession for Testing

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
}

public protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSession: URLSessionProtocol {
    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        return (dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

class MockURLSession: URLSessionProtocol {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    var request: URLRequest?

    init(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
        self.data = data
        self.response = response
        self.error = error
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        self.request = request
        return MockURLSessionDataTask {
            completionHandler(self.data, self.response, self.error)
        }
    }
}

class MockURLSessionDataTask: URLSessionDataTaskProtocol {
    private let closure: () -> Void

    init(closure: @escaping () -> Void) {
        self.closure = closure
    }

    func resume() {
        closure()
    }
}

// MARK: - Helper extension for creating JSON strings
extension Dictionary where Key == String, Value == String {
    func jsonString() -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }
}

// MARK: - Minimal AuthViewModel, AuthResponse, Credentials, and Error Types for Testability

struct AuthResponse: Codable {
    let token: String
    let username: String
    let name: String
}

struct Credentials: Codable {
    let username: String
    let password: String
}

struct BackendError: Codable, Error {
    let message: String
}

enum AuthViewModelError: Error, LocalizedError {
    case invalidURL
    case invalidServerResponse
    case failedToDecodeResponse
    case requestError(Error)
    case backendError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidServerResponse:
            return "Invalid server response"
        case .failedToDecodeResponse:
            return "Failed to decode response"
        case .requestError(let error):
            return "Request error: \(error.localizedDescription)"
        case .backendError(let message):
            return message
        }
    }
}

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String? = nil

    private let baseURL: String
    private let urlSession: URLSessionProtocol
    private var cancellables = Set<AnyCancellable>()

    init(baseURL: String = "http://your-backend-url.com", urlSession: URLSessionProtocol = URLSession.shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        if UserDefaults.standard.string(forKey: "authToken") != nil {
            self.isAuthenticated = true
        }
    }

    func login(credentials: Credentials) {
        errorMessage = nil

        guard let url = URL(string: self.baseURL + Constants.API.Auth.login) else {
            errorMessage = AuthViewModelError.invalidURL.localizedDescription
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONEncoder().encode(credentials)
            request.httpBody = jsonData
        } catch {
            errorMessage = "Failed to encode credentials"
            return
        }

        urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = AuthViewModelError.requestError(error).localizedDescription
                    self?.isAuthenticated = false
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = AuthViewModelError.invalidServerResponse.localizedDescription
                    self?.isAuthenticated = false
                    return
                }

                guard let data = data else {
                    self?.errorMessage = AuthViewModelError.invalidServerResponse.localizedDescription
                    self?.isAuthenticated = false
                    return
                }

                if httpResponse.statusCode == 200 {
                    do {
                        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                        UserDefaults.standard.set(authResponse.token, forKey: "authToken")
                        self?.isAuthenticated = true
                        self?.errorMessage = nil
                    } catch {
                        self?.errorMessage = AuthViewModelError.failedToDecodeResponse.localizedDescription
                        self?.isAuthenticated = false
                    }
                } else {
                    do {
                        let backendError = try JSONDecoder().decode(BackendError.self, from: data)
                        self?.errorMessage = AuthViewModelError.backendError(backendError.message).localizedDescription
                        self?.isAuthenticated = false
                    } catch {
                        self?.errorMessage = "Authentication failed with status code: \(httpResponse.statusCode)"
                        self?.isAuthenticated = false
                    }
                }
            }
        }.resume()
    }
}

// MARK: - AuthViewModel Tests

final class AuthViewModelTests: XCTestCase {

    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        cancellables = Set<AnyCancellable>()
        UserDefaults.standard.removeObject(forKey: "authToken")
    }

    override func tearDownWithError() throws {
        cancellables = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
    }

    func testLoginSuccess() throws {
        let expectedToken = "test_auth_token_123"
        let expectedUsername = "testuser"
        let expectedName = "Test User"
        let authResponse = AuthResponse(token: expectedToken, username: expectedUsername, name: expectedName)
        let jsonData = try JSONEncoder().encode(authResponse)

        // Updated mock response URL to match the new AuthViewModel baseURL
        let mockResponse = HTTPURLResponse(url: URL(string: "http://your-backend-url.com" + Constants.API.Auth.login)!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let mockSession = MockURLSession(data: jsonData, response: mockResponse, error: nil)

        let viewModel = AuthViewModel(urlSession: mockSession)
        let credentials = Credentials(username: "testuser", password: "password")

        let expectation = XCTestExpectation(description: "Login successful expectation")

        viewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    XCTAssertTrue(isAuthenticated)
                    XCTAssertNil(viewModel.errorMessage)
                    XCTAssertEqual(UserDefaults.standard.string(forKey: "authToken"), expectedToken)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.login(credentials: credentials)

        wait(for: [expectation], timeout: 1.0)
    }

    func testLoginFailure_InvalidCredentials() throws {
        let errorJson = ["message": "Invalid username or password"].jsonString()?.data(using: .utf8)
        // Updated mock response URL to match the new AuthViewModel baseURL
        let mockResponse = HTTPURLResponse(url: URL(string: "http://your-backend-url.com" + Constants.API.Auth.login)!, statusCode: 401, httpVersion: nil, headerFields: nil)
        let mockSession = MockURLSession(data: errorJson, response: mockResponse, error: nil)

        let viewModel = AuthViewModel(urlSession: mockSession)
        let credentials = Credentials(username: "wronguser", password: "wrongpassword")

        let expectation = XCTestExpectation(description: "Login failure expectation")

        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage)
                XCTAssertFalse(viewModel.isAuthenticated)
                XCTAssertEqual(errorMessage, "Invalid username or password")
                XCTAssertNil(UserDefaults.standard.string(forKey: "authToken"))
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.login(credentials: credentials)

        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoginFailure_NetworkError() throws {
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let mockSession = MockURLSession(data: nil, response: nil, error: networkError)

        let viewModel = AuthViewModel(urlSession: mockSession)
        let credentials = Credentials(username: "testuser", password: "password")

        let expectation = XCTestExpectation(description: "Network error expectation")

        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage)
                XCTAssertFalse(viewModel.isAuthenticated)
                XCTAssertEqual(errorMessage, "Request error: The Internet connection appears to be offline.")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.login(credentials: credentials)

        wait(for: [expectation], timeout: 1.0)
    }

    func testLoginFailure_InvalidServerResponse() throws {
        let mockSession = MockURLSession(data: nil, response: nil, error: nil)

        let viewModel = AuthViewModel(urlSession: mockSession)
        let credentials = Credentials(username: "testuser", password: "password")

        let expectation = XCTestExpectation(description: "Invalid server response expectation")

        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage)
                XCTAssertFalse(viewModel.isAuthenticated)
                XCTAssertEqual(errorMessage, "Invalid server response")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.login(credentials: credentials)

        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoginFailure_FailedToDecodeResponse() throws {
        let invalidJson = "{\"notAToken\": \"abc\"}".data(using: .utf8)
        // Updated mock response URL to match the new AuthViewModel baseURL
        let mockResponse = HTTPURLResponse(url: URL(string: "http://your-backend-url.com" + Constants.API.Auth.login)!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let mockSession = MockURLSession(data: invalidJson, response: mockResponse, error: nil)

        let viewModel = AuthViewModel(urlSession: mockSession)
        let credentials = Credentials(username: "testuser", password: "password")

        let expectation = XCTestExpectation(description: "Failed to decode response expectation")

        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage)
                XCTAssertFalse(viewModel.isAuthenticated)
                XCTAssertEqual(errorMessage, "Failed to decode response")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.login(credentials: credentials)

        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLogin_InvalidURL() {
        let viewModel = AuthViewModel(baseURL: "invalid-url-string", urlSession: MockURLSession())
        let credentials = Credentials(username: "testuser", password: "password")

        let expectation = XCTestExpectation(description: "Invalid URL error expectation")

        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage)
                XCTAssertEqual(errorMessage, "Invalid URL")
                XCTAssertFalse(viewModel.isAuthenticated)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.login(credentials: credentials)

        wait(for: [expectation], timeout: 1.0)
    }

    func testAuthViewModelInitializationWithExistingToken() {
        let expectedToken = "existing_auth_token_456"
        UserDefaults.standard.set(expectedToken, forKey: "authToken")

        let viewModel = AuthViewModel(urlSession: MockURLSession())

        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.errorMessage)
    }
}
