//
//  INetwork.swift
//  NetworkingPackage
//
//  Created by Ali Zafar on 2024-10-17.
//
import Foundation

public protocol INetwork: AnyObject {
    
    func httpRequest<T: Decodable>(url: URL, headers: [String: String]?) async -> NetworkAPIResult<T>
    func httpDownload(url: URL) async -> NetworkAPIResult<URL>
    func httpRequestData(url: URL) async -> NetworkAPIResult<Data>
}

public extension INetwork {
    public func http<T: Decodable, Y: Encodable>(request: Request, method: HttpMethod = .GET,
                                          paths: [String]? = nil, queryItems: [URLQueryItem]? = nil,
                                                 requestBody: Y? = EmptyBody(), headers: [String: String] = RequestHeader.json.standard) async -> NetworkAPIResult<T> {
        // Default implementation or just call the main function with the given parameters
        if let network = self as? Network {
            return await network.http(request: request, method: method, paths: paths, queryItems: queryItems, requestBody: requestBody, headers: headers)
        }
        if let mock = self as? MockNetwork {
            return await mock.http(request: request, method: method, paths: paths, queryItems: queryItems, requestBody: requestBody, headers: headers)
        }
        return NetworkAPIResult.error(NetworkError.BadRequest)
    }
    
}
