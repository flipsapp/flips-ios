//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit
import AssetsLibrary

class PlayerView: UIView {

    let BUTTONS_FADE_IN_OUT_ANIMATION_DURATION: NSTimeInterval = 0.25
    let BUTTONS_ALPHA: CGFloat = 0.6
    let PROGRESS_BAR_PADDING: CGFloat = 30
    let PROGRESS_BAR_HEIGHT: CGFloat = 10
    let RETRY_LABEL_PADDING: CGFloat = 10
    let RETRY_LABEL_CORNER_RADIUS: CGFloat = 10

    var isPlaying = false
    var loadPlayerOnInit = false
    var playInLoop = false
    var loadingFlips = false
    var hasDownloadError = false
    var originalSessionCategory : String! = nil
    
    private var flips: Array<Flip>!
    private var words: Array<String>?
    private var playerItems: Array<FlipPlayerItem> = [FlipPlayerItem]()
    private var flipsDownloadProgress: Array<Float> = [Float]()
    private var thumbnail: UIImage?
    private var timer: NSTimer?

    private var gradientLayer: UIImageView!
    private var wordLabel: UILabel!
    private var thumbnailView: UIImageView!
    private var playButtonView: UIImageView!
    private var retryLabel: UILabel!
    private var progressBarView: ProgressBar!

    weak var delegate: PlayerViewDelegate?
    
    private var contentIdentifier: String?
    
    var loadedPlayerItems : Array<FlipPlayerItem> {
        get {
            return self.playerItems
        }
    }
    
    var flipWordsStrings : [String] {
        get {
            return words!
        }
    }
    
    // MARK: - Initializers

    init() {
        super.init(frame: CGRectZero)
        
        self.addSubviews()
        self.makeConstraints()

        self.contentIdentifier = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addSubviews()
        self.makeConstraints()
        
        self.contentIdentifier = nil
    }
    
    deinit {
        self.releaseResources()
    }

    override class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }


    // MARK: - Accessors

    private func player() -> AVQueuePlayer? {
        let layer = self.layer as! AVPlayerLayer
        if let player = layer.player {
            return player as? AVQueuePlayer
        }
        return nil
    }

    private func setPlayer(player: AVPlayer?) {
        let layer = self.layer as! AVPlayerLayer
        layer.player = player
    }

    private func setWord(word: String) {
        self.wordLabel.text = word
    }
    
    private func generateRandomIdentifier() {
        self.contentIdentifier = NSUUID().UUIDString
    }


    // MARK: - Animations

    private func fadeAnimation(animations: () -> Void, completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIView.animateWithDuration(self.BUTTONS_FADE_IN_OUT_ANIMATION_DURATION, animations: animations, completion: { (finished) -> Void in
                completion?()
                return
            })
        })
    }

    private func fadeToPlayingState(completion: (() -> Void)? = nil) {
        self.fadeAnimation({ () -> Void in
            self.playingViewState()
        }, completion: completion)
    }

    private func fadeToPausedState(completion: (() -> Void)? = nil) {
        self.fadeAnimation({ () -> Void in
            self.pausedViewState()
        }, completion: completion)
    }

    private func fadeToErrorState(completion: (() -> Void)? = nil) {
        self.fadeAnimation({ () -> Void in
            self.errorViewState()
        }, completion: completion)
    }

    private func fadeToDownloadingState(completion: (() -> Void)? = nil) {
        self.fadeAnimation({ () -> Void in
            self.downloadingViewState()
        }, completion: completion)
    }


    // MARK: - Playback control

    func play() {
        
        originalSessionCategory = AVAudioSession.sharedInstance().category
        
        do
        {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        }
        catch _ {}
        
        self.timer?.invalidate()

        if (self.loadingFlips) {
            return
        }

        var isPlayerReady = false

        // Single word
        if ((self.flips == nil) && (self.playerItems.count > 0)) {
            isPlayerReady = true
        } else {
            if (self.flips != nil) {
                isPlayerReady = self.playerItems.count == self.flips.count
            }
        }

        if (isPlayerReady) {
            let currentIdentifier = self.contentIdentifier
            self.preparePlayer { (player) -> Void in
                if ((self.words != nil) && (self.words!.count == 0)) {
                    return
                }
                
                if (currentIdentifier != self.contentIdentifier) {
                    return
                }

                if let playerItem: FlipPlayerItem = player?.currentItem as? FlipPlayerItem {
                    if ((self.words != nil) && (self.words?.count > playerItem.order)) {
                        self.setWord(self.words![playerItem.order])
                    }
                    
                    if (player != nil) {
                        if (player!.status == AVPlayerStatus.ReadyToPlay) {
                            self.fadeToPlayingState({ () -> Void in
                                
                                // Since it needs to wait the animation, the user can press back button, so it won't exist.
                                if (currentIdentifier != self.contentIdentifier) {
                                    return
                                }
                                
                                self.isPlaying = true
                                player!.volume = 1.0
                                player!.play()
                            })
                        } else {
                            player!.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
                            self.isPlaying = true
                            player!.volume = 1.0
                            player!.play()
                        }
                    }
                }
            }
        } else {
            let isLoadingStarted: Bool = self.loadFlipsResourcesForPlayback({ () -> Void in
                self.play()
            })
            
            if (!isLoadingStarted) {
                // Retry after half second
                let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
                dispatch_after(delay, dispatch_get_main_queue(), { () -> Void in
                    var _: Bool = self.loadFlipsResourcesForPlayback({ () -> Void in
                        self.play()
                    })
                })
            }
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let player = self.player() {
            if (object as! AVQueuePlayer == player && keyPath == "status") {
                if (player.status == AVPlayerStatus.ReadyToPlay) {
                    self.fadeToPlayingState(nil)
                }
            }
            player.removeObserver(self, forKeyPath: "status")
        }
    }
    
    private func fadeOutVolume() {
        if let player = self.player() {
            if (player.volume > 0) {
                if (player.volume <= 0.2) {
                    player.volume = 0.0
                } else {
                    player.volume -= 0.2
                }
                
                weak var weakSelf = self
                
                let seconds = 0.1 * Double(NSEC_PER_SEC)
                let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds))
                dispatch_after(delay, dispatch_get_main_queue(), { () -> Void in
                    weakSelf?.fadeOutVolume()
                    return ()
                })
            } else {
                player.pause()
            }
        }
    }

    func pause(fadeOutVolume: Bool = false) {
        self.timer?.invalidate()
        self.loadPlayerOnInit = false
        
        if (!self.isPlaying) {
            return
        }
        
        if (fadeOutVolume) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.isPlaying = false
                self.fadeToPausedState()
                self.fadeOutVolume()
            })
        } else {
            self.isPlaying = false
            self.fadeToPausedState()
            if let player = self.player() {
                player.pause()
            }
        }
    }

    func pauseResume() {
        self.timer?.invalidate()
        
        if (self.isPlaying) {
            self.pause()
        } else {
            self.play()
        }
    }
    
    private func onFlipMessagePlaybackFinishedWithCompletion(completionBlock: (() -> Void)?) {
        
        if self.originalSessionCategory != nil {
            do {
                try AVAudioSession.sharedInstance().setCategory(originalSessionCategory)
            } catch _ {}
        }
        
        delegate?.playerViewDidFinishPlayback(self)
        
        let currentIdentifier = self.contentIdentifier
        
        // Change the thumbnail
        if (self.flips != nil) {
            if let firstFlip = self.flips.first {
                if (firstFlip.thumbnailURL != nil && !firstFlip.thumbnailURL.isEmpty) {
                    if let remoteURL: NSURL = NSURL(string: firstFlip.thumbnailURL) {
                        ThumbnailsCache.sharedInstance.get(remoteURL, success: { (url: String!, localThumbnailPath: String!) -> Void in
                            if (currentIdentifier != self.contentIdentifier) {
                                completionBlock?()
                                return
                            }
                            
                            let thumbnail: UIImage? = UIImage(contentsOfFile: localThumbnailPath)
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                if (currentIdentifier != self.contentIdentifier) {
                                    completionBlock?()
                                    return
                                }
                                
                                self.thumbnailView.image = thumbnail
                                
                                completionBlock?()
                            })
                        }, failure: { (url: String!, flipError: FlipError) -> Void in
                            print("Failed to get resource from cache, error: \(flipError)")
                            completionBlock?()
                        })

                        return
                    }
                }
            }
        }
        completionBlock?()
    }


    // MARK: - View update

    private func updateDownloadProgress(progress: Float, of: Float, animated: Bool, duration: NSTimeInterval = 0.3, completion:(() -> Void)? = nil) {
        let progressRatio = progress / of

        // Avoid going back in the progress bar
        if (progressRatio < self.progressBarView.progress) {
            return
        }

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.progressBarView.setProgress(progressRatio,
                animated: animated,
                duration: duration,
                completion: completion
            )
        })
    }

    private func showErrorState() {
        self.loadingFlips = false
        self.hasDownloadError = true
        self.playerItems.removeAll(keepCapacity: true)
        self.progressBarView.progress = 0

        self.fadeToErrorState()
    }


    // MARK: - View state

    private func errorViewState() {
        self.thumbnailView.alpha = 1.0
        self.playButtonView.alpha = 0.0
        self.progressBarView.alpha = 0.0
        self.retryLabel.alpha = 1.0
    }

    private func downloadingViewState() {
        self.thumbnailView.alpha = 1.0
        self.playButtonView.alpha = 0.0
        self.progressBarView.alpha = 1.0
        self.retryLabel.alpha = 0.0
    }

    private func playingViewState() {
        self.thumbnailView.alpha = 0.0
        self.playButtonView.alpha = 0.0
        self.progressBarView.alpha = 0.0
        self.retryLabel.alpha = 0.0
    }

    private func pausedViewState() {
        self.thumbnailView.alpha = 0.0
        self.playButtonView.alpha = self.BUTTONS_ALPHA
        self.progressBarView.alpha = 0.0
        self.progressBarView.progress = 0.0
        self.retryLabel.alpha = 0.0
    }

    private func initialViewState() {
        self.thumbnailView.alpha = 1.0

        self.playButtonView.alpha = 0.0
        if let shouldShowPlayButton = self.delegate?.playerViewShouldShowPlayButtonOnInitialState(self) {
            if (shouldShowPlayButton) {
                self.playButtonView.alpha = self.BUTTONS_ALPHA
            }
        }

        self.progressBarView.alpha = 0.0
        self.progressBarView.progress = 0.0
        self.retryLabel.alpha = 0.0
    }


    // MARK: - Resource loading

    func loadFlipsResourcesForPlayback(completion: () -> Void) -> Bool {
        let currentIdentifier = self.contentIdentifier
        
        self.loadingFlips = true
        self.hasDownloadError = false
        
        self.playerItems.removeAll(keepCapacity: true)
        
        var isWordsPreInitialized: Bool = true
        if (self.words == nil) {
            self.words = []
            isWordsPreInitialized = false
        }
        
        if let flipsArray: Array<Flip> = self.flips {
            for (index, flip) in flipsArray.enumerate() {
                if (currentIdentifier != self.contentIdentifier) {
                    return true // shouldn't retry
                }
                
                if (!isWordsPreInitialized) {
                    self.words!.append(flip.word)
                }
                
                if (flip.backgroundURL == nil || flip.backgroundURL.isEmpty) {
                    let emptyVideoPath = NSBundle.mainBundle().pathForResource("empty_video", ofType: "mov")
                    let videoAsset = AVURLAsset(URL: NSURL(fileURLWithPath: emptyVideoPath!), options: nil)
                    let playerItem = self.playerItemWithVideoAsset(videoAsset)
                    playerItem.order = index
                    self.playerItems.append(playerItem)
                    
                    self.flipsDownloadProgress[index] = 1.0
                    
                    let animated = flipsArray.count > 1
                    
                    self.updateDownloadProgress(Float(self.playerItems.count),
                        of: Float(flipsArray.count),
                        animated: animated,
                        completion: { () -> Void in
                            if (currentIdentifier != self.contentIdentifier) {
                                return
                            }
                            
                            if (self.playerItems.count == flipsArray.count) {
                                self.loadingFlips = false
                                self.sortPlayerItems()
                                completion()
                            }
                        }
                    )
                    
                } else {
                    let response = FlipsCache.sharedInstance.get(NSURL(string: flip.backgroundURL)!,
                        success: { (url: String!, localPath: String!) in
                            if (self.hasDownloadError) {
                                return
                            }
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                if (currentIdentifier != self.contentIdentifier) {
                                    return
                                }
                                
                                let videoAsset = AVURLAsset(URL: NSURL(fileURLWithPath: localPath), options: nil)
                                let playerItem = self.playerItemWithVideoAsset(videoAsset)
                                playerItem.order = index
                                self.playerItems.append(playerItem)
                                
                                self.flipsDownloadProgress[index] = 1.0
                                
                                if (self.playerItems.count == flipsArray.count) {
                                    self.loadingFlips = false
                                    self.sortPlayerItems()
                                    
                                    completion()
                                }
                            })
                        },
                        failure: { (url: String!, error: FlipError) in
                            print("Failed to get resource from cache, error: \(error)")
                            if (currentIdentifier != self.contentIdentifier) {
                                return
                            }
                            
                            self.showErrorState()
                        },
                        progress: { (p: Float) -> Void in
                            if (currentIdentifier != self.contentIdentifier) {
                                return
                            }
                            
                            self.flipsDownloadProgress[index] = p
                            
                            var progressPosition: Float = 0.0
                            for ratio in self.flipsDownloadProgress {
                                progressPosition += ratio
                            }
                            
                            self.updateDownloadProgress(progressPosition,
                                of: Float(self.flipsDownloadProgress.count),
                                animated: true,
                                completion: nil
                            )
                        }
                    )
                    
                    if (response == StorageCache.CacheGetResponse.DOWNLOAD_WILL_START) {
                        self.fadeToDownloadingState()
                    }
                }
            }
        } else {
            self.loadingFlips = false
            return false
        }
        return true
    }

    private func sortPlayerItems() {
        self.playerItems.sortInPlace { (itemOne: FlipPlayerItem, itemTwo: FlipPlayerItem) -> Bool in
            return itemOne.order < itemTwo.order
        }
    }

    func isSetupWithFlips(flips: Array<Flip>, andFormattedWords formattedWords: Array<String>? = nil) -> Bool {
        if (flips.count != self.flips.count) {
            return false
        }

        for i in 0 ..< flips.count {
            let passedFlip = flips[i]
            let localFlip = self.flips[i]
            
            print("\(passedFlip)")
            print("\(localFlip)")
            
            if (flips[i].flipID! != self.flips[i].flipID!) {
                return false
            }
        }

        if (formattedWords != nil) {
            if (formattedWords?.count != self.words?.count) {
                return false
            }

            for i in (0 ..< formattedWords!.count) {
                if (formattedWords![i] != self.words![i]) {
                    return false
                }
            }
        }

        return true
    }

    func setupPlayerWithFlips(flips: Array<Flip>, andFormattedWords formattedWords: Array<String>? = nil, blurringThumbnail: Bool = false) {
        self.generateRandomIdentifier()
        
        let currentIdentifier = self.contentIdentifier
        
        self.flips = flips
        self.flipsDownloadProgress = [Float]()
        for _ in (0 ..< flips.count) {
            self.flipsDownloadProgress.append(0.0);
        }

        self.words = formattedWords
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.progressBarView.progress = 0.0
        })
            
        let firstFlip = flips.first
        if (firstFlip != nil) {

            var word = firstFlip!.word
            if (formattedWords != nil) {
                word = formattedWords!.first
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.wordLabel.text = word
            })

            if (firstFlip!.thumbnailURL != nil && !firstFlip!.thumbnailURL.isEmpty) {
                if let remoteURL: NSURL = NSURL(string: firstFlip!.thumbnailURL) {
                    
                    var cacheInstance: ThumbnailsDataSource!
                    if (blurringThumbnail) {
                        cacheInstance = BlurredThumbnailsCache.sharedInstance
                    } else {
                        cacheInstance = ThumbnailsCache.sharedInstance
                    }
                    
                    cacheInstance.get(remoteURL, success: { (url: String!, localThumbnailPath: String!) -> Void in
                        if (currentIdentifier != self.contentIdentifier) {
                            return
                        }

                        let thumbnail: UIImage? = UIImage(contentsOfFile: localThumbnailPath)

                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if (currentIdentifier != self.contentIdentifier) {
                                return
                            }

                            self.thumbnailView.image = thumbnail
                        })
                    }, failure: { (url: String!, flipError: FlipError) -> Void in
                        print("Failed to get resource from cache, error: \(flipError)")
                    })
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if (currentIdentifier != self.contentIdentifier) {
                        return
                    }

                    self.thumbnailView.image = UIImage(named: "Empty_Flip_Thumbnail")
                })
            }
        }

        if (self.loadPlayerOnInit) {
            self.play()
        }
        else {
            self.playButtonView.alpha = BUTTONS_ALPHA
        }
    }
    
    func setupPlayerWithWord(word: String, videoURL: NSURL, thumbnailURL: NSURL?) {
        self.generateRandomIdentifier()
        
        self.words = [word]
        
        let videoAsset: AVURLAsset = AVURLAsset(URL: videoURL, options: nil)
        let flipPlayerItem = playerItemWithVideoAsset(videoAsset)
        flipPlayerItem.order = 0
        self.playerItems = [flipPlayerItem]
        
        if (thumbnailURL != nil) {
            _ = ThumbnailsCache.sharedInstance.get(thumbnailURL!,
                success: { (url: String!, localThumbnailPath: String!) in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.thumbnailView.image = UIImage(contentsOfFile: localThumbnailPath)
                    })
                },
                failure: { (url: String!, error: FlipError) in
                    print("Failed to get resource from cache, error: \(error)")
                })
        }
        
        if (self.loadPlayerOnInit) {
            self.play()
        }
        else {
            self.playButtonView.alpha = BUTTONS_ALPHA
        }
    }

    func playerItemWithVideoAsset(videoAsset: AVAsset) -> FlipPlayerItem {
        let playerItem: FlipPlayerItem = FlipPlayerItem(asset: videoAsset)

        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PlayerView.videoPlayerItemEnded(_:)),
            name:AVPlayerItemDidPlayToEndTimeNotification, object:playerItem)

        return playerItem
    }

    func videoPlayerItemEnded(notification: NSNotification) {
        let currentContentIdentifier = self.contentIdentifier
        
        if let player = self.player() {
            let currentItem = player.currentItem as! FlipPlayerItem
            
            if (self.playerItems.count == 1) {
                player.seekToTime(kCMTimeZero)
                self.onFlipMessagePlaybackFinishedWithCompletion(nil)
                
                if (!self.playInLoop) {
                    self.pause()
                }
            } else {
                let advanceBlock = { () -> Void in
                    if (currentContentIdentifier != self.contentIdentifier) {
                        return
                    }
                    
                    player.advanceToNextItem()
                    
                    let clonedPlayerItem = self.playerItemWithVideoAsset(currentItem.asset)
                    clonedPlayerItem.order = currentItem.order
                    player.insertItem(clonedPlayerItem, afterItem: nil)
                    
                    // Set next item's word
                    let nextWordIndex = (currentItem.order + 1) % self.words!.count
                    self.setWord(self.words![nextWordIndex])
                }
                
                if (currentItem.order == self.playerItems.count - 1) {
                    if (self.playInLoop) {
                        player.pause()
                        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector:#selector(PlayerView.play), userInfo:nil, repeats:false)
                    } else {
                        self.pause()
                    }
                    self.onFlipMessagePlaybackFinishedWithCompletion(advanceBlock)
                } else {
                    advanceBlock()
                }
            }
        }
    }

    func hasPlayer() -> Bool {
        let layer = self.layer as! AVPlayerLayer
        return layer.player != nil
    }

    private func preparePlayer(completion: ((player: AVQueuePlayer?) -> Void)) {
        if let player = self.player() {
            completion(player: player)
            return
        }

        let videoPlayer = AVQueuePlayer(items: self.playerItems)
        videoPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.None
        self.setPlayer(videoPlayer)
        
        completion(player: videoPlayer)
    }
    
    // MARK: - View lifecycle

    private func addSubviews() {
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PlayerView.pauseResume)))

        self.thumbnailView = UIImageView()
        self.thumbnailView.contentMode = UIViewContentMode.ScaleAspectFit
        self.addSubview(self.thumbnailView)

        self.gradientLayer = UIImageView(image: UIImage(named: "Filter_Photo"))
        self.gradientLayer.backgroundColor = UIColor.clearColor()
        self.gradientLayer.frame = self.bounds
        self.addSubview(self.gradientLayer)

        self.wordLabel = UILabel.flipWordLabel()
        self.wordLabel.textAlignment = NSTextAlignment.Center
        self.addSubview(self.wordLabel)
        
        self.playButtonView = UIImageView()
        self.playButtonView.contentMode = UIViewContentMode.Center
        self.playButtonView.image = UIImage(named: "PlayButton")
        self.addSubview(self.playButtonView)

        self.retryLabel = UILabel()
        self.retryLabel.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: BUTTONS_ALPHA)
        self.retryLabel.textColor = UIColor.whiteColor()
        self.retryLabel.font = UIFont.avenirNextRegular(UIFont.HeadingSize.h4)
        self.retryLabel.textAlignment = NSTextAlignment.Center
        self.retryLabel.text = LocalizedString.DOWNLOAD_FAILED_RETRY
        self.retryLabel.sizeToFit()
        self.retryLabel.layer.cornerRadius = self.RETRY_LABEL_CORNER_RADIUS
        self.retryLabel.clipsToBounds = true
        self.addSubview(self.retryLabel)

        self.progressBarView = ProgressBar()
        self.addSubview(self.progressBarView)

        self.initialViewState()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = self.layer.bounds
    }

    private func makeConstraints() {
        self.wordLabel.mas_makeConstraints { (make) -> Void in
            make.width.equalTo()(self)
            make.bottom.equalTo()(self).with().offset()(FLIP_WORD_LABEL_MARGIN_BOTTOM)
            make.centerX.equalTo()(self)
        }

        self.thumbnailView.mas_makeConstraints({ (make) -> Void in
            make.width.equalTo()(self)
            make.height.equalTo()(self)
            make.center.equalTo()(self)
        })
        
        self.playButtonView.mas_makeConstraints({ (make) -> Void in
            make.width.equalTo()(self.thumbnailView)
            make.height.equalTo()(self.thumbnailView)
            make.center.equalTo()(self.thumbnailView)
        })

        self.retryLabel.mas_makeConstraints({ (make) -> Void in
            make.center.equalTo()(self.thumbnailView)
            make.width.equalTo()(self.retryLabel.frame.width + (self.RETRY_LABEL_PADDING * 2))
            make.height.equalTo()(self.retryLabel.frame.height + (self.RETRY_LABEL_PADDING * 2))
            return
        })

        self.progressBarView.mas_makeConstraints({ (make) -> Void in
            make.center.equalTo()(self.thumbnailView)
            make.width.equalTo()(self.thumbnailView.mas_height).with().offset()(-(self.PROGRESS_BAR_PADDING * 2))
            make.height.equalTo()(self.PROGRESS_BAR_HEIGHT)
        })
    }

    func releaseResources() {
        self.contentIdentifier = nil
        
        NSNotificationCenter.defaultCenter().removeObserver(self)

        self.loadingFlips = false
        self.thumbnailView.image = nil
        self.wordLabel.text = ""
        self.flips = nil
        self.playerItems = [FlipPlayerItem]()
        self.words = []
        self.isPlaying = false
        
        self.initialViewState()

        self.flipsDownloadProgress.removeAll()

        if let player = self.player() {
            SwiftTryCatch.`try`({ () -> Void in
                player.removeObserver(self, forKeyPath: "status")
            }, catch: { (exception: NSException!) -> Void in
                return // Do nothing
            }, finally: { () -> Void in
                return
            })
            
            player.removeAllItems()
        }

        let layer = self.layer as! AVPlayerLayer
        layer.player = nil
    }

}


// MARK: - PlayerViewDelegate Protocol

protocol PlayerViewDelegate: class {
    
    func playerViewDidFinishPlayback(playerView: PlayerView)
    func playerViewIsVisible(playerView: PlayerView) -> Bool
    func playerViewShouldShowPlayButtonOnInitialState(playerView: PlayerView) -> Bool
    
}
