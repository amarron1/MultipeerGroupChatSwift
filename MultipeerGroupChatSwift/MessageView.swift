//
//  MessageView.swift
//  MultipeerGroupChatSwift
//
//  Created by amarron on 2016/12/09.
//  Copyright © 2016年 amarron. All rights reserved.
//

import Foundation
import UIKit

class MessageView: UIView {
    
    static let MESSAGE_VIEW_TAG:Int = 99
    
    // Constants for view sizing and alignment
    static let MESSAGE_FONT_SIZE:CGFloat        =  17.0
    static let NAME_FONT_SIZE:CGFloat           =  10.0
    static let BUFFER_WHITE_SPACE:CGFloat       =  14.0
    static let DETAIL_TEXT_LABEL_WIDTH:CGFloat  = 220.0
    static let NAME_OFFSET_ADJUST:CGFloat       =   4.0
    
    static let BALLOON_INSET_TOP:CGFloat        = 30 / 2
    static let BALLOON_INSET_LEFT:CGFloat       = 36 / 2
    static let BALLOON_INSET_BOTTOM:CGFloat     = 30 / 2
    static let BALLOON_INSET_RIGHT:CGFloat      = 46 / 2
    
    static let BALLOON_INSET_WIDTH:CGFloat      = BALLOON_INSET_LEFT + BALLOON_INSET_RIGHT
    static let BALLOON_INSET_HEIGHT:CGFloat     = BALLOON_INSET_TOP + BALLOON_INSET_BOTTOM
    
    static let BALLOON_MIDDLE_WIDTH:CGFloat     = 30 / 2
    static let BALLOON_MIDDLE_HEIGHT:CGFloat    =  6 / 2
    
    static let BALLOON_MIN_HEIGHT:CGFloat       = BALLOON_INSET_HEIGHT + BALLOON_MIDDLE_HEIGHT
    
    static let BALLOON_HEIGHT_PADDING:CGFloat   = 10
    static let BALLOON_WIDTH_PADDING:CGFloat    = 30

    
    var transcript:Transcript?
    
    // Background image
    var balloonView:UIImageView?
    // Message text string
    var messageLabel:UILabel?
    // Name text (for received messages)
    var nameLabel:UILabel?
    // Cache the background images and stretchable insets
    var balloonImageLeft:UIImage?
    var balloonImageRight:UIImage?
    var balloonInsetsLeft:UIEdgeInsets?
    var balloonInsetsRight:UIEdgeInsets?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Initialization the views
        self.balloonView =  UIImageView()
        self.messageLabel = UILabel()
        self.messageLabel?.numberOfLines = 0
        
        self.nameLabel = UILabel()
        self.nameLabel?.font = UIFont.systemFont(ofSize: MessageView.NAME_FONT_SIZE)
        self.nameLabel?.textColor = UIColor.init(colorLiteralRed: 34.0/255.0, green: 97.0/255.0, blue: 221.0/255.0, alpha: 1)
        
        self.balloonImageLeft = UIImage(named: "bubble-left.png")
        self.balloonImageRight = UIImage(named: "bubble-right.png")
        
        self.balloonInsetsLeft = UIEdgeInsetsMake(MessageView.BALLOON_INSET_TOP, MessageView.BALLOON_INSET_RIGHT, MessageView.BALLOON_INSET_BOTTOM, MessageView.BALLOON_INSET_LEFT)
        self.balloonInsetsRight = UIEdgeInsetsMake(MessageView.BALLOON_INSET_TOP, MessageView.BALLOON_INSET_LEFT, MessageView.BALLOON_INSET_BOTTOM, MessageView.BALLOON_INSET_RIGHT)
        
        // Add to parent view
        self.addSubview(self.balloonView!)
        self.addSubview(self.messageLabel!)
        self.addSubview(self.nameLabel!)
    }
    
    // Method for setting the transcript object which is used to build this view instance.
    func setTranscript(transcript:Transcript) {
        // Set the message text
        let messageText:String = (transcript.message ?? "")
        self.messageLabel?.text = messageText
        
        // Compute message size and frames
        let labelSize:CGSize = MessageView.labelSizeForString(string: messageText, fontSize: MessageView.MESSAGE_FONT_SIZE)
        let balloonSize:CGSize  = MessageView.balloonSizeForLabelSize(labelSize: labelSize)
        let nameText:String = transcript.peerID!.displayName
        let nameSize:CGSize  = MessageView.labelSizeForString(string: nameText, fontSize:MessageView.NAME_FONT_SIZE)
        
        // Comput the X,Y origin offsets
        var xOffsetLabel:CGFloat
        var xOffsetBalloon:CGFloat
        var yOffset:CGFloat
        
        if (.TRANSCRIPT_DIRECTION_SEND == transcript.direction) {
            // Sent messages appear or right of view
            xOffsetLabel = 320 - labelSize.width - (MessageView.BALLOON_WIDTH_PADDING / 2) - 3
            xOffsetBalloon = 320 - balloonSize.width
            yOffset = MessageView.BUFFER_WHITE_SPACE / 2
            self.nameLabel?.text = ""
            // Set text color
            self.messageLabel?.textColor = .white
            // Set resizeable image
            self.balloonView?.image = self.balloonImageRight?.resizableImage(withCapInsets: self.balloonInsetsRight!)
        } else {
            // Received messages appear on left of view with additional display name label
            xOffsetBalloon = 0
            xOffsetLabel = (MessageView.BALLOON_WIDTH_PADDING / 2) + 3
            yOffset = (MessageView.BUFFER_WHITE_SPACE / 2) + nameSize.height - MessageView.NAME_OFFSET_ADJUST
            if (.TRANSCRIPT_DIRECTION_LOCAL == transcript.direction) {
                self.nameLabel?.text = "Session Admin"
            } else {
                self.nameLabel?.text = nameText
            }
            // Set text color
            self.messageLabel?.textColor = .darkText
            // Set resizeable image
            self.balloonView?.image = self.balloonImageLeft?.resizableImage(withCapInsets: self.balloonInsetsLeft!)
        }
        
        // Set the dynamic frames
        self.messageLabel?.frame = CGRect(x: xOffsetLabel, y: yOffset + 5, width: labelSize.width, height: labelSize.height)
        self.balloonView?.frame = CGRect(x: xOffsetBalloon, y: yOffset, width: balloonSize.width, height: balloonSize.height)
        self.nameLabel?.frame = CGRect(x: xOffsetLabel - 2, y: 1, width: nameSize.width, height: nameSize.height)
    }
    
    
    // MARK: class methods for computing sizes based on strings
    static func viewHeightForTranscript(transcript:Transcript) -> CGFloat {
        let labelHeight:CGFloat = MessageView.balloonSizeForLabelSize(labelSize: MessageView.labelSizeForString(string: transcript.message, fontSize: MESSAGE_FONT_SIZE)).height
        if .TRANSCRIPT_DIRECTION_RECEIVE == transcript.direction {
            // Need to add extra height for display name
            let nameHeight:CGFloat = MessageView.labelSizeForString(string: transcript.peerID!.displayName, fontSize: NAME_FONT_SIZE).height
            return (labelHeight + nameHeight + BUFFER_WHITE_SPACE - NAME_OFFSET_ADJUST)
        } else {
            return (labelHeight + BUFFER_WHITE_SPACE)
        }
    }
    
    static func labelSizeForString(string:String?, fontSize:CGFloat) -> CGSize {
        let size:CGSize = CGSize(width: DETAIL_TEXT_LABEL_WIDTH, height: 2000.0)
        return ((string ?? "") as NSString).boundingRect(with: size,
                               options: .usesLineFragmentOrigin,
                               attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize)],
                               context: nil).size
    }
    
    static func balloonSizeForLabelSize(labelSize: CGSize) -> CGSize {
        if labelSize.height < BALLOON_INSET_HEIGHT {
            return CGSize(width: labelSize.width + BALLOON_WIDTH_PADDING, height: BALLOON_MIN_HEIGHT)
        } else {
            return CGSize(width: labelSize.width + BALLOON_WIDTH_PADDING, height: labelSize.height + BALLOON_HEIGHT_PADDING)
        }
    }
}
