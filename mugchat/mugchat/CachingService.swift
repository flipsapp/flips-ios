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

import UIKit

public class CachingService: NSObject {

    private var cacheHandler : CacheHandler!
    private var downloader : Downloader!

    public class var sharedInstance : CachingService {
        struct Static {
            static let instance : CachingService = CachingService()
        }

        return Static.instance
    }

    override init() {
        super.init()

        self.cacheHandler = CacheHandler.sharedInstance
        self.downloader = Downloader.sharedInstance
    }


    public func cachedFilePathForURL(url: NSURL, completion: ((url: NSURL?) -> Void)) {
        let fileManager = NSFileManager.defaultManager()
        var cachedURL : NSURL?

        // Check if there is an already cached copy
        if (self.cacheHandler.hasCachedFileForUrl(url.relativePath!)) {
            cachedURL = NSURL.URLWithString(self.cacheHandler.getFilePathForUrl(url.relativePath!, isTemporary: true))

            if (fileManager.fileExistsAtPath(cachedURL!.relativePath!)) {
                completion(url: cachedURL!)
                return;
            }

            cachedURL = NSURL.URLWithString(self.cacheHandler.getFilePathForUrl(url.relativePath!, isTemporary: false))

            if (fileManager.fileExistsAtPath(cachedURL!.relativePath!)) {
                completion(url: cachedURL!)
                return;
            }
        }

        // No cached version could be found. Fetch from original source to temp file
        cachedURL = NSURL.URLWithString(self.cacheHandler.getFilePathForUrl(url.relativePath!, isTemporary: true))

        self.downloader.downloadDataFromURL(url,
            localURL: cachedURL!,
            completion: { (success) -> Void in
                if (success) {
                    completion(url: cachedURL!)
                } else {
                    println("Error downloading media file")
                    completion(url: nil)
                }
            }
        )
    }

}