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

class PreviewViewController : MugChatViewController, PreviewViewDelegate {
    
    private var previewView: PreviewView!
    private var words: [MugText]!
    
    convenience init(words: [MugText]) {
        self.init()
        self.words = words
    }
    
    override func loadView() {
        self.previewView = PreviewView()
        self.previewView.delegate = self
        self.view = previewView
    }
    
    
    // MARK: - Overridden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        self.setupWhiteNavBarWithBackButton(NSLocalizedString("Preview", comment: "Preview"))
        
        self.setNeedsStatusBarAppearanceUpdate()
        
        self.previewView.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.previewView.viewDidAppear()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.previewView.viewWillDisappear()
    }
    
    // MARK: - ComposeViewDelegate Methods
    
    func previewViewDidTapBackButton(previewView: PreviewView!) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func previewButtonDidTapSendButton(previewView: PreviewView!) {
        self.previewView.stopMovie()
        self.showActivityIndicator()
        
        let delayBetweenExecutions = 2.0 * Double(NSEC_PER_SEC)
        let oneSecond = dispatch_time(DISPATCH_TIME_NOW, Int64(delayBetweenExecutions))
        dispatch_after(oneSecond, dispatch_get_main_queue()) { () -> Void in
            self.hideActivityIndicator()
            self.navigationController?.popViewControllerAnimated(true)
        }

    }
    
    func previewViewMakeConstraintToNavigationBarBottom(container: UIView!) {
        // using Mansory strategy
        // check here: https://github.com/Masonry/Masonry/issues/27
        container.mas_makeConstraints { (make) -> Void in
            var topLayoutGuide: UIView = self.topLayoutGuide as AnyObject! as UIView
            make.top.equalTo()(topLayoutGuide.mas_bottom)
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.BlackOpaque
    }

}