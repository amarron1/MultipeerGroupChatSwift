//
//  ImageView.swift
//  MultipeerGroupChatSwift
//
//  Created by amarron on 2016/12/04.
//  Copyright © 2016年 amarron. All rights reserved.
//

import Foundation
import UIKit

class ImageView: UIView {
    
    static let IMAGE_VIEW_TAG:Int = 100
    
    static let IMAGE_VIEW_HEIGHT_MAX:CGFloat   = 140.0
    static let IMAGE_PADDING_X:CGFloat         = 15.0
    static let NAME_FONT_SIZE:CGFloat          = 10.0
    static let BUFFER_WHITE_SPACE:CGFloat      = 14.0
    static let DETAIL_TEXT_LABEL_WIDTH:CGFloat = 220.0
    static let PEER_NAME_HEIGHT:CGFloat        = 12.0
    static let NAME_OFFSET_ADJUST:CGFloat      = 4.0
    
    var transcript:Transcript?
    
    // Background image
    var imageView:UIImageView?
    // Name text (for received messages)
    var nameLabel:UILabel?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Initialization the views
        self.imageView = UIImageView()
        self.imageView?.layer.cornerRadius = 5.0
        self.imageView?.layer.masksToBounds = true
        self.imageView?.layer.borderColor = UIColor.lightGray.cgColor
        self.imageView?.layer.borderWidth = 0.5
        
        self.nameLabel = UILabel()
        self.nameLabel?.font = UIFont.systemFont(ofSize: 10.0)
        self.nameLabel?.textColor = UIColor(colorLiteralRed: 34.0/255.0, green: 97.0/255.0, blue: 221.0/255.0, alpha: 1)
        
        // Add to parent view
        self.addSubview(self.imageView!)
        self.addSubview(self.nameLabel!)
    }
    
    // Method for setting the transcript object which is used to build this view instance.
    func setTranscript(transcript:Transcript) {
        // Load the image the specificed resource URL points to.
        let image:UIImage = UIImage(contentsOfFile: (transcript.imageUrl?.path)!)!
        self.imageView?.image = image
        
        // Get the image size and scale based on our max height (if necessary)
        let imageSize:CGSize  = image.size
        var height:CGFloat  = imageSize.height
        var scale:CGFloat  = 1.0
        
        // Compute scale between the original image and our max row height
        scale = (ImageView.IMAGE_VIEW_HEIGHT_MAX / height)
        height = ImageView.IMAGE_VIEW_HEIGHT_MAX
        // Scale the width
        let width:CGFloat = imageSize.width * scale
        
        // Compute name size
        let nameText:String = transcript.peerID!.displayName
        let nameSize:CGSize = ImageView.labelSizeForString(string: nameText, fontSize:ImageView.NAME_FONT_SIZE)
        
        // Comput the X,Y origin offsets
        var xOffsetBalloon:CGFloat
        var yOffset:CGFloat
        
        if (.TRANSCRIPT_DIRECTION_SEND == transcript.direction) {
            // Sent images appear or right of view
            xOffsetBalloon = 320 - width - ImageView.IMAGE_PADDING_X
            yOffset = ImageView.BUFFER_WHITE_SPACE / 2
            self.nameLabel?.text = ""
        } else {
            // Received images appear on left of view with additional display name label
            xOffsetBalloon = ImageView.IMAGE_PADDING_X
            yOffset = (ImageView.BUFFER_WHITE_SPACE / 2) + nameSize.height - ImageView.NAME_OFFSET_ADJUST
            self.nameLabel?.text = nameText
        }
        
        // Set the dynamic frames
        self.nameLabel?.frame = CGRect(x: xOffsetBalloon, y: 1, width: nameSize.width, height: nameSize.height)
        self.imageView?.frame = CGRect(x: xOffsetBalloon, y: yOffset, width: width, height: height)
    }
    
    
    // MARK: class methods for computing sizes based on strings
    static func viewHeightForTranscript(transcript:Transcript) -> CGFloat {
        // Return dynamic height of the cell based on the particular transcript
        if .TRANSCRIPT_DIRECTION_RECEIVE == transcript.direction {
            // The senders name height is included for received messages
            return (PEER_NAME_HEIGHT + IMAGE_VIEW_HEIGHT_MAX + BUFFER_WHITE_SPACE - NAME_OFFSET_ADJUST)
        } else {
            // Just the scaled image height and some buffer space
            return (IMAGE_VIEW_HEIGHT_MAX + BUFFER_WHITE_SPACE)
        }
    }
    
    static func labelSizeForString(string:String, fontSize:CGFloat) -> CGSize {
        let size:CGSize = CGSize(width: DETAIL_TEXT_LABEL_WIDTH, height: 2000.0)
        return (string as NSString).boundingRect(with: size,
                                                 options: .usesLineFragmentOrigin,
                                                 attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize)],
                                                 context: nil).size
    }
}
