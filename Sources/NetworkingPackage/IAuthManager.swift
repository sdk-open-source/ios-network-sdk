//
//  IAuthManager.swift
//  elitesquads
//
//  Created by Ali Zafar on 3/17/23.
//

import Foundation

public protocol IAuthManager: AnyObject {
    func refreshTonken() async -> Bool
}
