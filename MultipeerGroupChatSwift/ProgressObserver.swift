//
//  ProgressObserver.swift
//  MultipeerGroupChatSwift
//
//  Created by amarron on 2016/12/04.
//  Copyright © 2016年 amarron. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class ProgressObserver: NSObject {
    // Human readable name string for this observer
    var name:String?
    // NSProgress this class is monitoring
    var progress:Progress?
    // Delegate for receiving change events
    var delegate:ProgressObserverDelegate?
    
    // KVO path strings for observing changes to properties of NSProgress
    static let kProgressCancelledKeyPath:String = "cancelled"
    static let kProgressCompletedUnitCountKeyPath:String = "completedUnitCount"
 
    func initWithName(name:String, progress:Progress) -> ProgressObserver {
        self.name = name
        self.progress = progress
        // Add KVO observer for the cancelled and completed unit count properties of NSProgress
        self.progress?.addObserver(self, forKeyPath: ProgressObserver.kProgressCancelledKeyPath, options: .new, context: nil)
        self.progress?.addObserver(self, forKeyPath: ProgressObserver.kProgressCompletedUnitCountKeyPath, options: .new, context: nil)
        return self
    }
    
    deinit {
        // stop KVO
        self.progress?.removeObserver(self, forKeyPath: ProgressObserver.kProgressCancelledKeyPath)
        self.progress?.removeObserver(self, forKeyPath: ProgressObserver.kProgressCompletedUnitCountKeyPath)
        self.progress = nil

    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let progress:Progress = object as! Progress
        // Check which KVO key change has fired
        if keyPath == ProgressObserver.kProgressCancelledKeyPath {
            // Notify the delegate that the progress was cancelled
            self.delegate?.observerDidCancel(observer: self)
        } else if keyPath == ProgressObserver.kProgressCompletedUnitCountKeyPath {
            // Notify the delegate of our progress change
            self.delegate?.observerDidChange(observer: self)
            if progress.completedUnitCount == progress.totalUnitCount {
                // Progress completed, notify delegate
                self.delegate?.observerDidComplete(observer: self)
            }
        }
    }
}

// Protocol for notifying listeners of changes to the NSProgress we are observing
protocol ProgressObserverDelegate {
    // Called when there is a change to the completion % of the resource transfer
    func observerDidChange(observer:ProgressObserver)
    // Called when cancel is called on the NSProgress
    func observerDidCancel(observer:ProgressObserver)
    // Called when the resource transfer is complete
    func observerDidComplete(observer:ProgressObserver)
}


