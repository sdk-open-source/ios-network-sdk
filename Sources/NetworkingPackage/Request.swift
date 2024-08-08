//
//  Request.swift
//  elitesquads
//
//  Created by Ali Zafar on 3/15/23.
//

import Foundation

public enum RequestHeader: String {
    
    case urlEncoding = "application/x-www-form-urlencoded"
    case json = "application/json"
    
    public var standard: [String: String] {
        switch self {
        case .json:
            return ["Content-Type": rawValue]
        case .urlEncoding:
            return ["Content-Type": rawValue]
        }
       
    }
}

public enum HttpMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

public protocol Request {
    var Url: URL? { get }
    var RefreshUrl: String { get }
    var Scheme: String { get }
    var Environment: String { get }
    var Host: String{ get }
    var API: String { get }
    var Path: String { get }
    var BaseUrl: String { get }
    var AccessToken: String? { get set }
    var RefreshToken: String? { get set }
    var AccessTokenKey: String? { get }
    var SignOutAppIfUnAuthorized: Bool { get }
    var SignOutNotificationName: Notification.Name { get }
    var SignOut: Bool { get }
    var isAccessTokenRequired: Bool { get }
    var isAccessTokenExpired: Bool { get }
}

public extension Request {
    var URLComponent: URLComponents {
        var components = URLComponents()
                components.scheme = Scheme
                components.host = Host
                components.path = Path
                return components
    }
    var Url: URL? {
        let urlString = "\(Scheme)://\(Environment)\(Host)\(Path)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL: ", "\(Scheme)://\(Environment)\(Host)\(Path)")
            return nil
        }
        return url
    }
    var BaseUrl: String {
        return "\(Scheme)://\(Environment)\(Host)"
    }
    var SignOutAppIfUnAuthorized: Bool {
        return true
    }
    
    var AccessToken: String? {
        get {
            if let token = NetworkKeychain.accessToken[AccessTokenKey ?? "default"] {
                return token
            }
            if let token = NetworkKeychain.loadString(key: "\(AccessTokenKey ?? ""):\(NetworkConstants.AccessToken)") {
                NetworkKeychain.accessToken[AccessTokenKey ?? "default"] = token
                return token
            }
            return nil
        }
        set {
            NetworkKeychain.saveString(value: newValue ?? "", key: "\(AccessTokenKey ?? ""):\(NetworkConstants.AccessToken)")
            NetworkKeychain.accessToken[AccessTokenKey ?? "default"] = newValue
        }
    }
    
    var RefreshToken: String? {
        get{
            if let token = NetworkKeychain.refreshToken[AccessTokenKey ?? "default"] {
                return token
            }
            if let token = NetworkKeychain.loadString(key: "\(AccessTokenKey ?? ""):\(NetworkConstants.RefreshToken)") {
               NetworkKeychain.refreshToken[AccessTokenKey ?? "default"] = token
               return token
            }
            return nil
        }
        set {
            NetworkKeychain.saveString(value: newValue ?? "", key: "\(AccessTokenKey ?? ""):\(NetworkConstants.RefreshToken)")
            NetworkKeychain.refreshToken[AccessTokenKey ?? "default"] = newValue
        }
    }
}
