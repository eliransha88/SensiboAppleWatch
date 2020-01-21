//
//  ChooseModeView.swift
//  SmartAC WatchKit Extension
//
//  Created by Eliran Sharabi on 14/01/2020.
//  Copyright © 2020 Eliran Sharabi. All rights reserved.
//

import WatchKit
import Foundation


protocol ChooseModeDelegate {
    func backFromChooseMode(acState : ACState)
}

class ChooseModeInterfaceController: WKInterfaceController {
    
    @IBOutlet var tableView : WKInterfaceTable!
    
    var delegate : ChooseModeDelegate?
    
    var deviceId : String!
    
    var property : String! 
    
    var modes : [String]! {
        didSet {
           loadTableData()
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
        if let context = context as? ChooseModeContext {
            deviceId = context.id
            property = context.property
            modes = context.modes
            delegate = context.delegate
        }
      
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    func loadTableData()
    {
        tableView.setNumberOfRows(modes.count , withRowType : "ModeRow")
        
        for (index , rowModel) in modes.enumerated() {
            if let rowController = tableView.rowController(at: index) as? RowController {
                rowController.mode = rowModel
            }
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        SensiboAPI.instance.setACStateProperty(with: deviceId, property: property  , newValue: modes[rowIndex]) { (result) in
                switch result {
                case .success(let response):
                    self.delegate?.backFromChooseMode(acState: response.acState)
                    self.pop()
                case .failure(let error):
                    print(error)
                    self.presentAlert(withTitle: "", message: error.stringValue() , preferredStyle: .alert, actions: [WKAlertAction.init(title:"OK" , style: .default, handler: {})])
                }
            }
    }
    
}


class RowController: NSObject {
    @IBOutlet var modeLabel : WKInterfaceLabel!
    
    var mode : String! {
        didSet {
            modeLabel.setText(mode.capitalized)
        }
    }
}
