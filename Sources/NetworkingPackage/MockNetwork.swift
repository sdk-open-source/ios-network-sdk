//
//  NetworkMoc.swift
//  NetworkingPackage
//
//  Created by Ali Zafar on 2024-10-17.
//

import Foundation

public class MockNetwork: INetwork {
    let responseDict: [String: Any]
    
    public init() {
        self.responseDict = MockNetwork.loadPlist() ?? [: ]
    }
    

    public func http<T: Decodable, Y: Encodable>(request: Request, method: HttpMethod = .GET,
                                          paths: [String]? = nil, queryItems: [URLQueryItem]? = nil,
                                                 requestBody: Y? = EmptyBody(), headers: [String: String] = RequestHeader.json.standard) async -> NetworkAPIResult<T> {
        
        guard let url = request.Url?.absoluteString else {
            return (NetworkAPIResult.error(NetworkError.BadRequest))
        }
        guard let dict = responseDict[url] as? [String: Any] else {
            return (NetworkAPIResult.error(NetworkError.BadRequest))
        }
        if let  fileName = dict[method.rawValue] as? String {
            return readFileContent(fileName: fileName)
            
        }
        return (NetworkAPIResult.error(NetworkError.BadRequest))
    }
    
    public func httpRequest<T>(url: URL, headers: [String : String]?) async -> NetworkAPIResult<T> where T : Decodable {
        return decodeJSON(from: "")
    }
    
    public func httpDownload(url: URL) async -> NetworkAPIResult<URL> {
        return decodeJSON(from: "")
    }
    
    public func httpRequestData(url: URL) async -> NetworkAPIResult<Data> {
        return decodeJSON(from: "")
    }
    
    private func readFileContent<T: Decodable>(fileName: String) -> NetworkAPIResult<T> {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Failed to locate the file.")
            return (NetworkAPIResult.error(NetworkError.BadRequest))
        }
        
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let object = try decoder.decode(T.self, from: jsonData)
            return .success(object)
        } catch {
            print("Error reading JSON data: \(error)")
            return (NetworkAPIResult.error(NetworkError.InvalidResponse))
        }
        return (NetworkAPIResult.error(NetworkError.InvalidResponse))
    }
    
    private func decodeJSON<T: Decodable>(from jsonString: String) -> NetworkAPIResult<T> {
        guard let jsonData = jsonString.data(using: .utf8) else {
                print("Failed to convert JSON string to Data.")
            return (NetworkAPIResult.error(NetworkError.BadRequest))
        }
        let decoder = JSONDecoder()
            do {
                let object = try decoder.decode(T.self, from: jsonData)
                return .success(object)
            } catch {
                print("Failed to decode JSON: \(error)")
                return (NetworkAPIResult.error(NetworkError.InvalidResponse))
            }
    }
    
    static private func loadPlist() -> [String: Any]? {
        guard let url = Bundle.main.url(forResource: "MockResponse", withExtension: "plist") else {
            print("MockResponse.plist not found.")
            return nil
        }
    
        do {
            let data = try Data(contentsOf: url)
            // Deserialize the plist data into a dictionary
            if let dictionary = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                return dictionary
            }
        } catch {
            print("Error reading plist: \(error)")
        }
        
        return nil
    }
    
    
}
