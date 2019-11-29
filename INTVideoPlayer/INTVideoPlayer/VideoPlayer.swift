//
//  VideoPlayer.swift
//  VideoPlayer
//
//  Created by Samrat on 18/11/19.
//  Copyright © 2019 Samrat. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

open class VideoPlayer: UIView {
    //MARK: Outlets
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var volumeButton: UIButton!
    @IBOutlet weak var loaderView: LoaderView?
    @IBOutlet weak var playerBottomView: UIView!
    @IBOutlet weak var expandButton: UIButton!
    @IBOutlet weak var playerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var playerSlider: UISlider!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var fullTime: UILabel!
    
    fileprivate var parentController: UIViewController?
    fileprivate var fullScreenController: FullSecreenVideo?
    fileprivate var previousSuperviewConstraints: [NSLayoutConstraint] = []
    fileprivate var previousSelfConstraints: [NSLayoutConstraint] = []
    fileprivate var timer:Timer?
    fileprivate var isFullScreen: Bool = false
    
    //MARK: Internal Properties
    public var isMuted = true {
        didSet {
            self.player?.isMuted = self.isMuted
            self.volumeButton.isSelected = self.isMuted
        }
    }
    public var isToShowPlaybackControls = true {
        didSet {
            if !isToShowPlaybackControls {
                self.layoutIfNeeded()
            }
        }
    }
    
    //MARK: Private Properties
    open var playerLayer: AVPlayerLayer?
    open var player: AVPlayer?
    open var playerItem: AVPlayerItem?
    
    private enum Constants {
        static let nibName = "VideoPlayer"
        static let rewindForwardDuration: Float64 = 10 //in seconds
    }
    
    //MARK: Lifecycle Methods
    override open func layoutSubviews() {
        super.layoutSubviews()
        self.playerLayer?.frame = self.videoView.bounds
    }
    
    deinit {
        removeAllObserver()
        NotificationCenter.default.removeObserver(self)
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "status" {
            
            observePlayerStatus()
            
        } else if keyPath == "timeControlStatus", let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int {
            let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
            DispatchQueue.main.async {[weak self] in
                if newStatus == .playing || newStatus == .paused {
                    self?.loaderView?.isHidden = true
                } else {
                    self?.loaderView?.isHidden = false
                }
            }
        }
    }
    
    func removeAllObserver() {
        player?.removeObserver(self, forKeyPath: "timeControlStatus")
        player?.removeObserver(self, forKeyPath: "rate")
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem?.removeObserver(self, forKeyPath: "status")
        
    }
    
    //MARK: Public Methods
    open class func initialize(with frame: CGRect, controller: UIViewController) -> VideoPlayer? {
        let bundle = Bundle(for: VideoPlayer.self)
        let view = bundle.loadNibNamed(Constants.nibName, owner: self, options: nil)?.first as? VideoPlayer
        view?.frame = frame
        view?.parentController = controller
        return view
    }
    
    public func loadVideo(with url: URL) {
        self.loadVideos(with: url)
    }
    
    public func loadVideos(with url: URL) {
        removeAllObserver()
        let asset = AVAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)
        
        player =  AVPlayer(playerItem: playerItem)
        
//        self.expandButton.setBackgroundImage(UIImage(named: "expand"), for: .normal)
        self.expandButton.isSelected = false
        self.playerBottomView.alpha = 0
        let playerLayer = self.playerLayer(with: player ?? AVPlayer())
        self.videoView.layer.insertSublayer(playerLayer, at: 0)
        playerSlider.tintColor = UIColor.white
        playerSlider.backgroundColor = UIColor.clear
        playerSlider.maximumTrackTintColor = UIColor.gray
        playerSlider.minimumTrackTintColor = UIColor.white
        playerSlider.minimumValue = 0
        playerSlider.isContinuous = false
        playerSlider.addTarget(self, action: #selector(touchPlayerProgress), for: [.touchDown, .touchUpInside])
        setPlayerObserver()
    }
    
    public func playVideo() {
        self.player?.play()
        self.playPauseButton.isSelected = true
    }
    
    public func pauseVideo() {
        self.player?.pause()
        self.playPauseButton.isSelected = false
    }
    
    //MARK:- timer
    fileprivate func startTimer() {
        
        timer = Timer()
        timer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(setPlayBottomViewAnimation), userInfo: nil, repeats: false)
    }
    
    fileprivate func stopTimer() {
        
        if timer == nil {
            return
        }
        timer?.invalidate()
        timer = nil
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        setPlayBottomViewAnimation()
        stopTimer()
        if player?.rate == 1 && playerBottomView.alpha == 1 {
            startTimer()
        }
    }
    
    @objc fileprivate func setPlayBottomViewAnimation() {
        
        UIView.animate(withDuration: 0.5) {
            if self.playerBottomView.alpha == 0 {
                self.playerBottomView.alpha = 1
            } else {
                self.playerBottomView.alpha = 0
            }
        }
        
    }
    
    @objc fileprivate func touchPlayerProgress() {
        
        if playerSlider.isHighlighted {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    //MARK:- calculate time formatter
    fileprivate func timeFotmatter(_ time:Float) -> String {
        
        var hr:Int!
        var min:Int!
        var sec:Int!
        var timeString: String = "00:00:00"
        
        if time >= 3600 {
            hr = Int(time / 3600)
            min = Int(time.truncatingRemainder(dividingBy: 3600))
            sec = Int(min % 60)
            timeString = String(format: "%02d:%02d:%02d", hr, min, sec)
        } else if time >= 60 && time < 3600 {
            min = Int(time / 60)
            sec = Int(time.truncatingRemainder(dividingBy: 60))
            timeString = String(format: "00:%02d:%02d", min, sec)
        } else if time < 60 {
            sec = Int(time)
            timeString = String(format: "00:00:%02d", sec)
        }
        
        return timeString
    }
    
    //MARK: Button Action Methods
    @IBAction private func onTapPlayPauseVideoButton(_ sender: UIButton) {
        if sender.isSelected {
            self.pauseVideo()
        } else {
            self.playVideo()
        }
    }
    
    @IBAction private func onTapExpandVideoButton(_ sender: UIButton) {
        if isFullScreen {
            isFullScreen = false
//            expandButton.setBackgroundImage(UIImage(named: "expand"), for: .normal)
             self.expandButton.isSelected = false
            // dismiss full screen
            fullScreenController?.dismiss(animated: false, completion: {
                if let previousPlaybackViewSuperview = self.fullScreenController?.previousPlaybackViewSuperview {
                    previousPlaybackViewSuperview.addSubview(self)
                }
                self.translatesAutoresizingMaskIntoConstraints = false
                self.fullScreenController?.playbackControlsView?.translatesAutoresizingMaskIntoConstraints = false
                self.superview?.addConstraints(self.previousSuperviewConstraints)
                self.addConstraints(self.previousSelfConstraints)
            })
            playerBottomConstraint.constant = 0
        } else {
            var bottomSafeAreaHeight: CGFloat = 0
            
            if #available(iOS 11.0, *) {
                let window = UIApplication.shared.windows[0]
                let safeFrame = window.safeAreaLayoutGuide.layoutFrame
                bottomSafeAreaHeight = window.frame.maxY - safeFrame.maxY
                playerBottomConstraint.constant = bottomSafeAreaHeight
            }
//            expandButton.setBackgroundImage(UIImage(named: "exitFull"), for: .normal)
             self.expandButton.isSelected = true
            isFullScreen = true
            previousSuperviewConstraints = superview?.constraints ?? []
            previousSelfConstraints = constraints
            superview?.removeConstraints(superview?.constraints ?? [])
            //            removeConstraints(constraints)
            fullScreenController = FullSecreenVideo()
            fullScreenController?.modalTransitionStyle = .crossDissolve
            translatesAutoresizingMaskIntoConstraints = true
            fullScreenController?.playbackView = self
            
            fullScreenController?.playbackControlsView = self.superview
            fullScreenController?.playbackControlsView?.translatesAutoresizingMaskIntoConstraints = true
            self.parentController?.present(fullScreenController!, animated: false, completion: nil)
        }
        
    }
    
    @IBAction private func onTapVolumeButton(_ sender: UIButton) {
        self.isMuted = !sender.isSelected
    }
    
    @IBAction private func onTapRewindButton(_ sender: UIButton) {
        if let currentTime = self.player?.currentTime() {
            var newTime = CMTimeGetSeconds(currentTime) - Constants.rewindForwardDuration
            if newTime <= 0 {
                newTime = 0
            }
            self.player?.seek(to: CMTime(value: CMTimeValue(newTime * 1000), timescale: 1000))
        }
    }
    
    @IBAction private func onTapForwardButton(_ sender: UIButton) {
        if let currentTime = self.player?.currentTime(), let duration = self.player?.currentItem?.duration {
            var newTime = CMTimeGetSeconds(currentTime) + Constants.rewindForwardDuration
            if newTime >= CMTimeGetSeconds(duration) {
                newTime = CMTimeGetSeconds(duration)
            }
            self.player?.seek(to: CMTime(value: CMTimeValue(newTime * 1000), timescale: 1000))
        }
    }
}

// MARK: - Private Methods
private extension VideoPlayer {
    
    //MARK:- check playItem status
    func observePlayerStatus() {
        let status: AVPlayerItem.Status = playerItem?.status ?? (player?.currentItem?.status)!
        switch status {
        case .readyToPlay:
            if let playerItem = playerItem {
                if Float(CMTimeGetSeconds((playerItem.duration))).isNaN  == true { break }
                playerSlider.addTarget(self, action: #selector(changePlayerProgress), for: .valueChanged)
                playerSlider.maximumValue = Float(CMTimeGetSeconds((playerItem.duration)))
            }

            break
        case .failed:

            break
        default:

            break
        }
    }
    
    func setPlayerObserver() {
        
        player?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        player?.addObserver(self, forKeyPath: "timeControlStatus", options:  .new, context: nil)

        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 2), queue: DispatchQueue.main) {[weak self] (progressTime) in
            if let duration = self?.player?.currentItem?.duration {
                
                let durationSeconds = CMTimeGetSeconds(duration)
                let seconds = CMTimeGetSeconds(progressTime)
                let progress = Float(seconds/durationSeconds)
                
                if let playerItem = self?.playerItem {
                    let during = playerItem.currentTime()
                    let allTimeString = self?.timeFotmatter(Float(CMTimeGetSeconds((playerItem.duration))))
                    let time = during.value / Int64(during.timescale)
                    self?.currentTime.text = self?.timeFotmatter(Float(time))
                    self?.fullTime.text = allTimeString
                    if !(self?.playerSlider.isHighlighted)! {
                        self?.playerSlider.value = Float(time)
                    }
                }
               
                
                DispatchQueue.main.async {
                    self?.progressBar.progress = progress
                    if progress >= 1.0 {
                        self?.progressBar.progress = 0.0
                    }
                }
            }
        }
//        player?.addObserver(self, forKeyPath: "status", options: [.initial, .new], context: nil)
       
        NotificationCenter.default.addObserver(self, selector: #selector(playerEndedPlaying), name: Notification.Name("AVPlayerItemDidPlayToEndTimeNotification"), object: nil)
        
    }
    
    func playerLayer(with player: AVPlayer) -> AVPlayerLayer {
        self.layoutIfNeeded()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.videoView.bounds
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        playerLayer.contentsGravity = CALayerContentsGravity.resizeAspect
        self.playerLayer = playerLayer
        return playerLayer
    }
    
    @objc func playerEndedPlaying(_ notification: Notification) {
        DispatchQueue.main.async {[weak self] in
            if let playerItem = notification.object as? AVPlayerItem {
                playerItem.seek(to: CMTime.zero, completionHandler: nil)
                self?.playVideo()
            }
        }
    }
    
    //MARK:- change player progress
    @objc func changePlayerProgress() {
        
        let seekDuration = playerSlider.value
        player?.seek(to: CMTimeMake(value: Int64(seekDuration), timescale: 1), completionHandler: { (BOOL) in
        })
        
    }
}

extension AVPlayerViewController {
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player?.pause()
    }
}

