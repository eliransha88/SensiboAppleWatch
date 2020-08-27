//
//  SensiboAPI.swift
//  SmartAC WatchKit Extension
//
//  Created by Eliran Sharabi on 15/01/2020.
//  Copyright © 2020 Eliran Sharabi. All rights reserved.
//

import Foundation


class SensiboAPI {
    
    static let instance = SensiboAPI()
    
    lazy var baseURL : String = "https://home.sensibo.com/api/v2/"
    
    // TODO : enter api key
    let apiKey = "<api key>"
    
    enum Paths  {
        case devices
        case device(deviceId : String)
        case acState(deviceId : String)
        case acStateProperty(deviceId : String , property : String)
        
        func getPath() -> String {
            switch self {
            case .devices:
                return "users/me/pods"
            case let .device(deviceId):
                return "pods/\(deviceId)"
            case let .acState(deviceId):
                return "pods/\(deviceId)/acStates"
            case let .acStateProperty(deviceId, property):
                return "pods/\(deviceId)/acStates/\(property)"
            }
        }
    }
    
    lazy private var manager = NetworkManager(baseURL: URL.init(string: self.baseURL)!)
    
    typealias RequestHandler<T : Decodable> = (Result<T , NetworkError>) -> ()

    func getDevices(completion : @escaping RequestHandler<[SmartAC]>) {
        performRequest(path: .devices, method: .get, urlParams: ["fields" : "*"]) { (result : Result<Response<[SmartAC]> , NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response.result))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getDevice(by deviceId : String , completion : @escaping RequestHandler<SmartAC>) {
        performRequest(path: .device(deviceId: deviceId), method: .get, urlParams: ["fields" : "*"]) { (result : Result<Response<SmartAC> , NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response.result))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getDeviceACState(with deviceId : String ,completion : @escaping RequestHandler<ACStateResponse>) {
        performRequest(path: .acState(deviceId: deviceId), method: .get, urlParams: ["limit" : "1"]) { (result : Result<Response<ACStateResponse> , NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response.result))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func setACState(with deviceId : String , acState : ACState , completion : @escaping RequestHandler<ACStateResponse>) {
        let params : NetworkManager.Parameters
        do {
            let data = try JSONEncoder().encode(ACStateRequest(acState: acState))
            params = try (JSONSerialization.jsonObject(with: data, options: []) as? NetworkManager.Parameters)!
        }catch {
            completion(.failure(.decodeError))
            return
        }
        performRequest(path: .acState(deviceId: deviceId), method: .post, params: params) { (result : Result<Response<ACStateResponse> , NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response.result))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func setACStateProperty(with deviceId : String, property : String , newValue : Any , completion : @escaping RequestHandler<ACStateResponse>) {
        performRequest(path: .acStateProperty(deviceId: deviceId, property: property), method: .patch, params: ["newValue" : newValue]) { (result : Result<Response<ACStateResponse> , NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response.result))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func performRequest<T : Decodable>(path : Paths ,method : HTTPMethod , urlParams : NetworkManager.Parameters  = [String : Any]() , params : NetworkManager.Parameters = [String : Any]() , completion :@escaping RequestHandler<T>) {
        
        var sensiboUrlParams = urlParams
        sensiboUrlParams["apiKey"] = apiKey
        
        manager.performRequest(urlString: path.getPath() , httpMethod: method, urlParams: sensiboUrlParams, params: params,
                               success: { (object ) in
            completion(.success(object))
        }) { (error) in
            completion(.failure(error))
        }
    }

    
}


struct ACStateRequest : Codable {
    var acState : ACState
}

struct ACStateResponse : Decodable {
    var status : String
    var reason : String
    var acState : ACState
}

struct Response <T: Decodable> : Decodable {
    var status : String
    var result : T

}


