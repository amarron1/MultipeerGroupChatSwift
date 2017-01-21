//
//  Transcript.swift
//  MultipeerGroupChatSwift
//
//  Created by amarron on 2016/12/04.
//  Copyright © 2016年 amarron. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class Transcript: NSObject {
    // Enumeration of transcript directions
    enum TranscriptDirection {
        case TRANSCRIPT_DIRECTION_SEND
        case TRANSCRIPT_DIRECTION_RECEIVE
        case TRANSCRIPT_DIRECTION_LOCAL // for admin messages. i.e. "<name> connected"
    }

    // Direction of the transcript
    var direction:TranscriptDirection!
    // PeerID of the sender
    var peerID:MCPeerID!
    // String message (optional)
    var message:String?
    // Resource Image name (optional)
    var imageName:String?
    // Resource Image URL (optional)
    var imageUrl:URL?
    // Resource name (optional)
    var progress:Progress?
    
    // Designated initializer with all properties
    func initWithPeerID(peerID:MCPeerID, message:String?, imageName:String?, imageUrl:URL?, progress:Progress?, direction:TranscriptDirection) -> Transcript {
        self.peerID = peerID
        self.message = message
        self.direction = direction
        self.imageUrl = imageUrl
        self.progress = progress
        self.imageName = imageName
        
        return self
    }
    
    // Initializer used for sent/received text messages
    func initWithPeerID(peerID:MCPeerID, message:String, direction:TranscriptDirection) -> Transcript {
        return self.initWithPeerID(peerID: peerID, message: message, imageName: nil, imageUrl:nil, progress:nil, direction:direction)
    }
    
    // Initializer used for sent/received images resources
    func initWithPeerID(peerID:MCPeerID, imageUrl:URL, direction:TranscriptDirection) -> Transcript {
        return self.initWithPeerID(peerID:peerID, message:nil, imageName:imageUrl.lastPathComponent, imageUrl:imageUrl, progress:nil, direction:direction)
    }
    
    func initWithPeerID(peerID:MCPeerID, imageName:String,  progress:Progress?, direction:TranscriptDirection) -> Transcript {
        return self.initWithPeerID(peerID:peerID, message:nil, imageName:imageName, imageUrl:nil, progress:progress, direction:direction)
    }

}
