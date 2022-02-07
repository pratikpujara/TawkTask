//
//  Router.swift
//  TAWKIOSTask
//
//  Created by Pratik on 04/02/22.
//

import Foundation


enum Router {
    
    case getUserList(body: String)
    case getUserProfile(body: String)

    static let baseURLString = AppConstants.baseURL
    
    private enum HTTPMethod {
        case get
        case post
        case put
        case patch
        case delete
        
        var value: String {
            switch self {
                case .get   : return "GET"
                case .post  : return "POST"
                case .put   : return "PUT"
                case .patch : return "PATCH"
                case .delete: return "DELETE"
            }
        }
    }
    
    private var method: HTTPMethod {
        switch self {
        case .getUserList:
            return .get
        case .getUserProfile:
            return .get
        }
    }
  
    private var endPoint: String {
        switch self {
        case .getUserList:
            return "users?since="
        case .getUserProfile:
            return "users/"
        }
    }
    
    func request() throws -> URLRequest {
        var urlString = "\(Router.baseURLString)\(endPoint)"
        
        if method == .get {
            switch self {
            case .getUserList(let body):
                urlString.append(body)
            case .getUserProfile(let body):
                urlString.append(body)
            default:
                print("No value")
            }
        }
        print("final url is here=======",urlString)
        
        guard let url = URL(string: urlString) else {
            throw ErrorType.parseUrlFail
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: Double.infinity)
        request.httpMethod = method.value
        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        return request
    }
    
    func getMimeType(str : String) -> String {
        if str == "mp4" {
            return "video/mp4"
        } else if str == "png" {
            return "image/png"
        } else if str == "pdf" {
            return "application/pdf"
        } else if str == "jpeg" {
            return "image/jpeg"
        } else if str == "jpg" {
            return "image/jpeg"
        } else if str == "doc" {
            return "application/msword"
        } else if str == "docx" {
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        }
        
        return ""
    }
}
