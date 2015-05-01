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


class TutorialPagesDataSource : NSObject, UIPageViewControllerDataSource {

    private var pageAssets: Array<String> = ["flips-tutorial.mp4", "Slide1.png", "Slide2.png", "Slide3.png", "Slide4.png", "Slide5.png", "Slide6.png"]

    func viewControllerForPage(page: Int) -> TutorialPageViewController? {
        if (page < 0 || page >= pageAssets.count) {
            return nil
        }

        let asset = self.pageAssets[page]
        var pageViewController: TutorialPageViewController?

        if (asset.pathExtension == "mp4") {
            pageViewController = TutorialPageVideoViewController()
            (pageViewController! as TutorialPageVideoViewController).pageVideo = asset
        } else {
            pageViewController = TutorialPageImageViewController()
            (pageViewController! as TutorialPageImageViewController).pageImage = asset
        }

        pageViewController!.pageIndex = page

        return pageViewController
    }

    // MARK: - UIPageViewControllerDataSource

    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        var page = (viewController as TutorialPageViewController).pageIndex - 1

        var pageViewController = self.viewControllerForPage(page)

        return pageViewController
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        var page = (viewController as TutorialPageViewController).pageIndex + 1

        var pageViewController = self.viewControllerForPage(page)

        return pageViewController
    }

    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return pageAssets.count
    }

    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }

}
