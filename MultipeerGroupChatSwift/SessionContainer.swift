//
//  SessionContainer.swift
//  MultipeerGroupChatSwift
//
//  Created by amarron on 2016/12/04.
//  Copyright © 2016年 amarron. All rights reserved.
//

import Foundation
import MultipeerConnectivity


class SessionContainer: NSObject, MCSessionDelegate {
    
    var session:MCSession?
    var delegate:SessionContainerDelegate?
    
    // Framework UI class for handling incoming invitations
    var advertiserAssistant:MCAdvertiserAssistant?

    // Session container designated initializer
    func initWithDisplayName(displayName:String, serviceType:String) -> SessionContainer {
        
        // Create the peer ID with user input display name.  This display name will be seen by other browsing peers
        let peerID:MCPeerID = MCPeerID(displayName: displayName)
        // Create the session that peers will be invited/join into.  You can provide an optinal security identity for custom authentication.  Also you can set the encryption preference for the session.
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        // Set ourselves as the MCSessionDelegate
        self.session?.delegate = self
        // Create the advertiser assistant for managing incoming invitation
        self.advertiserAssistant =  MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: self.session!)
        // Start the assistant to begin advertising your peers availability
        self.advertiserAssistant?.start()
        
        return self

    }
    
    // On dealloc we should clean up the session by disconnecting from it.
    deinit {
        self.advertiserAssistant?.stop()
        session?.disconnect()
    }
    
    // Helper method for human readable printing of MCSessionState.  This state is per peer.
    func stringForPeerConnectionState(state:MCSessionState) -> String {
        switch state {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .notConnected:
            return "Not Connected"
        }
    }
    
    // MARK: Public methods
    // Instance method for sending a string bassed text message to all remote peers
    func sendMessage(message: String) -> Transcript? {
        // Convert the string into a UTF8 encoded data
        let messageData:Data = message.data(using: .utf8)!
        // Send text message to all connected peers
        
        do {
            try self.session!.send(messageData, toPeers: (self.session?.connectedPeers)!,
                                  with: .reliable)
        } catch {
            // Check the error return to know if there was an issue sending data to peers.  Note any peers in the 'toPeers' array argument are not connected this will fail.
            print("Error sending message to peers " + error.localizedDescription)
            return nil
        }

        // Create a new send transcript
        return Transcript().initWithPeerID(peerID:(self.session?.myPeerID)!, message:message, direction:.TRANSCRIPT_DIRECTION_SEND)
        
    }
    
    // Method for sending image resources to all connected remote peers.  Returns an progress type transcript for monitoring tranfer
    func sendImage(imageUrl:URL) -> Transcript {
        
        var progress:Progress?
        // Loop on connected peers and send the image to each
        for peerID in (self.session?.connectedPeers)! {
            progress = self.session?.sendResource(at: imageUrl, withName: imageUrl.lastPathComponent, toPeer: peerID, withCompletionHandler: { (error) in
                if (error != nil) {
                    print("Send resource to peer " + peerID.displayName + " completed with Error " + error.debugDescription)
                } else {
                    // Create an image transcript for this received image resource
                    let transcript:Transcript = Transcript().initWithPeerID(peerID: (self.session?.myPeerID)!, imageUrl: imageUrl, direction: .TRANSCRIPT_DIRECTION_SEND)
                    self.delegate?.updateTranscript(transcript: transcript)
                }
            })

        }
        // Create an outgoing progress transcript.  For simplicity we will monitor a single NSProgress.  However users can measure each NSProgress returned individually as needed
        let transcript:Transcript = Transcript().initWithPeerID(peerID: (self.session?.myPeerID)!, imageName: imageUrl.lastPathComponent, progress: progress, direction: .TRANSCRIPT_DIRECTION_SEND)
        
        return transcript
    }
    
    // MARK: MCSessionDelegate methods
    // Override this method to handle changes to peer session state
    func session(_ session: MCSession, peer peerID: MCPeerID,
                 didChange state: MCSessionState)  {
        print("Peer " + peerID.displayName + " changed state to " + self.stringForPeerConnectionState(state: state))
        
        let adminMessage:String = "'" + peerID.displayName + "' is " + self.stringForPeerConnectionState(state: state)
        // Create an local transcript
        let transcript:Transcript = Transcript().initWithPeerID(peerID: peerID, message: adminMessage, direction: .TRANSCRIPT_DIRECTION_LOCAL)
        
        // Notify the delegate that we have received a new chunk of data from a peer
        self.delegate?.receivedTranscript(transcript: transcript)
    }
    
    // MCSession delegate callback when receiving data from a peer in a given session
    func session(_ session: MCSession, didReceive data: Data,
                 fromPeer peerID: MCPeerID)  {
        // Decode the incoming data to a UTF8 encoded string
        let receiveMessage:String = String(data: data, encoding: .utf8)!
        // Create an received transcript
        let transcript:Transcript = Transcript().initWithPeerID(peerID: peerID, message: receiveMessage, direction: .TRANSCRIPT_DIRECTION_RECEIVE)
        
        // Notify the delegate that we have received a new chunk of data from a peer
        self.delegate?.receivedTranscript(transcript: transcript)

    }

    // MCSession delegate callback when we start to receive a resource from a peer in a given session
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, with progress: Progress) {
        
        print("Start receiving resource " + resourceName + " from peer " + peerID.displayName + " with progress [" + progress.localizedDescription + "]")
        // Create a resource progress transcript
        let transcript:Transcript = Transcript().initWithPeerID(peerID: peerID, imageName: resourceName, progress: progress, direction: .TRANSCRIPT_DIRECTION_RECEIVE)
        // Notify the UI delegate
        self.delegate?.receivedTranscript(transcript: transcript)
    }
    
    // MCSession delegate callback when a incoming resource transfer ends (possibly with error)
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL, withError error: Error?) {
        // If error is not nil something went wrong
        if error != nil {
            print("Error " + (error?.localizedDescription)! + " receiving resource from peer " + peerID.displayName)
        } else {
            // No error so this is a completed transfer.  The resources is located in a temporary location and should be copied to a permenant locatation immediately.
            // Write to documents directory
            let paths:Array = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let copyPath:String = paths[0] + "/" + resourceName

            do {
                try FileManager.default.copyItem(at: URL(fileURLWithPath: localURL.path), to: URL(fileURLWithPath: copyPath))
                
                // Get a URL for the path we just copied the resource to
                let imageUrl:URL = URL(fileURLWithPath: copyPath)
                // Create an image transcript for this received image resource
                let transcript:Transcript = Transcript().initWithPeerID(peerID: peerID, imageUrl: imageUrl, direction: .TRANSCRIPT_DIRECTION_RECEIVE)
                self.delegate?.updateTranscript(transcript: transcript)
            } catch {
                print("Error copying resource to documents directory")
            }
        }
    }
    
    // Streaming API not utilized in this sample code
    func session(_ session: MCSession, didReceive stream: InputStream,
                 withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Received data over stream with name " + streamName + " from peer " + peerID.displayName)
    }
    
}

protocol SessionContainerDelegate {
    
    // Method used to signal to UI an initial message, incoming image resource has been received
    func receivedTranscript(transcript: Transcript)
    // Method used to signal to UI an image resource transfer (send or receive) has completed
    func updateTranscript(transcript: Transcript)

}
