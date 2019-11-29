//
//  FullSecreenVideo.swift
//  VideoPlayer
//
//  Created by Samrat on 18/11/19.
//  Copyright © 2019 Samrat. All rights reserved.
//

import UIKit

class FullSecreenVideo: UIViewController {
    
    var previousPlaybackViewSuperview: UIView?
    var previousPlaybackViewFrame: CGRect?
    var previousPlaybackViewControlsSuperview: UIView?
    var previousPlaybackViewControlsFrame: CGRect?
    
    var playbackView: VideoPlayer? {
        willSet {
            previousPlaybackViewSuperview = newValue?.superview
            previousPlaybackViewFrame = newValue?.frame
        }
        didSet {
            guard let playbackView = playbackView else { return }
            view.addSubview(playbackView)
            playbackView.frame = view.bounds
        }
    }
    
    var playbackControlsView: UIView? {
        willSet {
            previousPlaybackViewControlsSuperview = newValue?.superview
            previousPlaybackViewControlsFrame = newValue?.frame
        }
        didSet {
            guard let playbackView = playbackView else { return }
            view.addSubview(playbackView)
            playbackView.frame = view.bounds
        }
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async {
            
            self.playbackView?.frame = self.view.bounds
            
            let controlsHeight = self.playbackControlsView?.bounds.height ?? 140.0
//            if #available(iOS 11.0, *) {
//                self.playbackControlsView?.frame = CGRect(x: 0.0, y: self.view.bounds.height - self.view.safeAreaInsets.bottom - controlsHeight,
//                                                          width: self.view.bounds.width,
//                                                          height: controlsHeight)
//            } else {
                self.playbackControlsView?.frame = CGRect(x: 0.0, y: self.view.bounds.height - controlsHeight,
                                                          width: self.view.bounds.width,
                                                          height: controlsHeight)
//            }
            self.playbackView?.layoutSubviews()
        }
    }
    
//    override func viewWillLayoutSubviews() {
//        super.viewWillLayoutSubviews()
//
//    }
}
