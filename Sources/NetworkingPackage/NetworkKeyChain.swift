//
//  NetworkKeyChain.swift
//  elitesquads
//
//  Created by Ali Zafar on 3/18/23.
//

import Foundation

class NetworkKeychain {
    static var accessToken: [String: String] = [:]
    static var refreshToken: [String: String] = [:]
    
    static func saveInt(value: Int, key: String) {
        let data = Data(from: value)
        let status = NetworkKeychain.save(key: key, data: data)
        print("status: ", status)
    }
    
    static func loadInt(key: String) -> Int? {
           if let receivedData = NetworkKeychain.load(key: key) {
               let result = receivedData.to(type: Int.self)
               return result
           }
           return nil
       }
        
    static func saveString(value: String, key: String) {
    let saveValue = value.data(using: String.Encoding.utf8)!
       let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : saveValue] as [String : Any]

        SecItemDelete(query as CFDictionary)

        let status =  SecItemAdd(query as CFDictionary, nil)
        print("status: ", status)
    }
        
    static func loadString(key: String) -> String? {
        let query = [
                   kSecClass as String       : kSecClassGenericPassword,
                   kSecAttrAccount as String : key,
                   kSecReturnData as String  : kCFBooleanTrue!,
                   kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]

        var item: CFTypeRef? = nil

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == noErr {
            
            if let valueData = item as? Data {
                if let returnString = String(data: valueData, encoding: .utf8) {
                    return returnString
                }
            }
           return nil
        }
        return nil
    }
        
    class func save(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ] as [String : Any]

        SecItemDelete(query as CFDictionary)

        return SecItemAdd(query as CFDictionary, nil)
    }
        
    class func removeAll() {
        let query: [String : Any] = [: ]
            
        SecItemDelete(query as CFDictionary)
            
    }
        
    class func removeKey(key: String) {
        let query = [
                kSecClass as String       : kSecClassGenericPassword as String,
                kSecAttrAccount as String : key]

                SecItemDelete(query as CFDictionary)
    }

    class func load(key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]

        var dataTypeRef: AnyObject? = nil

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr {
            return dataTypeRef as! Data?
        } else {
            return nil
        }
    }

    class func createUniqueID() -> String {
        let uuid: CFUUID = CFUUIDCreate(nil)
        let cfStr: CFString = CFUUIDCreateString(nil, uuid)

        let swiftString: String = cfStr as String
        return swiftString
    }
}

extension Data {

    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.load(as: T.self) }
    }
    
}
