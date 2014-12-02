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

class VerificationCodeViewController: FlipsViewController, VerificationCodeViewDelegate {
    
    private let PLATFORM = "ios"
    private let US_CODE = "+1"
    let VERIFICATION_CODE_DID_NOT_MATCH = "Wrong validation code."
    
    var verificationCodeView: VerificationCodeView!
    var phoneNumber: String!
    var userId: String!
    var verificationCode: String = "XXXX"
    
    init(phoneNumber: String!, userId: String!) {
        super.init(nibName: nil, bundle: nil)
        self.phoneNumber = phoneNumber
        self.userId = userId
        
        let trimmedPhoneNumber = phoneNumber.stringByReplacingOccurrencesOfString("-", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        let intlPhoneNumber = "\(US_CODE)\(trimmedPhoneNumber)"
        let token = DeviceHelper.sharedInstance.retrieveDeviceToken()?
        
        createDeviceForUser(userId, phoneNumber: intlPhoneNumber, platform: PLATFORM, token: token)
    }
    
    override func loadView() {
        super.loadView()
        verificationCodeView = VerificationCodeView(phoneNumber: phoneNumber)
        verificationCodeView.delegate = self
        self.view = verificationCodeView
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        verificationCodeView.viewWillAppear()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        verificationCodeView.viewWillDisappear()
    }
    
    func navigateAfterValidateDevice() {
        var inboxViewController = InboxViewController()
        self.navigationController?.pushViewController(inboxViewController, animated: true)
    }
    
    // MARK: - VerificationCodeViewDelegate Methods
    
    func verificationCodeView(verificatioCodeView: VerificationCodeView!, didFinishTypingVerificationCode verificationCode: String!) {
        self.verifyDevice(userId, deviceId: DeviceHelper.sharedInstance.retrieveDeviceId()!, verificationCode: verificationCode)
    }
    
    func verificationCodeViewDidTapBackButton(verificatioCodeView: VerificationCodeView!) {
        self.navigationController?.popViewControllerAnimated(true)
        verificatioCodeView.resetVerificationCodeField()
    }
    
    func verificationCodeViewDidTapResendButton(view: VerificationCodeView!) {
        view.resetVerificationCodeField()
        view.focusKeyboardOnCodeField()
        self.resendVerificationCode(userId, deviceId: DeviceHelper.sharedInstance.retrieveDeviceId()!)
    }
    
    
    // MARK: - Backend Services Integration
    
    private func createDeviceForUser(userId: String, phoneNumber: String, platform: String, token: String?) {
        DeviceService.sharedInstance.createDevice(userId,
            phoneNumber: phoneNumber,
            platform: platform,
            uuid: token,
            success: { (device) in
                if (device == nil) {
                    println("Error: Device was not created")
                    return ()
                }
                DeviceHelper.sharedInstance.saveDeviceId(device!.deviceID)
            },
            failure: { (flipError) in
                println("Error trying to register device: " + flipError!.error!)
        })
    }
    
    private func resendVerificationCode(userId: String, deviceId: String) {
        DeviceService.sharedInstance.resendVerificationCode(userId,
            deviceId: deviceId,
            success: { (device) in
                if (device == nil) {
                    println("Error: Verification Code was not resent")
                    return ()
                }
                let verificationCodeView = self.view as VerificationCodeView
                verificationCodeView.resetVerificationCodeField()
                verificationCodeView.focusKeyboardOnCodeField()
            },
            failure: { (flipError) in
                println("Error trying to resend verification code to device: " + flipError!.error!)
            })
    }
    
    private func verifyDevice(userId: String, deviceId: String, verificationCode: String) {
        ActivityIndicatorHelper.showActivityIndicatorAtView(self.view)
        DeviceService.sharedInstance.verifyDevice(userId,
            deviceId: deviceId,
            verificationCode: verificationCode,
            phoneNumber: self.phoneNumber,
            success: { (device) in
                if (device == nil) {
                    println("Error verifying device")
                    return ()
                }
                var deviceEntity = device as Device
                var user = deviceEntity.user
                user.me = true
                UserDataSource().save()
                
                AuthenticationHelper.sharedInstance.userInSession = user
                
                var userDataSource = UserDataSource()
                userDataSource.syncUserData({ (success, error) -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let verificationCodeView = self.view as VerificationCodeView
                        verificationCodeView.resetVerificationCodeField()
                        
                        ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                        self.navigateAfterValidateDevice()
                    })
                })
            },
            failure: { (flipError) in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                    if (flipError!.error == self.VERIFICATION_CODE_DID_NOT_MATCH) {
                        let verificationCodeView = self.view as VerificationCodeView
                        verificationCodeView.didEnterWrongVerificationCode()
                    } else {
                        println("Device code verification error: " + flipError!.error!)
                        let verificationCodeView = self.view as VerificationCodeView
                        verificationCodeView.resetVerificationCodeField()
                        verificationCodeView.focusKeyboardOnCodeField()
                    }
                })
            })
    }
    
    
    // MARK: - Required methods
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
}
