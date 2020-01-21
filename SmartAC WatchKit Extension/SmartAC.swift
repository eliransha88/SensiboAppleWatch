//
//  SmartAC.swift
//  SmartAC WatchKit Extension
//
//  Created by Eliran Sharabi on 14/01/2020.
//  Copyright © 2020 Eliran Sharabi. All rights reserved.
//

import Foundation
import UIKit

class SmartAC : Codable {
    
    var id : String
    var connectionStatus : ConnectionStatus
    var acState : ACState
    
    private var room  : Room
    
    var name : String? {
        get {
            return room.name
        }
    }
    
    enum CodingKeys : String , CodingKey {
        case id , connectionStatus, acState , room
    }
}

struct Room : Codable {
    var name : String
    var icon : String
}

struct ConnectionStatus : Codable {
    var isAlive : Bool
    var lastSeen : LastSeen
    
}

struct LastSeen : Codable {
    var secondsAgo : Int
    var time : String
}

struct ACState : Codable {
    var isPowerOn : Bool
    var fanLevel : FanLevel
    var tempUnit : String
    var tempDegree : Int
    var acMode : ACMode
    
    enum CodingKeys : String , CodingKey {
        case isPowerOn = "on"
        case fanLevel
        case tempUnit = "temperatureUnit"
        case tempDegree = "targetTemperature"
        case acMode = "mode"
    }
    
    public func encode(to encoder: Encoder) throws {
         var container = encoder.container(keyedBy: CodingKeys.self)
         try container.encode(isPowerOn, forKey: .isPowerOn)
         try container.encode(fanLevel, forKey: .fanLevel)
         try container.encode(tempUnit, forKey: .tempUnit)
         try container.encode(tempDegree, forKey: .tempDegree)
         try container.encode(acMode.rawValue, forKey: .acMode)
     }
    
    enum FanLevel : String , Codable {
        case low , medium , high , auto
    }
    
    enum ACMode : String , Decodable {
        case heat , cool , dry
    }
    
    
    func getACModeColor() -> UIColor {
        switch self.acMode {
        case .cool:
            return .blue
        case .heat:
            return .red
        case .dry:
            return .white
        }
    }

}

struct Modes  {
    static var fanModes = [ "low" , "medium" , "high" , "auto"]
    static var acModes  = [ "heat" , "cool" , "dry"]
}
