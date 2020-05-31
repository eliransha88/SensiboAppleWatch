//
//  SplashInterfaceController.swift
//  SmartAC WatchKit Extension
//
//  Created by Eliran Sharabi on 21/01/2020.
//  Copyright © 2020 Eliran Sharabi. All rights reserved.
//

import UIKit
import WatchKit

class DevicesInterfaceController: WKInterfaceController {

    @IBOutlet weak var refershDevices: WKInterfaceButton!
    @IBOutlet weak var devicesTableView: WKInterfaceTable!
    
    var devices : [SmartAC]! {
        didSet {
            loadTableData()
        }
    }
    
    private func getDevices() {
        SensiboAPI.instance.getDevices { result in
            switch result {
            case .success(let object) :
                self.devices = object
            case .failure(let error) :
                print(error)
                self.presentAlert(withTitle: "", message: error.stringValue() , preferredStyle: .alert, actions: [WKAlertAction.init(title:"OK" , style: .default, handler: {})])
            }
        }
    }
    
    override func awake(withContext context: Any?) {
         super.awake(withContext: context)
        
     }
     
     override func willActivate() {
         // This method is called when watch view controller is about to be visible to user
         super.willActivate()
         getDevices()
     }
     
    func loadTableData()
    {
        devicesTableView.setNumberOfRows(devices.count , withRowType : "DeviceRowController")
        
        for (index , rowModel) in devices.enumerated() {
            if let rowController = devicesTableView.rowController(at: index) as? DeviceRowController {
                rowController.device = rowModel
            }
        }
    }
    
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        return devices[rowIndex]
    }
    
    @IBAction func refreshDevices() {
        getDevices()
    }
}


class DeviceRowController: NSObject {
   
    @IBOutlet var deviceNameLabel : WKInterfaceLabel!
    @IBOutlet var deviceStatusLabel : WKInterfaceLabel!
    
    var device : SmartAC! {
        didSet {
            deviceNameLabel.setText(device.name)
            deviceStatusLabel.setText(device.connectionStatus.isAlive ? "Online" : "Offline" )
        }
    }
    
    
}
