//
//  InterfaceController.swift
//  SmartAC WatchKit Extension
//
//  Created by Eliran Sharabi on 14/01/2020.
//  Copyright © 2020 Eliran Sharabi. All rights reserved.
//

import WatchKit
import Foundation
import SceneKit

class ACRemoteInterfaceController: WKInterfaceController {

    
    @IBOutlet weak var tempUpButton: WKInterfaceButton!
    @IBOutlet weak var tempDownButton: WKInterfaceButton!
    @IBOutlet weak var tempDegreeLabel: WKInterfaceTextField!
    @IBOutlet weak var fanModeButton: WKInterfaceButton!
    @IBOutlet weak var acModeButton: WKInterfaceButton!
    @IBOutlet weak var powerButton: WKInterfaceButton!
    
    let alertAction = WKAlertAction.init(title:"OK" , style: .default, handler: {})
    
    let tampArray : [Int] = Array(16...32)
    
    var backFromSelection: Bool = false
    
    var smartAC : SmartAC! {
        didSet {
            updateUI()
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
        
        if context is SmartAC {
            smartAC = context as? SmartAC
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if !backFromSelection {
            getDevice()
        } else {
            backFromSelection.toggle()
        }
    }
    
    private func getDevice() {
        guard smartAC != nil else { return }
        SensiboAPI.instance.getDevice(by: smartAC.id) { result in
            switch result {
            case let .success(object):
                self.smartAC = object
            case let .failure(error):
                print(error)
                self.presentAlert(withTitle: "", message: error.stringValue() , preferredStyle: .alert, actions: [WKAlertAction.init(title:"OK" , style: .default, handler: {})])
            }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    
    @IBAction func powerOnOff() {
        setACStatePropertyCall(ACState.CodingKeys.isPowerOn,!smartAC.acState.isPowerOn , alertAction)
    }
    
    @IBAction func setTemperatureDown() {
        changeTemperature(newTemp: smartAC.acState.tempDegree - 1)
    }
    
    @IBAction func setTemperatureUp() {
        changeTemperature(newTemp: smartAC.acState.tempDegree + 1)
    }
    
    
    fileprivate func setACStatePropertyCall(_ property : CodingKey, _ newTemp: Any, _ alertAction: WKAlertAction) {
        SensiboAPI.instance.setACStateProperty(with: smartAC.id, property: property.stringValue  , newValue: newTemp) { (result) in
            switch result {
            case .success(let response):
                self.smartAC.acState = response.acState
                self.updateUI()
            case .failure(let error):
                print(error)
                self.presentAlert(withTitle: "", message: error.stringValue() , preferredStyle: .alert, actions: [alertAction])
            }
        }
    }
    
    func changeTemperature(newTemp : Int) {
       
        if smartAC.connectionStatus.isAlive {
            setACStatePropertyCall(ACState.CodingKeys.tempDegree,newTemp, alertAction)
        } else {
            presentAlert(withTitle: "AC is offline", message: nil , preferredStyle: .alert, actions: [alertAction])
        }
    }
    
    
    func updateUI() {
        tempDegreeLabel.setText("\(smartAC.acState.tempDegree)°C \(smartAC.acState.isPowerOn ? "On" : "Off")")
        acModeButton.setBackgroundImage(UIImage.init(named: smartAC.acState.acMode.rawValue))
        acModeButton.setBackgroundColor(smartAC.acState.acMode.color)
        
        acModeButton.setEnabled(smartAC.acState.isPowerOn)
        fanModeButton.setEnabled(smartAC.acState.isPowerOn)
        tempUpButton.setEnabled(smartAC.acState.isPowerOn)
        tempDownButton.setEnabled(smartAC.acState.isPowerOn)
        
    }
    
    
    override func contextForSegue(withIdentifier segueIdentifier: String) -> Any? {
        print(segueIdentifier)
        let context = ChooseModeContext()
        context.id = smartAC.id
        context.property  = segueIdentifier
        switch segueIdentifier {
        case "fanLevel":
            context.modes = Modes.fanModes
        default:
            context.modes = Modes.acModes
        }
        context.delegate = self
        backFromSelection = true
        return context
    }
    
}


extension ACRemoteInterfaceController : ChooseModeDelegate {
    func backFromChooseMode(acState: ACState) {
        self.smartAC.acState = acState
        updateUI()
    }
}

class ChooseModeContext {
    var id : String?
    var property : String?
    var modes : [String]?
    var delegate : ChooseModeDelegate?
}



