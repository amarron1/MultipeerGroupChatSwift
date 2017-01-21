//
//  File.swift
//  MultipeerGroupChatSwift
//
//  Created by amarron on 2016/12/04.
//  Copyright © 2016年 amarron. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

class SettingsViewController:UIViewController, UITextFieldDelegate {
    
    var delegate:SettingsViewControllerDelegate?
    
    var displayName:String?
    var serviceType:String?

    @IBOutlet var displayNameTextField:UITextField!
    @IBOutlet var serviceTypeTextField:UITextField!

    
    override func viewDidLoad() {
        self.displayNameTextField.text = self.displayName
        self.serviceTypeTextField.text = self.serviceType
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: private
    // RFC 6335 text:
    //   5.1. Service Name Syntax
    //
    //     Valid service names are hereby normatively defined as follows:
    //
    //     o  MUST be at least 1 character and no more than 15 characters long
    //     o  MUST contain only US-ASCII [ANSI.X3.4-1986] letters 'A' - 'Z' and
    //        'a' - 'z', digits '0' - '9', and hyphens ('-', ASCII 0x2D or
    //        decimal 45)
    //     o  MUST contain at least one letter ('A' - 'Z' or 'a' - 'z')
    //     o  MUST NOT begin or end with a hyphen
    //     o  hyphens MUST NOT be adjacent to other hyphens
    //
    private func isDisplayNameAndServiceTypeValid() -> Bool {
    
        // MCPeerID
        // The display name is intended for use in UI elements, and should be short and descriptive of the local peer. The maximum allowable length is 63 bytes in UTF-8 encoding. The displayName parameter may not be nil or an empty string.
        if self.displayNameTextField.text == nil {
            print("Invalid display name [nil]")
            return false
        } else if ((self.displayNameTextField.text?.isEmpty)!
            || (self.displayNameTextField.text?.lengthOfBytes(using: .utf8))! > 63) {
            print("Invalid display name [" + self.displayNameTextField.text! + "]")
            return false
        }
        
       // MCNearbyServiceAdvertiser
       //   Valid serviceType:
       //   o  Must be 1–15 characters long
       //   o  Can contain only ASCII lowercase letters, numbers, and hyphens
       //   o  Must contain at least one ASCII letter
       //   o  Must not begin or end with a hyphen
       //   o  Must not contain hyphens adjacent to other hyphens.
        if self.serviceTypeTextField.text == nil {
            print("Invalid service type [nil]")
            return false
        } else if ((self.serviceTypeTextField.text?.isEmpty)!
            || (self.serviceTypeTextField.text?.characters.count)! > 15
            || self.serviceTypeTextField.text?.range(of: "^[a-z0-9-]+$", options: .regularExpression, range: nil, locale: nil) == nil
            || (self.serviceTypeTextField.text?.hasPrefix("-"))!
            || (self.serviceTypeTextField.text?.hasSuffix("-"))!
            || ((self.serviceTypeTextField.text?.range(of: "--")) != nil)) {
            print("Invalid service type [" + self.serviceTypeTextField.text! + "]")
            return false
        }
        
        print("Room Name ["    + self.serviceTypeTextField.text! + "] (aka service type) are valid")
        print("Display name [" + self.displayNameTextField.text! + "] are valid")
        return true
    }

    // MARK: IBAction methods
    @IBAction func doneTapped(_ sender: Any) {
        if self.isDisplayNameAndServiceTypeValid() {
            // Fields are set.  send the values back to the delegate
            self.delegate?.controller(controller: self, displayName: self.displayNameTextField.text!, serviceType: self.serviceTypeTextField.text!)
        } else {
            // These are mandatory fields.  Alert the user
            let alert: UIAlertController = UIAlertController(title: "Error", message: "You must set a valid room name and your display name", preferredStyle: .alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel, handler:nil)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }

    // MARK: UITextFieldDelegate methods
    func textFieldShouldReturn(_ texField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.view.endEditing(true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.isEmpty || string.range(of: "^[0-9]+$", options: .regularExpression, range: nil, locale: nil) != nil
    }
}

// MARK: SettingsViewControllerDelegate protocol
protocol SettingsViewControllerDelegate {
    func controller(controller: SettingsViewController, displayName:String, serviceType:String)
}


