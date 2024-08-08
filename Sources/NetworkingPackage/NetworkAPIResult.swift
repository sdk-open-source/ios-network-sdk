//
//  APIResult.swift
//  elitesquads
//
//  Created by Ali Zafar on 3/12/23.
//

import Foundation

public enum NetworkAPIResult<T> {
    case success(T)
    case error(Error)
}
