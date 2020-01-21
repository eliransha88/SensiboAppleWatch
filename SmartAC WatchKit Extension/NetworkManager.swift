//
//  NetworkManager.swift
//  ForeScout-POC
//
//  Created by Eliran Sharabi on 08/01/2020.
//  Copyright © 2020 Eliran Sharabi. All rights reserved.
//

import Foundation
import UIKit

/// This define the type of HTTP method used to perform the request
///
/// - post: POST method
/// - put: PUT method
/// - get: GET method
/// - delete: DELETE method
/// - patch: PATCH method
public enum HTTPMethod: String {
    case post            = "POST"
    case put                = "PUT"
    case get                = "GET"
    case delete            = "DELETE"
    case patch            = "PATCH"
}

public enum NetworkError: Error   {
    case unautorized
    case paramsError
    case decodeError
    case errorMessage(message : String)
    
    func stringValue() -> String {
        switch self {
        case .unautorized:
            return "unautorized user"
        case .paramsError:
            return "failed to send params"
        case .decodeError:
            return "failed to decode object"
        case .errorMessage(let message):
            return message
        }
    }
}

class NetworkManager : NSObject , URLSessionDelegate {
    
    let baseURL : URL
    
    typealias SuccessHandler<T : Decodable> = (_ object : T) -> ()
    typealias ErrorHandler = (_ error : NetworkError) -> ()
    
    typealias Parameters = [String : Any]
    
    lazy var defaultSession:URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Content-Type":"application/json; charset=UTF-8"]
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    init(baseURL:URL){
        self.baseURL = baseURL
    }

    
    private func  prepareRequest(urlString : String , httpMethod : HTTPMethod ,urlParams : Parameters , params : Parameters) throws ->  URLRequest  {
        var url = self.baseURL.appendingPathComponent(urlString)
        
        if urlParams.count > 0 {
            var components = URLComponents(string: url.absoluteString)!
            components.queryItems = urlParams.map { (arg) -> URLQueryItem in
                    let (key, value) = arg
                    return URLQueryItem(name: key, value: value as? String)
            }
            url = components.url!
        }
        
        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.timeoutInterval = 5.0
        
        switch httpMethod {
        case .post , .patch , .put:
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        default:
            break
        }
        
        print("URL : \(httpMethod.rawValue) \(url.absoluteString )\nBody: \(params)")
        
        return urlRequest
        
    }
    
    
    func performRequest<T : Decodable>(urlString: String,
                           httpMethod : HTTPMethod ,
                           urlParams : Parameters = Parameters(),
                           params: Parameters = Parameters(),
                           success:@escaping (SuccessHandler<T>),
                           failure:@escaping (ErrorHandler)) {
        
        let urlRequest : URLRequest!
        
        do {
            urlRequest = try prepareRequest(urlString: urlString, httpMethod: httpMethod, urlParams: urlParams , params: params)
        }
          catch {
            failure(.paramsError)
            return
        }
        
        let task = defaultSession.dataTask(with: urlRequest, completionHandler: {(data, response, error) -> () in
            
            DispatchQueue.main.async {
                guard error == nil else {
                    failure(.errorMessage(message: error?.localizedDescription ?? "failed get response"))
                    return
                }
                
                if let aData = data,
                    let urlResponse = response as? HTTPURLResponse,
                    (200..<300).contains(urlResponse.statusCode) {
                    
                    do {
                        let responseJSON = try JSONDecoder().decode(T.self, from: aData)
                        success(responseJSON)
                    }
                    catch {
                        failure(.decodeError)
                    }
                }
            }
            
        })
        
        task.resume()
    }
    
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential: URLCredential?
        
        print("received challenge")
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            disposition = URLSession.AuthChallengeDisposition.useCredential
            credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        } else {
            if challenge.previousFailureCount > 0 {
                disposition = .cancelAuthenticationChallenge
            } else {
                credential = session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)
                
                if credential != nil {
                    disposition = .useCredential
                }
            }
        }
        
        completionHandler (disposition, credential)
    }
    

}
