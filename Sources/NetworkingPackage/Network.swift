//
//  Network.swift
//  elitesquads
//
//  Created by Ali Zafar on 3/12/23.
//

import Foundation
import Combine
import SwiftUI

public class Network {
    let configuration: URLSessionConfiguration
    let session: URLSession
    weak public var authManager: IAuthManager?
    
    public init() {
        self.configuration = URLSessionConfiguration.default
        self.configuration.timeoutIntervalForRequest = 10.0
        self.configuration.timeoutIntervalForResource = 30.0
        self.session = URLSession(configuration: configuration)
    }
    
    public func setAuthManager(autManager: IAuthManager) {
        self.authManager = autManager
    }
    
    private func createURLRequest<Y: Encodable>(request: Request, method: HttpMethod,
                                        paths: [String]?, queryItems: [URLQueryItem]?,
                                        requestBody: Y?, headers: [String: String]=RequestHeader.json.standard) async -> URLRequest? {
        var component = request.URLComponent
        component.queryItems = queryItems
        
        guard var url = component.url else {
            return nil
        }
        
        if let paths = paths {
            for path in paths {
                url = url.appending(path: path)
            }
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        
        for key in headers.keys {
            urlRequest.setValue(headers[key], forHTTPHeaderField: key)
        }
        
        if request.isAccessTokenRequired {
            guard let accessToken = request.AccessToken, let accessTokenKey = request.AccessTokenKey else {
                return nil
            }
            if request.isAccessTokenExpired {
                let _ = await authManager?.refreshTonken()
            }
            urlRequest.setValue(accessToken, forHTTPHeaderField: accessTokenKey)
        }
        
        if let requestBody = requestBody,  method == .POST || method == .PATCH  {
            urlRequest.httpBody = try? JSONEncoder().encode(requestBody)
        }
        return urlRequest
    }
    /**
     This method is used to call APIs and will be helpful to add access token and refresh token.
     */
    public func http<T: Decodable, Y: Encodable>(request: Request, method: HttpMethod = .GET,
                                                 paths: [String]? = nil, queryItems: [URLQueryItem]? = nil,
                                                 requestBody: Y? = ["": ""],
                                                 headers: [String: String] = RequestHeader.json.standard) async -> NetworkAPIResult<T> {
        
        guard var urlRequest = await createURLRequest(request: request,
                                                      method: method,
                                                      paths: paths,
                                                      queryItems: queryItems,
                                                      requestBody: requestBody,
                                                      headers: headers) else {
            return .error(NetworkError.InvalidRequest)
        }
        
        do {
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return (.error(NetworkError.requestFailed))
            }
            if httpResponse.statusCode == 401 {
                if let authManager = authManager {
                    let isRefresh = await authManager.refreshTonken()
                    if let accessToken = request.AccessToken, let key = request.AccessTokenKey, isRefresh {
                        urlRequest.setValue(accessToken, forHTTPHeaderField: key)
                        return await http(request: request, method: method, paths: paths,
                                          queryItems: queryItems, requestBody: requestBody,
                                          headers: headers)
                    }
                    return .error(NetworkError.UnAuthorized)
                }
            }
            if let dataString = String(data: data, encoding: .utf8), let object = try? JSONDecoder().decode(T.self, from: data) {
                print("Response String", dataString)
                return .success(object)
            }
            else if (200...299).contains(httpResponse.statusCode) {
                let object = try? JSONDecoder().decode(T.self, from: "{}".data(using: .utf8)!)
                return .success(object!)
            }
            return .error(NetworkError.errorForStatusCode(statusCode: httpResponse.statusCode))
        }
        catch (let error) {
            return .error(NetworkError.getServiceError(error: error as NSError, response: nil))
        }
        
    }
    /**
     - Simple http GET call for a given url. No authoriztion added
     */
    public func httpRequest<T: Decodable>(url: URL, headers: [String: String]?) async -> NetworkAPIResult<T> {
        do {
            var urlRequest = URLRequest(url: url)
            
            if let headers = headers {
                for key in headers.keys {
                    urlRequest.setValue(headers[key], forHTTPHeaderField: key)
                }
            }
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode), let dataString = String(data: data, encoding: .utf8) else {
                return (.error(NetworkError.requestFailed))
            }
            print(dataString)
            
            if let object = try? JSONDecoder().decode(T.self, from: data) {
                return .success(object)
            }
            return .error(NetworkError.responseDecodingFailed)
        }
        catch (let error) {
            return .error(NetworkError.requestError(error: error as NSError))
        }
    }
    
    public func httpDownload(url: URL) async -> NetworkAPIResult<URL> {
        do {
            let (downloadURL, response) = try await session.download(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return (.error(NetworkError.requestFailed))
            }
            let fileManager = FileManager.default
            guard let documentPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return .error(NetworkError.fileDownloadFailed)
            }
            let lastPathComponent = url.lastPathComponent
            let destinationURL = documentPath.appendingPathComponent(lastPathComponent)
            
            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.copyItem(at: downloadURL, to: destinationURL)
            } catch {
                return .error(NetworkError.fileDownloadFailed)
            }
            
            return .success(destinationURL)
        }
        catch(let error) {
            return .error(NetworkError.requestError(error: error as NSError))
        }
    }
    
    public func httpRequestData(url: URL) async -> NetworkAPIResult<Data> {
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode)  else {
                return (.error(NetworkError.requestFailed))
            }
            return .success(data)
        }
        catch(let error) {
            return .error(NetworkError.requestError(error: error as NSError))
        }
    }
    
    public func httpDownloadWithProgress(url: URL, progress: Binding<Float>) async -> NetworkAPIResult<URL> {
        do {
            let (asyncBytes, response) = try await session.bytes(from: url)
            let contentLength = Float(response.expectedContentLength)
            var data = Data(capacity: Int(contentLength))
            
            do {
                for try await byte in asyncBytes {
                    data.append(byte)
                    let currentProgress = Float (data.count)/Float(contentLength)
                    if(progress.wrappedValue * 100) != (currentProgress * 100) {
                        progress.wrappedValue = currentProgress
                    }
                }
                let fileManager = FileManager.default
                guard let documentpath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    return .error(NetworkError.fileSavingFailed)
                }
                let lastPathComponent = url.lastPathComponent
                let destinationURL = documentpath.appendingPathComponent(lastPathComponent)
                
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try data.write(to: destinationURL)
                return .success(destinationURL)
            }
            catch {
                return .error(NetworkError.fileDownloadFailed)
            }
        }
        catch (let error) {
            return .error(NetworkError.requestError(error: error as NSError))
        }
    }
}
