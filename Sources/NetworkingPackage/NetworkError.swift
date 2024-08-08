//
//  NetworkError.swift
//  elitesquads
//
//  Created by Ali Zafar on 3/12/23.
//

import Foundation

public enum NetworkError: String, Error {
    case InvalidRequest = "Request Sent is invalid."
    case requestFailed = "Request Failed."
    case UnAuthorized = "Your request is unauthorized."
    case RequestRequiresAccessToken = "Request require authorization."
    case InvalidResponse = "We received invalid response from service."
    case responseDecodingFailed = "We are unable to process response from service."
    case urlCreationFailed = "There is a problem with request creation."
    case fileDownloadFailed = "File downloading failed."
    case fileSavingFailed = "Unable to save file in the system."
    case RequestTimeOut = "Request Timed out."
    case NoInternet = "There is no internet connection"
    case NoDataConnection = "Unable to reach service. Please check your internet setting"
    case DomainError = "We are unable to reach service"
    case MovedPermanently = "There is an unexpected change in service"
    case NotModified = "Request is not modified"
    case Redirection = "Reponse is redirecting"
    case BadRequest = "Service is rejecting the request"
    case Forbidden = "Service is forbidden"
    case NotFound = "Unable to locate service"
    case ClientError = "Some error ocured while requesting the service"
    case ServerInternalError = "There is a problem with the service."
    case ServiceUnavailable = "Service not available at the moment."
    case ServerError = "Our service have unexpected error."
    case UnKnownError = "There is some unexpected error in the service."
   
    
    static func requestError(error: NSError) -> NetworkError
    {
        let code = error.code
        if code == -1020 {
            return .NoDataConnection
        }
        else if code == -1001 {
            return .RequestTimeOut
        }
        return .requestFailed
    }
    
    static func getServiceError(error: NSError, response: URLResponse?) -> NetworkError {
        
        let code = error.code
        
        switch code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorDataNotAllowed:
            return .NoInternet
        case NSURLErrorTimedOut:
            return .RequestTimeOut
        case NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateHasBadDate,
            NSURLErrorServerCertificateUntrusted, NSURLErrorServerCertificateHasUnknownRoot,
            NSURLErrorServerCertificateNotYetValid, NSURLErrorClientCertificateRejected,
            NSURLErrorClientCertificateRequired, NSURLErrorCannotLoadFromNetwork,
            NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost, NSURLErrorUnsupportedURL, NSURLErrorBadURL:
            return .DomainError
        default:
            guard let response = response as? HTTPURLResponse else {
                return .InvalidResponse
            }
            return errorForStatusCode(statusCode: response.statusCode)
        }
        
    }
    
    static func errorForStatusCode(statusCode: Int) -> NetworkError {
        
        switch statusCode {
        
        case 301:
            return .MovedPermanently
        case 304:
            return .NotModified
        case 300..<400:
            return .Redirection
        
        case 400:
            return .BadRequest
        case 401:
            return .UnAuthorized
        case 403:
            return .Forbidden
        case 404:
            return .NotFound
        case 400..<500:
            return .ClientError
       
        case 500:
            return .ServerInternalError
        case 503:
            return .ServiceUnavailable
        case 500..<600:
            return .ServerError
        default:
            return .UnKnownError
            
        }
    }
    
  }
