//
// Copyright 2014 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

class ChatView: UIView, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, JoinStringsTextFieldDelegate,ChatTableViewCellDelegate {
    
    private let CELL_IDENTIFIER = "flipChatCell"
    private let REPLY_VIEW_OFFSET : CGFloat = 18.0
    private let REPLY_BUTTON_HEIGHT : CGFloat = 64.0
    private let REPLY_VIEW_MARGIN : CGFloat = 10.0
    private let TEXT_VIEW_MARGIN : CGFloat = 3.0
    private let HORIZONTAL_RULER_HEIGHT : CGFloat = 1.0
    private let AUTOPLAY_ON_LOAD_DELAY : Double = 0.3
    
    private let CELL_FLIP_AREA_HEIGHT: CGFloat = UIScreen.mainScreen().bounds.width
    private let CELL_FLIP_AREA_HEIGHT_IPHONE_4S : CGFloat = 240.0
    private let CELL_FLIP_TEXT_AREA_HEIGHT: CGFloat = 62
    
    private let THUMBNAIL_FADE_DURATION: NSTimeInterval = 0.2
    
    private let ONBOARDING_BUBBLE_TITLE = NSLocalizedString("Pretty cool, huh?", comment: "Pretty cool, huh?")
    private let ONBOARDING_BUBBLE_MESSAGE = NSLocalizedString("Now it's your turn.", comment: "Now it's your turn.")
    
    private var tableView: UITableView!
    private var darkHorizontalRulerView: UIView!
    private var replyView: UIView!
    private var replyButton: UIButton!
    private var replyTextField: JoinStringsTextField!
    private var nextButton: NextButton!
    
    private var shouldPlayUnreadMessage: Bool = true
    private var keyboardHeight: CGFloat = 0.0
    
    var delegate: ChatViewDelegate?
    var dataSource : ChatViewDataSource?
    
    private var showOnboarding = false
    private var bubbleView: BubbleView!
    
    
    // MARK: - Required initializers
    
    init(showOnboarding: Bool) {
        super.init(frame: CGRect.zeroRect)
        
        self.showOnboarding = showOnboarding
        self.addSubviews()
        self.makeConstraints()
        
        self.updateNextButtonState()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Layout
    
    func addSubviews() {
        tableView = UITableView(frame: self.frame, style: .Plain)
        tableView.backgroundColor = UIColor.whiteColor()
        tableView.registerClass(ChatTableViewCell.self, forCellReuseIdentifier: CELL_IDENTIFIER)
        tableView.separatorStyle = .None
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        tableView.contentOffset = CGPointMake(0, 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        self.addSubview(tableView)
        
        darkHorizontalRulerView = UIView()
        darkHorizontalRulerView.backgroundColor = UIColor.grayColor()
        self.addSubview(darkHorizontalRulerView)
        
        replyView = UIView()
        replyView.backgroundColor = UIColor.whiteColor()
        self.addSubview(replyView)
        
        replyButton = UIButton()
        replyButton.contentMode = .Center
        replyButton.backgroundColor = UIColor.whiteColor()
        replyButton.contentEdgeInsets = UIEdgeInsetsMake(REPLY_VIEW_OFFSET / 2, REPLY_VIEW_OFFSET * 2, REPLY_VIEW_OFFSET / 2, REPLY_VIEW_OFFSET * 2)
        replyButton.addTarget(self, action: "didTapReplyButton", forControlEvents: UIControlEvents.TouchUpInside)
        replyButton.setImage(UIImage(named: "Reply"), forState: UIControlState.Normal)
        replyButton.sizeToFit()
        replyView.addSubview(replyButton)
        
        replyTextField = JoinStringsTextField()
        replyTextField.joinStringsTextFieldDelegate = self
        replyTextField.hidden = true
        replyTextField.font = UIFont.avenirNextRegular(UIFont.HeadingSize.h4)
        replyView.addSubview(replyTextField)
        
        nextButton = NextButton()
        nextButton.contentEdgeInsets = UIEdgeInsetsMake(REPLY_VIEW_OFFSET, REPLY_VIEW_OFFSET, REPLY_VIEW_OFFSET, REPLY_VIEW_OFFSET)
        nextButton.hidden = true
        nextButton.addTarget(self, action: "didTapNextButton", forControlEvents: UIControlEvents.TouchUpInside)
        nextButton.sizeToFit()
        replyView.addSubview(nextButton)
        
        if (showOnboarding) {
            bubbleView = BubbleView(title: ONBOARDING_BUBBLE_TITLE, message: ONBOARDING_BUBBLE_MESSAGE, bubbleType: BubbleType.arrowDownFirstLineBold)
            self.addSubview(bubbleView)
        } 
    }
    
    func makeConstraints() {
        
        tableView.mas_makeConstraints( { (make) in
            make.top.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.bottom.equalTo()(self.darkHorizontalRulerView.mas_top)
        })
        
        darkHorizontalRulerView.mas_makeConstraints( { (make) in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.HORIZONTAL_RULER_HEIGHT)
            make.bottom.equalTo()(self.replyView.mas_top)
        })
        
        replyView.mas_makeConstraints( { (make) in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.REPLY_BUTTON_HEIGHT)
            make.bottom.equalTo()(self)
        })
        
        replyButton.mas_makeConstraints( { (make) in
            make.center.equalTo()(self.replyView)
            return ()
        })
        
        replyTextField.mas_makeConstraints( { (make) in
            make.left.equalTo()(self.replyView).with().offset()(self.REPLY_VIEW_OFFSET)
            make.right.equalTo()(self.nextButton.mas_left).with().offset()(-self.REPLY_VIEW_OFFSET)
            make.centerY.equalTo()(self.replyView)
            make.height.equalTo()(self.getReplyTextHeight())
        })
        
        nextButton.mas_makeConstraints( { (make) in
            make.right.equalTo()(self.replyView)
            make.top.equalTo()(self.replyView)
            make.bottom.equalTo()(self.replyView)
            make.width.equalTo()(self.nextButton.frame.width)
        })
        
        if (showOnboarding) {
            bubbleView.mas_makeConstraints({ (make) -> Void in
                make.bottom.equalTo()(self.tableView.mas_bottom)
                make.width.equalTo()(self.bubbleView.getWidth())
                make.height.equalTo()(self.bubbleView.getHeight())
                make.centerX.equalTo()(self)
            })
        }
    }
    
    
    func getReplyTextHeight() -> CGFloat{
        let myString: NSString = self.replyTextField.text as NSString
        var font: UIFont = UIFont.avenirNextRegular(UIFont.HeadingSize.h4)
        let size: CGSize = myString.sizeWithAttributes([NSFontAttributeName: font])
        return size.height * 2 - self.TEXT_VIEW_MARGIN
    }
    
    
    // MARK: - CustomNavigationBarDelegate
    
    func customNavigationBarDidTapLeftButton(navBar : CustomNavigationBar) {
        delegate?.chatViewDidTapBackButton(self)
    }
    
    
    // MARK: - Data Load Methods
    
    func reloadFlipMessages() {
        self.tableView.reloadData()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            let flipMessagaDataSource = FlipMessageDataSource()
            if let numberOfMessages = self.dataSource?.numberOfFlipMessages(self) as Int? {
                var firstNotReadMessageIndex = numberOfMessages - 1
                for (var i = 0; i < numberOfMessages; i++) {
                    let flipMessageId = self.dataSource?.chatView(self, flipMessageIdAtIndex: i)
                    if (flipMessageId != nil) {
                        var flipMessage = flipMessagaDataSource.retrieveFlipMessageById(flipMessageId!)
                        if (flipMessage.notRead.boolValue) {
                            firstNotReadMessageIndex = i
                            break
                        }
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: firstNotReadMessageIndex, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(self.AUTOPLAY_ON_LOAD_DELAY * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), { () -> Void in
                        self.playVideoForVisibleCell()
                    })
                })
            }
        })
    }
    
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as ChatTableViewCell
        
        if cell.isPlayingFlip() {
            cell.stopMovie()
        }
        
        let flipMessageId = dataSource?.chatView(self, flipMessageIdAtIndex: indexPath.row)
        if (flipMessageId != nil) {
            cell.setFlipMessageId(flipMessageId!)
        }
        
        return cell;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfMessages = dataSource?.numberOfFlipMessages(self) as Int?
        if (numberOfMessages == nil) {
            numberOfMessages = 0
        }
        
        return numberOfMessages!
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var cellHeightForRowAtIndexPath : CGFloat
        if (DeviceHelper.sharedInstance.isDeviceModelLessOrEqualThaniPhone4S()) {
            cellHeightForRowAtIndexPath = CELL_FLIP_AREA_HEIGHT_IPHONE_4S + CELL_FLIP_TEXT_AREA_HEIGHT
        } else {
            cellHeightForRowAtIndexPath = CELL_FLIP_AREA_HEIGHT + CELL_FLIP_TEXT_AREA_HEIGHT
        }
        return cellHeightForRowAtIndexPath

    }
    
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let visibleCells = self.tableView.visibleCells()

        for cell : ChatTableViewCell in visibleCells as [ChatTableViewCell] {
            if !self.isCell(cell, totallyVisibleOnView: self) {
                if cell.isPlayingFlip() {
                    cell.stopMovie()
                }
            }
        }
    }
    
    private func isCell(cell: ChatTableViewCell, totallyVisibleOnView view: UIView) -> Bool {
        var videoContainerView = cell.subviews[0].subviews[0].subviews[0] as UIView // Gets video container view from cell
        var convertedVideoContainerViewFrame = cell.convertRect(videoContainerView.frame, toView:view)
        if (CGRectContainsRect(view.frame, convertedVideoContainerViewFrame)) {
            return true
        } else {
            return false
        }
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if (!decelerate) {
                self.playVideoForVisibleCell()
            }
        })
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.playVideoForVisibleCell()
        })
    }

    private func playVideoForVisibleCell() {
        let visibleCells = self.tableView.visibleCells()
        for cell : ChatTableViewCell in visibleCells as [ChatTableViewCell] {
            if (self.isCell(cell, totallyVisibleOnView: self)) {
                var indexPath = self.tableView.indexPathForCell(cell) as NSIndexPath?
                if (indexPath == nil) {
                    return
                }
                var row = indexPath?.row
                var shouldAutoPlay: Bool? = dataSource?.chatView(self, shouldAutoPlayFlipMessageAtIndex: row!)
                if (shouldAutoPlay != nil) {
                    cell.playMovie()
                }
            } else {
                cell.stopMovie()
            }
        }
    }

    
    // MARK: - Button Handlers
    
    func didTapReplyButton() {
        hideReplyButtonAndShowTextField()
        
        let visibleCells = tableView.visibleCells()
        for cell : ChatTableViewCell in visibleCells as [ChatTableViewCell] {
            cell.stopMovie()
        }
        
        self.replyTextField.becomeFirstResponder()
    }
    
    func didTapNextButton() {
        self.delegate?.chatView(self, didTapNextButtonWithWords: replyTextField.getFlipTexts())
    }
    
    private func hideReplyButtonAndShowTextField() {
        self.replyButton.hidden = true
        self.replyTextField.hidden = false
        self.nextButton.hidden = false
        
        replyView.mas_updateConstraints( { (make) in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.getReplyTextHeight() + self.REPLY_VIEW_MARGIN)
            make.bottom.equalTo()(self)
        })
        self.updateConstraints()
        
        
    }
    
    private func hideTextFieldAndShowReplyButton() {
        self.replyButton.hidden = false
        self.replyTextField.hidden = true
        self.nextButton.hidden = true
    }
    
    func clearReplyTextField() {
        self.replyTextField.text = ""
    }
    
    
    // MARK: - Notifications
    
    func keyboardDidShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        keyboardHeight = keyboardFrame.height as CGFloat
        
        var numberOfMessages = dataSource?.numberOfFlipMessages(self) as Int?
        if (numberOfMessages == nil) {
            numberOfMessages = 0
        }
        
        if (numberOfMessages > 0) {
            let indexPath = NSIndexPath(forRow: numberOfMessages! - 1, inSection: 0)
            
            replyView.mas_updateConstraints( { (make) in
                make.left.equalTo()(self)
                make.right.equalTo()(self)
                make.height.equalTo()(self.getReplyTextHeight() + self.REPLY_VIEW_MARGIN)
                make.bottom.equalTo()(self).with().offset()(-self.keyboardHeight)
            })
            self.updateConstraints()
            self.layoutIfNeeded()
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
    }
    
    
    // MARK: - View Events
    
    func viewWillAppear() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        
        replyView.mas_updateConstraints( { (make) in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.getReplyTextHeight() + self.REPLY_VIEW_MARGIN)
            make.bottom.equalTo()(self)
        })
        self.updateConstraints()
        
        self.replyTextField.viewWillAppear()
    }
    
    func viewWillDisappear() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        PlayerView.videoSerialOperationQueue.cancelAllOperations()
        
        let visibleCells = tableView.visibleCells()
        for cell : ChatTableViewCell in visibleCells as [ChatTableViewCell] {
            cell.stopMovie()
            cell.releaseResources()
        }
    }
    
    
    // MARK: JoinStringsTextFieldDelegate delegate
    
    func joinStringsTextFieldNeedsToHaveItsHeightUpdated(joinStringsTextField: JoinStringsTextField!) {
        replyView.mas_updateConstraints( { (make) in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.getReplyTextHeight() + self.REPLY_VIEW_MARGIN)
            make.bottom.equalTo()(self).with().offset()(-self.keyboardHeight)
        })
        
        replyTextField.mas_updateConstraints( { (make) in
            make.left.equalTo()(self.replyView).with().offset()(self.REPLY_VIEW_OFFSET)
            make.right.equalTo()(self.nextButton.mas_left).with().offset()(-self.REPLY_VIEW_OFFSET)
            make.centerY.equalTo()(self.replyView)
            make.height.equalTo()(self.getReplyTextHeight())
        })
        self.updateConstraints()
    }
    
    func joinStringsTextField(joinStringsTextField: JoinStringsTextField, didChangeText: String!) {
        updateNextButtonState()
    }
    
    // MARK: - ChatTableViewCellDelegate
    
    func chatTableViewCellIsVisible(chatTableViewCell: ChatTableViewCell) -> Bool {
        let visibleCells = tableView.visibleCells()
        for cell : ChatTableViewCell in visibleCells as [ChatTableViewCell] {
            if (cell == chatTableViewCell) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Private methods
    
    private func updateNextButtonState() {
        nextButton.enabled = !replyTextField.text.removeWhiteSpaces().isEmpty
    }
}

@objc protocol ChatViewDelegate {
    
    func chatViewDidTapBackButton(chatView: ChatView)
    
    func chatView(chatView: ChatView, didTapNextButtonWithWords words: [String])
    
    optional func chatViewReloadMessages(chatView: ChatView)
    
    optional func chatView(chatView: ChatView, didDeleteItemAtIndex index: Int)
    
}

protocol ChatViewDataSource {
    
    func numberOfFlipMessages(chatView: ChatView) -> Int
    
    func chatView(chatView: ChatView, flipMessageIdAtIndex index: Int) -> String
    
    func chatView(chatView: ChatView, shouldAutoPlayFlipMessageAtIndex index: Int) -> Bool
    
}
