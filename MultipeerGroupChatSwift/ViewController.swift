//
//  ViewController.swift
//  MultipeerGroupChatSwift
//
//  Created by amarron on 2016/12/04.
//  Copyright © 2016年 amarron. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UITableViewController, MCBrowserViewControllerDelegate, SettingsViewControllerDelegate, UITextFieldDelegate, SessionContainerDelegate,  UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Constants for save/restore NSUserDefaults for the user entered display name and service type.
    static let kNSDefaultDisplayName:String = "displayNameKey"
    static let kNSDefaultServiceType:String = "serviceTypeKey"
    
    // Display name for local MCPeerID
    var displayName:String?
    // Service type for discovery
    var serviceType:String?
    // MC Session for managing peer state and send/receive data between peers
    var sessionContainer:SessionContainer?
    // TableView Data source for managing sent/received messagesz
    var transcripts:NSMutableArray?
    // Map of resource names to transcripts array index
    var imageNameIndex:NSMutableDictionary?
    // Text field used for typing text messages to send to peers
    @IBOutlet var messageComposeTextField:UITextField!
    // Button for executing the message send.
    @IBOutlet var sendMessageButton:UIBarButtonItem!

    // MARK: Override super class methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Init transcripts array to use as table view data source
        self.transcripts = NSMutableArray()
        self.imageNameIndex = NSMutableDictionary()
        
        // Get the display name and service type from the previous session (if any)
        let defaults:UserDefaults = UserDefaults.standard
        self.displayName = defaults.object(forKey: ViewController.kNSDefaultDisplayName) as! String?
        self.serviceType = defaults.object(forKey: ViewController.kNSDefaultServiceType) as! String?
        
        if ((self.displayName != nil) && (self.serviceType != nil)) {
            // Show the service type (room name) as a title
            self.navigationItem.title = self.serviceType
            // create the session
            self.createSession()
        } else {
            // first time running the application.  user needs to create the group chat service
            self.performSegue(withIdentifier: "Room Create", sender: self)
        }
        self.navigationController?.isToolbarHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Listen for will show/hide notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow(notification:)),
            name: .UIKeyboardWillShow,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillHide(notification:)),
            name: .UIKeyboardWillHide,
            object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Stop listening for keyboard notifications
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Room Create" {
            // Prepare the settings view where the user inputs the 'serviceType' and local peer 'displayName'
            let navController:UINavigationController = segue.destination as! UINavigationController
            let viewController:SettingsViewController = navController.topViewController as! SettingsViewController
            viewController.delegate = self
            // Pass the existing properties (if any) so the user can edit them.
            viewController.displayName = self.displayName
            viewController.serviceType = self.serviceType
        }
    }
    
    // MARK: SettingsViewControllerDelegate methods
    func controller(controller: SettingsViewController, displayName:String, serviceType:String) {
        // Dismiss the modal view controller
        self.dismiss(animated: true, completion: nil)
        
        // Cache these for MC session creation and changing later via the "info" button
        self.displayName = displayName
        self.serviceType = serviceType
        
        // Save these for subsequent app launches
        let defaults:UserDefaults = UserDefaults.standard
        defaults.set(displayName, forKey: ViewController.kNSDefaultDisplayName)
        defaults.set(serviceType, forKey: ViewController.kNSDefaultServiceType)
        defaults.synchronize()
        
        // Set the service type (aka Room Name) as the view controller title
        self.navigationItem.title = serviceType
        
        // Create the session
        self.createSession()
    }
    
    // MARK: MCBrowserViewControllerDelegate methods
    // Override this method to filter out peers based on application specific needs
    func browserViewController(_ browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
        return true
    }
    
    // Override this to know when the user has pressed the "done" button in the MCBrowserViewController
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true, completion: nil)
    }
    
    // Override this to know when the user has pressed the "cancel" button in the MCBrowserViewController
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: SessionContainerDelegate methods
    func receivedTranscript(transcript: Transcript) {
        // Add to table view data source and update on main thread
        DispatchQueue.main.async {
            self.insertTranscript(transcript: transcript)
        }
    }
    
    func updateTranscript(transcript: Transcript) {
        // Find the data source index of the progress transcript
        let index:NSInteger = self.imageNameIndex?.object(forKey: transcript.imageName ?? 0) as! NSInteger
        
        // Replace the progress transcript with the image transcript
        self.transcripts?.replaceObject(at: index, with: transcript)
        
        // Reload this particular table view row on the main thread
        DispatchQueue.main.async {
            let newIndexPath:IndexPath = IndexPath(row: index, section: 0)
            self.tableView.reloadRows(at: [newIndexPath], with: .automatic)
        }
    }


    // MARK: private methods
    // Private helper method for the Multipeer Connectivity local peerID, session, and advertiser.  This makes the application discoverable and ready to accept invitations
    private func createSession() {
        // Create the SessionContainer for managing session related functionality.
        self.sessionContainer = SessionContainer().initWithDisplayName(displayName: self.displayName!, serviceType: self.serviceType!)
        // Set this view controller as the SessionContainer delegate so we can display incoming Transcripts and session state changes in our table view.
        self.sessionContainer?.delegate = self
    }
    
    // Helper method for inserting a sent/received message into the data source and reload the view.
    // Make sure you call this on the main thread
    private func insertTranscript(transcript:Transcript) {
        // Add to the data source
        self.transcripts?.add(transcript)
        
        // If this is a progress transcript add it's index to the map with image name as the key
        if (nil != transcript.progress) {
            let transcriptIndex:NSNumber = (self.transcripts!.count - 1) as NSNumber
            self.imageNameIndex?.setObject(transcriptIndex, forKey: transcript.imageName as! NSCopying)
        }
        
        // Update the table view
        let newIndexPath:IndexPath = IndexPath(row: ((self.transcripts?.count)! - 1), section: 0)
        self.tableView.insertRows(at: [newIndexPath], with: .fade)
        
        // Scroll to the bottom so we focus on the latest message
        let numberOfRows:Int = self.tableView.numberOfRows(inSection: 0)
        self.tableView.scrollToRow(at: IndexPath(row: (numberOfRows - 1), section:0), at: .bottom, animated: true)
    }
    
    // MARK: Table view data source
    // Only one section in this example
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // The numer of rows is based on the count in the transcripts arrays
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.transcripts?.count)!
    }
    
    // The individual cells depend on the type of Transcript at a given row.  We have 3 row types (i.e. 3 custom cells) for text string messages, resource transfer progress, and completed image resources
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get the transcript for this row
        let transcript:Transcript = self.transcripts?.object(at: indexPath.row) as! Transcript
        
        // Check if it's an image progress, completed image, or text message
        let cell:UITableViewCell
        if (nil != transcript.imageUrl) {
            // It's a completed image
            cell = tableView.dequeueReusableCell(withIdentifier: "Image Cell", for: indexPath) as UITableViewCell
            // Get the image view
            let imageView:ImageView = cell.viewWithTag(ImageView.IMAGE_VIEW_TAG) as! ImageView
            // Set up the image view for this transcript
            imageView.setTranscript(transcript: transcript)
        } else if (nil != transcript.progress) {
            // It's a resource transfer in progress
            cell = tableView.dequeueReusableCell(withIdentifier: "Progress Cell", for: indexPath) as UITableViewCell
            let  progressView:ProgressView = cell.viewWithTag(ProgressView.PROGRESS_VIEW_TAG) as! ProgressView
            // Set up the progress view for this transcript
            progressView.setTranscript(transcript: transcript)
        } else {
            // Get the associated cell type for messages
            cell = tableView.dequeueReusableCell(withIdentifier: "Message Cell", for: indexPath) as UITableViewCell
            // Get the message view
            let  messageView:MessageView = cell.viewWithTag(MessageView.MESSAGE_VIEW_TAG) as! MessageView
            // Set up the message view for this transcript
            messageView.setTranscript(transcript: transcript)
        }
        return cell
    }
    
    // Return the height of the row based on the type of transfer and custom view it contains
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Dynamically compute the label size based on cell type (image, image progress, or text message)
        let transcript:Transcript = self.transcripts?.object(at: indexPath.row) as! Transcript
        if (nil != transcript.imageUrl) {
            return ImageView.viewHeightForTranscript(transcript: transcript)
        } else if (nil != transcript.progress) {
            return ProgressView.viewHeightForTranscript(transcript: transcript)
        } else {
            return MessageView.viewHeightForTranscript(transcript: transcript)
        }
    }

    // MARK: IBAction methods
    // Action method when pressing the "browse" (search icon).  It presents the MCBrowserViewController: a framework UI which enables users to invite and connect to other peers with the same room name (aka service type).
    @IBAction func browseForPeers(_ sender: Any) {
        print(#function)
        
        // Instantiate and present the MCBrowserViewController
        let browserViewController:MCBrowserViewController = MCBrowserViewController(serviceType: self.serviceType!, session: self.sessionContainer!.session!)
        
        browserViewController.delegate = self
        browserViewController.minimumNumberOfPeers = kMCSessionMinimumNumberOfPeers
        browserViewController.maximumNumberOfPeers = kMCSessionMaximumNumberOfPeers
        
        self.present(browserViewController, animated: true, completion: nil)
    }
    
    // Action method when user presses "send"
    @IBAction func sendMessageTapped(_ sender: Any) {
    // Dismiss the keyboard.  Message will be actually sent when the keyboard resigns.
        self.messageComposeTextField.resignFirstResponder()
    }
    
    // Action method when user presses the "camera" photo icon.
    @IBAction func photoButtonTapped(_ sender: Any) {
        // Preset an action sheet which enables the user to take a new picture or select and existing one.
        let actionSheet:UIAlertController = UIAlertController(title: nil,
                                                              message: nil,
                                                              preferredStyle: .actionSheet)
        
        let cancelAction:UIAlertAction = UIAlertAction(title: "Cancel",
                                                       style: .cancel,
                                                       handler:{
                                                        (action:UIAlertAction!) -> Void in})
        let takeAction:UIAlertAction = UIAlertAction(title: "Take Photo",style: .default, handler:{ (action:UIAlertAction!) -> Void in
            let imagePicker:UIImagePickerController = UIImagePickerController()
            // set the delegate and source type, and present the image picker
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true, completion: nil)
            
        })
        let chooseAction:UIAlertAction = UIAlertAction(title: "Choose Existing", style: .default, handler:{ (action:UIAlertAction!) -> Void in
            
            let imagePicker:UIImagePickerController = UIImagePickerController()
            // set the delegate and source type, and present the image picker
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
            
        })
        
        actionSheet.addAction(cancelAction)
        actionSheet.addAction(takeAction)
        actionSheet.addAction(chooseAction)
        
        // Show the action sheet
        present(actionSheet, animated: true, completion: nil)
    }
    

    // MARK: UIImagePickerControllerDelegate methods
    // For responding to the user tapping Cancel.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // Override this delegate method to get the image that the user has selected and send it view Multipeer Connectivity to the connected peers.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        // Don't block the UI when writing the image to documents
        DispatchQueue.global().async {
            // We only handle a still image
            let imageToSave: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            
            // Save the new image to the documents directory
            let pngData: Data = UIImageJPEGRepresentation(imageToSave, 1.0)!
            
            // Create a unique file name
            let inFormat: DateFormatter = DateFormatter()
            inFormat.dateFormat = "yyMMdd-HHmmss"
            
            let imageName: String = "image-" + inFormat.string(from: Date()) + ".JPG"
            // Create a file path to our documents directory
            let paths:Array = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let filePath:String = paths[0] + "/" + imageName
            do {
                try pngData.write(to: URL(fileURLWithPath: filePath), options: .atomic) // Write the file
                // Get a URL for this file resource
                let imageUrl:URL = URL(fileURLWithPath: filePath)
                
                // Send the resource to the remote peers and get the resulting progress transcript
                let transcript:Transcript = self.sessionContainer!.sendImage(imageUrl: imageUrl)
                
                // Add the transcript to the data source and reload
                DispatchQueue.main.async {
                    self.insertTranscript(transcript: transcript)
                }
            } catch {
                print("Invalid filePath [" + filePath + "]")
            }
        }
    }
    
    
    // MARK: UITextFieldDelegate methods
    // Override to dynamically enable/disable the send button based on user typing
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let length:Int = (self.messageComposeTextField.text?.lengthOfBytes(using: .utf8))! - range.length + string.lengthOfBytes(using: .utf8)
        if (length > 0) {
            self.sendMessageButton.isEnabled = true
        } else {
            self.sendMessageButton.isEnabled = false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
    // Delegate method called when the message text field is resigned.
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Check if there is any message to send
        if (!(self.messageComposeTextField.text?.isEmpty)!) {
            // Resign the keyboard
            textField.resignFirstResponder()

            // Send the message
            if let transcript:Transcript = self.sessionContainer?.sendMessage(message: self.messageComposeTextField.text!) {
                // Add the transcript to the table view data source and reload
                self.insertTranscript(transcript: transcript)
            }
            
            // Clear the textField and disable the send button
            self.messageComposeTextField.text = ""
            self.sendMessageButton.isEnabled = false
        }
    }
    
    // MARK: Toolbar animation helpers
    // Helper method for moving the toolbar frame based on user action
    func moveToolBarUp(up:Bool, notification: Notification) {
        let userInfo = notification.userInfo
        
        // Get animation info from userInfo
        let animationDuration:TimeInterval = userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        let animationCurve:UIViewAnimationCurve = UIViewAnimationCurve(rawValue: userInfo![UIKeyboardAnimationCurveUserInfoKey] as! Int)!
        let keyboardFrame:CGRect = userInfo![UIKeyboardFrameEndUserInfoKey] as! CGRect
        
        // Animate up or down
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(animationDuration)
        UIView.setAnimationCurve(animationCurve)
        
        let frame:CGRect = CGRect(x: (self.navigationController?.toolbar.frame.origin.x)!,
//                                 y: (self.navigationController?.toolbar.frame.origin.y)! + (keyboardFrame.size.height * (up ? -1 : 1)),
                                 y: self.view.frame.size.height - ((self.navigationController?.toolbar?.frame.size.height)! + (up ? keyboardFrame.size.height: 0)),
                                 width: (self.navigationController?.toolbar.frame.size.width)!,
                                 height:(self.navigationController?.toolbar.frame.size.height)!)
        
        self.navigationController?.toolbar.frame = frame
        UIView.commitAnimations()
        
    }
    
    func keyboardWillShow(notification: Notification) {
        // move the toolbar frame up as keyboard animates into view
        self.moveToolBarUp(up: true, notification: notification)
    }
    
    func keyboardWillHide(notification: Notification) {
        // move the toolbar frame down as keyboard animates into view
        self.moveToolBarUp(up: false, notification:notification)
    }
}
