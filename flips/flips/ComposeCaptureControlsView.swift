//
//  ComposeOptionsView.swift
//  flips
//
//  Created by Taylor Bell on 8/22/15.
//
//

class ComposeCaptureControlsView : UIView, UIScrollViewDelegate, FlipSelectionViewDelegate {
    
    private let SCROLL_DELAY = dispatch_time(DISPATCH_TIME_NOW, Int64(0.75) * Int64(NSEC_PER_SEC))
    
    weak var delegate : CaptureControlsViewDelegate?
    weak var dataSource : FlipSelectionViewDataSource? {
        set {
            flipsView.dataSource = newValue
        }
        get {
            return flipsView.dataSource!
        }
    }
    
    // Video Recording Timer
    private var videoTimer : NSTimer!
    
    // UI
    private var optionsScrollView : UIScrollView!
    
    private var overflowCameraView : UIView!
    private var overflowGalleryView : UIView!
    private var flipsView : FlipsSelectionView!
    private var videoView : UIView!
    private var cameraView : UIView!
    private var galleryView : UIView!
    
    
    
    ////
    // MARK: - Init
    ////
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: CGRectZero)
        self.initSubviews()
        self.initConstraints()
    }
    
    
    
    ////
    // MARK: - Subview Initialization
    ////
    
    private func initSubviews() {
        
        // Shared Button Image
        
        var captureImage = UIImage(named: "Capture")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        // Video Button Long Press Recognizer
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("handleVideoButtonPress:"))
        longPressRecognizer.minimumPressDuration = 0.1
        
        // Flips Views
        
        flipsView = FlipsSelectionView()
        flipsView.delegate = self
        
        // Button Containers
        
        videoView = buttonView(image: captureImage, tintColor: UIColor.orangeColor(), gestureRecognizer: longPressRecognizer)
        cameraView = buttonView(image: captureImage, tintColor: UIColor.blueColor(), tapSelector: Selector("handleCameraButtonTap:"))
        overflowCameraView = buttonView(image: captureImage, tintColor: UIColor.blueColor(), tapSelector: Selector("handleCameraButtonTap:"))
        galleryView = buttonView(image: captureImage, tintColor: UIColor.greenColor(), tapSelector: Selector("handleGalleryButtonTap:"))
        overflowGalleryView = buttonView(image: captureImage, tintColor: UIColor.greenColor(), tapSelector: Selector("handleGalleryButtonTap:"))
        
        disableCameraControls()
        
        // ScrollView
        
        optionsScrollView = UIScrollView()
        optionsScrollView.pagingEnabled = true
        optionsScrollView.backgroundColor = UIColor.sand()
        optionsScrollView.delegate = self;
        optionsScrollView.showsHorizontalScrollIndicator = false
        optionsScrollView.showsVerticalScrollIndicator = false
        
        optionsScrollView.addSubview(overflowCameraView)
        optionsScrollView.addSubview(galleryView)
        optionsScrollView.addSubview(flipsView)
        optionsScrollView.addSubview(videoView)
        optionsScrollView.addSubview(cameraView)
        optionsScrollView.addSubview(overflowGalleryView)
        
        addSubview(optionsScrollView)
        
    }
    
    private func initConstraints() {
        
        self.optionsScrollView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self)
            make.top.equalTo()(self)
            make.height.equalTo()(self)
            make.width.equalTo()(self)
        }
        
        overflowCameraView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.optionsScrollView)
            make.top.equalTo()(self.optionsScrollView)
            make.height.equalTo()(self.optionsScrollView)
            make.width.equalTo()(self.optionsScrollView)
        }
        
        galleryView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.optionsScrollView)
            make.top.equalTo()(self.overflowCameraView.mas_bottom)
            make.height.equalTo()(self.optionsScrollView)
            make.width.equalTo()(self.optionsScrollView)
        }
        
        flipsView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.optionsScrollView)
            make.top.equalTo()(self.galleryView.mas_bottom)
            make.height.equalTo()(self.optionsScrollView)
            make.width.equalTo()(self.optionsScrollView)
        }
        
        videoView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.optionsScrollView)
            make.top.equalTo()(self.flipsView.mas_bottom)
            make.height.equalTo()(self.optionsScrollView)
            make.width.equalTo()(self.optionsScrollView)
        }
        
        cameraView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.optionsScrollView)
            make.top.equalTo()(self.videoView.mas_bottom)
            make.height.equalTo()(self.optionsScrollView)
            make.width.equalTo()(self.optionsScrollView)
        }
       
        overflowGalleryView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.optionsScrollView)
            make.top.equalTo()(self.cameraView.mas_bottom)
            make.height.equalTo()(self.optionsScrollView)
            make.width.equalTo()(self.optionsScrollView)
        }
        
    }
    
    
    
    ////
    // MARK: - Lifecycle
    ////
    
    override func layoutSubviews() {
        super.layoutSubviews()
        optionsScrollView.contentSize = CGSizeMake(optionsScrollView.frame.width, optionsScrollView.frame.height * 6)
        scrollToFlipsView(false)
    }
    
    
    
    ////
    // MARK: - Button Setup
    ////
    
    func buttonView(image: UIImage? = nil, tintColor: UIColor? = nil, gestureRecognizer: UIGestureRecognizer? = nil, tapSelector: Selector? = nil) -> (UIView) {
        
        let button = UIButton()
        
        if let buttonImage = image {
            button.setImage(buttonImage, forState: .Normal)
            button.sizeToFit()
        }
        
        if let buttonColor = tintColor {
            button.tintColor = tintColor
        }
        
        if let gestureRec = gestureRecognizer {
            button.addGestureRecognizer(gestureRec)
        }
        
        if let tapAction = tapSelector {
            button.addTarget(self, action: tapAction, forControlEvents: UIControlEvents.TouchUpInside)
        }
        
        let buttonContainer = UIView()
        buttonContainer.addSubview(button)
        
        button.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(buttonContainer)
            make.centerY.equalTo()(buttonContainer)
            make.height.equalTo()(button.frame.height)
            make.width.equalTo()(button.frame.width)
        }
        
        return buttonContainer
        
    }
    
    
    
    ////
    // MARK: - UIScrollViewDelegate
    ////
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let currentPage = scrollView.contentOffset.y / scrollView.frame.height
        
        switch currentPage
        {
            case 0:
                scrollToPhotoButton(false)
            case 5:
                scrollToGalleryButton(false)
            default:
                break;
        }
        
    }
    
    
    
    ////
    // MARK: - Camera Controls
    ////
    
    func enableCameraControls() {
        self.cameraView.userInteractionEnabled = true
        self.videoView.userInteractionEnabled = true
    }
    
    func disableCameraControls() {
        self.cameraView.userInteractionEnabled = false
        self.videoView.userInteractionEnabled = false
    }
    
    
    
    ////
    // MARK: - Scrolling
    ////
    
    func scrollToFlipsView(animated: Bool) {
        
        if animated
        {
            dispatch_after(SCROLL_DELAY, dispatch_get_main_queue()) { () -> Void in
                self.optionsScrollView.setContentOffset(CGPointMake(0, self.optionsScrollView.frame.height * 2), animated: true)
            }
        }
        else
        {
            optionsScrollView.setContentOffset(CGPointMake(0, self.optionsScrollView.frame.height * 2), animated: false)
        }
        
    }
    
    func scrollToVideoButton(animated: Bool) {
        
        if animated
        {
            dispatch_after(SCROLL_DELAY, dispatch_get_main_queue()) { () -> Void in
                self.optionsScrollView.setContentOffset(CGPointMake(0, self.optionsScrollView.frame.height * 3), animated: true)
            }
        }
        else
        {
            optionsScrollView.setContentOffset(CGPointMake(0, self.optionsScrollView.frame.height * 3), animated: false)
        }
        
    }
    
    func scrollToPhotoButton(animated: Bool) {
        
        if animated
        {
            dispatch_after(SCROLL_DELAY, dispatch_get_main_queue()) { () -> Void in
                self.optionsScrollView.setContentOffset(CGPointMake(0, self.optionsScrollView.frame.height * 4), animated: true)
            }
        }
        else
        {
            optionsScrollView.setContentOffset(CGPointMake(0, self.optionsScrollView.frame.height * 4), animated: false)
        }
        
    }
    
    func scrollToGalleryButton(animated: Bool) {
        
        if animated
        {
            dispatch_after(SCROLL_DELAY, dispatch_get_main_queue()) { () -> Void in
                self.optionsScrollView.setContentOffset(CGPointMake(0, self.optionsScrollView.frame.height), animated: true)
            }
        }
        else
        {
            optionsScrollView.setContentOffset(CGPointMake(0, self.optionsScrollView.frame.height), animated: false)
        }
        
    }
    
    
    
    ////
    // MARK: - FlipsView
    ////
    
    func reloadFlipsView() {
        flipsView.reloadData()
    }
   
    func showUserFlips(animated: Bool) {
        
        if animated {
            flipsView.showUserFlipsViewAnimated()
        }
        else {
            flipsView.showUserFlipsView()
        }
        
    }
    
    func dismissUserFlips(animated: Bool) {
        
        if animated {
            flipsView.dismissUserFlipsViewAnimated()
        }
        else {
            flipsView.dismissUserFlipsView()
        }
        
    }
    
    func showStockFlips(animated: Bool) {
        
        if animated {
            flipsView.showStockFlipsViewAnimated()
        }
        else {
            flipsView.showStockFlipsView()
        }
        
    }
    
    func dismissStockFlips(animated: Bool) {
        
        if animated {
            flipsView.dismissStockFlipsViewAnimated()
        }
        else {
            flipsView.dismissStockFlipsView()
        }
        
    }
    
    
    
    ////
    // MARK: - Gallery Button
    ////
    
    func handleGalleryButtonTap(sender: UIButton) {
        self.delegate?.didTapGalleryButton()
    }
    
    
    
    ////
    // MARK: - Camera Button
    ////
    
    func handleCameraButtonTap(sender: UIButton) {
        self.delegate?.didTapCapturePhotoButton()
    }
    
    
    
    ////
    // MARK: - Video Timer & Button
    ////
    
    func handleVideoButtonPress(gestureRecognizer: UILongPressGestureRecognizer) {
        
        switch(gestureRecognizer.state) {
            case .Began:
                self.delegate?.didPressVideoButton()
                startVideoTimer()
                break;
            case .Ended:
                if let timer = self.videoTimer {
                    clearVideoTimer()
                    self.delegate?.didReleaseVideoButton()
                }
                break;
            default:
                break;
        }
        
    }
    
    
    
    ////
    // MARK: - Video Timer
    ////
    
    func startVideoTimer() {
        videoTimer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: Selector("handleVideoTimerExpired"), userInfo: nil, repeats: false)
    }
    
    func clearVideoTimer() {
        videoTimer.invalidate()
        videoTimer = nil
    }
    
    func handleVideoTimerExpired() {
        
        if let timer = self.videoTimer {
            clearVideoTimer()
            delegate?.didReleaseVideoButton()
        }
        
    }
    
    
    
    ////
    // MARK: - FlipSelectionViewDelegate
    ////
    
    func didOpenUserFlipsView() {
        delegate?.captureControlsDidShowUserFlips()
    }
    
    func didDismissUserFlipsView() {
        delegate?.captureControlsDidDismissUserFlips()
    }
    
    func didSelectUserFlipAtIndex(index: Int) {
        delegate?.didSelectFlipAtIndex(index)
    }
    
    func didOpenStockFlipsView() {
        delegate?.captureControlsDidShowStockFlips()
    }
    
    func didDismissStockFlipsView() {
        delegate?.captureControlsDidDismissStockFlips()
    }
    
    func didSelectStockFlipAtIndex(index: Int) {
        delegate?.didSelectStockFlipAtIndex(index)
    }
    
    
}

protocol CaptureControlsViewDelegate : class {
    
    func captureControlsDidShowUserFlips()
    
    func captureControlsDidDismissUserFlips()
    
    func captureControlsDidShowStockFlips()
    
    func captureControlsDidDismissStockFlips()
    
    func didSelectStockFlipAtIndex(index: Int)
    
    func didSelectFlipAtIndex(index: Int)
    
    func didPressVideoButton()
    
    func didReleaseVideoButton()
    
    func didTapCapturePhotoButton()
    
    func didTapGalleryButton()
    
}