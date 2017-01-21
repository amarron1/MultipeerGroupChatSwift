//
//  ProgressView.swift
//  MultipeerGroupChatSwift
//
//  Created by amarron on 2016/12/04.
//  Copyright © 2016年 amarron. All rights reserved.
//

import Foundation
import UIKit

class ProgressView: UIView, ProgressObserverDelegate {
    var transcript:Transcript?
    
    static let PROGRESS_VIEW_TAG:Int = 101

    static let PROGRESS_VIEW_HEIGHT:CGFloat    = 15.0
    static let PADDING_X:CGFloat               = 15.0
    static let NAME_FONT_SIZE:CGFloat          = 10.0
    static let BUFFER_WHITE_SPACE:CGFloat      = 14.0
    static let PROGRESS_VIEW_WIDTH:CGFloat     = 140.0
    static let PEER_NAME_HEIGHT:CGFloat        = 12.0
    static let NAME_OFFSET_ADJUST:CGFloat      = 4.0
    
    
    // View for showing resource send/receive progress
    var progressView:UIProgressView?
    // View for displaying sender name (received transcripts only)
    var displayNameLabel:UILabel?
    // KVO progress observer for updating the progress bar based on NSProgress changes
    var observer:ProgressObserver?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Initialization the sub views
        self.progressView = UIProgressView(progressViewStyle: .default)
        self.progressView?.progress = 0.0
        
        self.displayNameLabel = UILabel()
        self.displayNameLabel?.font = UIFont.systemFont(ofSize: 10.0)
        self.displayNameLabel?.textColor = UIColor(colorLiteralRed: 34.0/255.0, green: 34.0/255.0, blue: 221.0/255.0, alpha: 1)
        
        // Add to parent view
        self.addSubview(self.displayNameLabel!)
        self.addSubview(self.progressView!)
    }
    
    
    var yOffsetTmp:CGFloat?
    // Method for setting the transcript object which is used to build this view instance.
    func setTranscript(transcript: Transcript) {
        // Create the progress observer
        self.observer = ProgressObserver().initWithName(name:transcript.imageName!, progress:transcript.progress!)
        // Listen for progress changes
        self.observer?.delegate = self
        
        // Compute name size
        let nameText:String  = transcript.peerID!.displayName
        let nameSize:CGSize = ProgressView.labelSizeForString(string: nameText, fontSize: ProgressView.NAME_FONT_SIZE)
        
        // Comput the X,Y origin offsets
        var xOffset:CGFloat
        var yOffset:CGFloat
        
        if (.TRANSCRIPT_DIRECTION_SEND == transcript.direction) {
            // Sent images appear or right of view
            xOffset = 320 - ProgressView.PADDING_X - ProgressView.PROGRESS_VIEW_WIDTH
            yOffset = ProgressView.BUFFER_WHITE_SPACE / 2
            self.displayNameLabel?.text = ""
        } else {
            // Received images appear on left of view with additional display name label
            xOffset = ProgressView.PADDING_X
            yOffset = (ProgressView.BUFFER_WHITE_SPACE / 2) + nameSize.height - ProgressView.NAME_OFFSET_ADJUST
            self.displayNameLabel?.text = nameText
        }
        
        
        // Set the dynamic frames
        self.displayNameLabel?.frame = CGRect(x: xOffset, y: 1, width: nameSize.width, height: nameSize.height)
        self.progressView?.frame = CGRect(x: xOffset, y: yOffset + 5, width: ProgressView.PROGRESS_VIEW_WIDTH, height: ProgressView.PROGRESS_VIEW_HEIGHT)
    }

    
    // MARK: class methods for computing sizes based on strings
    static func viewHeightForTranscript(transcript: Transcript) -> CGFloat {
        // Return dynamic height of the cell based on the particular transcript
        if .TRANSCRIPT_DIRECTION_RECEIVE == transcript.direction {
            // The senders name height is included for received messages
            return (PEER_NAME_HEIGHT + PROGRESS_VIEW_HEIGHT + BUFFER_WHITE_SPACE - NAME_OFFSET_ADJUST)
        } else {
            // Just the scaled image height and some buffer space
            return (PROGRESS_VIEW_HEIGHT + BUFFER_WHITE_SPACE)
        }
    }
    
    
    static func labelSizeForString(string: String, fontSize: CGFloat) -> CGSize {
        let size:CGSize = CGSize(width: PROGRESS_VIEW_WIDTH, height: 2000.0)
        return (string as NSString).boundingRect(with: size,
                                                 options: .usesLineFragmentOrigin,
                                                 attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize)],
                                                 context: nil).size
    }

    // MARK: ProgressObserver delegate methods
    func observerDidChange(observer:ProgressObserver) {
        DispatchQueue.main.async {
            // Update the progress bar with the latest completion %
            self.progressView?.progress = Float(observer.progress!.fractionCompleted)
            print("progress changed completedUnitCount[" + String(stringInterpolationSegment: observer.progress?.completedUnitCount) + "]")
        }
    }
    
    func observerDidCancel(observer:ProgressObserver) {
        print("progress canceled")
    }
    
    func observerDidComplete(observer:ProgressObserver) {
        print("progress complete")

    }

}
