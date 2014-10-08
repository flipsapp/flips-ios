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

import AVFoundation

class TakePictureViewController : MugChatViewController, TakePictureViewDelegate, ConfirmPictureViewDelegate {
    
    private var takePictureView: TakePictureView!
    private var confirmPictureView: ConfirmPictureView!
    
    private var picture: UIImage!
    
    var delegate: TakePictureViewControllerDelegate?
    
    // MARK: - Overriden Methods
    
    override func loadView() {
        takePictureView = TakePictureView(interfaceOrientation: AVCaptureVideoOrientation.Portrait)
        takePictureView.delegate = self
        self.view = takePictureView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        confirmPictureView = ConfirmPictureView()
        confirmPictureView.alpha = 0
        confirmPictureView.delegate = self
        self.view.addSubview(confirmPictureView)
        
        confirmPictureView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.view)
            make.bottom.equalTo()(self.view)
            make.leading.equalTo()(self.view)
            make.trailing.equalTo()(self.view)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        takePictureView.registerObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        takePictureView.removeObservers()
    }
    
    override func shouldAutorotate() -> Bool {
        return takePictureView.shouldAutorotate()
    }
    
    
    // MARK: - TakePictureViewDelegate
    
    func takePictureViewDidTapBackButton(takePictureView: TakePictureView) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func takePictureView(takePictureView: TakePictureView, didTakePicture picture: UIImage) {
        self.picture = picture
        confirmPictureView.setPicture(picture)
        self.showConfirmPictureView()
    }
    
    
    // MARK: - Confirm Picture Methods
    
    func showConfirmPictureView() {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.confirmPictureView.alpha = 1
        })
    }
    
    func hideConfirmPictureView() {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.confirmPictureView.alpha = 0
        })
    }
    
    // MARK: - ConfirmPictureViewDelegate
    
    func confirmPictureViewDidTapBackButton(confirmPictureView: ConfirmPictureView) {
        self.hideConfirmPictureView()
    }

    func confirmPictureViewDidApprovePicture(confirmPictureView: ConfirmPictureView) {
        delegate?.takePictureViewController(self, didFinishWithPicture: self.picture)
    }
}
