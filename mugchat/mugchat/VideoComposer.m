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

#import "VideoComposer.h"
#import "Mug.h"

#import "Flips-Swift.h"

@implementation VideoComposer

- (instancetype)init
{
    self = [super init];

    if (self) {
        self.renderOverlays = YES;
    }

    return self;
}

- (NSURL *)videoFromMugs:(NSArray *)mugs
{
    NSArray *messageParts = [self videoPartsFromFlips:mugs];
    
    return [self videoJoiningParts:messageParts];
}

- (NSArray *)videoPartsFromFlips:(NSArray *)flips
{
    [self precacheAssetsFromFlips:flips];

    NSMutableArray *messageParts = [NSMutableArray array];

    for (Mug *flip in flips) {
        AVAsset *videoTrack = [self videoFromMug:flip];

        if (videoTrack) {
            [messageParts addObject:videoTrack];
        }
    }

    return [NSArray arrayWithArray:messageParts];
}

- (void)precacheAssetsFromFlips:(NSArray *)flips
{
    CachingService *cachingService = [CachingService sharedInstance];
    dispatch_group_t cachingGroup = dispatch_group_create();

    for (Mug *flip in flips) {
        if ([flip hasBackground]) {
            dispatch_group_enter(cachingGroup);

            [cachingService cachedFilePathForURL:[NSURL URLWithString:flip.backgroundURL]
                                      completion:^(NSURL *localFileURL) {
                                          dispatch_group_leave(cachingGroup);
                                      }];
        }

        if ([flip hasAudio]) {
            dispatch_group_enter(cachingGroup);

            [cachingService cachedFilePathForURL:[NSURL URLWithString:flip.soundURL]
                                      completion:^(NSURL *localFileURL) {
                                          dispatch_group_leave(cachingGroup);
                                      }];
        }
        

    }

    // Timeout is number of flips times 30 seconds
    dispatch_group_wait(cachingGroup, dispatch_time(DISPATCH_TIME_NOW, flips.count * 30 * NSEC_PER_SEC));
}

- (NSURL *)videoFromMugMessage:(MugMessage *)mugMessage
{
    NSMutableArray *messageParts = [NSMutableArray array];

    for (Mug *mug in mugMessage.mugs) {
        AVAsset *videoTrack = [self videoFromMug:mug];

        if (videoTrack) {
            [messageParts addObject:videoTrack];
        }
    }

    return [self videoJoiningParts:messageParts];
}

- (AVAsset *)videoFromMug:(Mug *)flip {
    __block AVAsset *track;
    
    NSLog(@"flip word: %@", flip.word);
    NSString *word = flip.word;

    dispatch_group_t group = dispatch_group_create();

    // Empty mugs doesn't exist
    Mug *flipInContext = [flip MR_inThreadContext];
    if (flipInContext == nil) {
        flipInContext = [Mug MR_createEntity];
        flipInContext.word = word;
    }

    dispatch_group_enter(group);
    [self prepareVideoAssetFromFlip:flipInContext completion:^(BOOL success, AVAsset *videoAsset) {
        if (success) {
            track = videoAsset;
        }
        dispatch_group_leave(group);
    }];

    // Timeout in 5 seconds
    dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));

    return track;
}


#pragma mark - Private

- (NSURL *)videoJoiningParts:(NSArray *)videoParts
{
    AVMutableComposition *composition = [AVMutableComposition composition];

    CMTime insertionPoint = kCMTimeZero;

    for (AVAsset *videoAsset in videoParts) {
        CMTime trackDuration = videoAsset.duration;

        // should never happen as the videos are recorded with a fixed length of 1 second
        // NOTE: value / timeScale = seconds
        if ((trackDuration.value / trackDuration.timescale) > 1) {
            trackDuration = CMTimeMake(1, 1);
        }

        NSError *error;
        [composition insertTimeRange:CMTimeRangeMake(kCMTimeZero, trackDuration)
                             ofAsset:videoAsset
                              atTime:insertionPoint
                               error:&error];

        if (error) {
            NSLog(@"ERROR ADDING TRACK: %@", error);
        } else {
            insertionPoint = CMTimeAdd(insertionPoint, trackDuration);
        }
    }

    NSURL *outputFolder = [self outputFolderPath];
    __block NSURL *videoUrl = [outputFolder URLByAppendingPathComponent:@"generated-mug-message.mov"]; // TODO: Should get unique ID of mug message to use as filename

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtURL:videoUrl error:nil];
    

    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    exportSession.outputURL = videoUrl;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status == AVAssetExportSessionStatusFailed) {
            videoUrl = nil;
            NSLog(@"Could not create video composition.");
        }
        dispatch_group_leave(group);
    }];

    // 20 seconds timeout
    dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC));
    
    return videoUrl;
}

- (void)prepareVideoAssetFromFlip:(Mug *)flip completion:(void (^)(BOOL success, AVAsset *videoAsset))completion
{
    NSURL *videoURL;
    CacheHandler *cacheHandler = [CacheHandler sharedInstance];

    if ([flip isBackgroundContentTypeVideo]) {
        NSString *filePath = [cacheHandler getFilePathForUrlFromAnyFolder:flip.backgroundURL];
        videoURL = [NSURL fileURLWithPath:filePath];
    } else {
        videoURL = [NSURL fileURLWithPath:[ImageVideoCreator videoPathForMug:flip]];
    }

    AVURLAsset *videoAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    AVAssetTrack *videoTrack = [self videoTrackFromAsset:videoAsset];

    AVMutableComposition *composition;

    if ([flip hasAudio]) {
        NSString *audioPath = [cacheHandler getFilePathForUrlFromAnyFolder:flip.soundURL];
        AVAsset *audioAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:audioPath]];
        composition = [self compositionFromVideoAsset:videoAsset audioAsset:audioAsset];
    } else {
        composition = [self compositionFromVideoAsset:videoAsset];
    }
    
    if (!composition) {
        completion(NO, nil);
        return;
    }

    AVMutableVideoComposition *videoComposition = [self videoCompositionFromTrack:videoTrack withText:flip.word];

    NSURL *outputURL = [self tempOutputFileURL];

    /// exporting
    AVAssetExportSession *exportSession;
    exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    exportSession.videoComposition = videoComposition;
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;

    [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        if (exportSession.status == AVAssetExportSessionStatusFailed) {
            NSLog(@"Could not create video composition. Error: %@", exportSession.error.description);
            if (completion) {
                completion(NO, nil);
            }

        } else  if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            if (completion) {
                AVAsset *outputAsset = [AVAsset assetWithURL:outputURL];
                completion(YES, outputAsset);
            }
        }
    }];
    
}

- (NSURL *)outputFolderPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSURL *outputFolder = [[fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    outputFolder = [outputFolder URLByAppendingPathComponent:@"VideoComposerOutput"];

    if (![fileManager fileExistsAtPath:[outputFolder relativePath] isDirectory:nil]) {
        [fileManager createDirectoryAtPath:[outputFolder relativePath]
               withIntermediateDirectories:NO
                                attributes:nil
                                     error:nil];
    }

    return outputFolder;
}

- (NSURL *)tempOutputFileURL
{
    NSURL *outputFolder = [self outputFolderPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSUInteger index = 0;
    NSURL *outputPath;

    do {
        index++;
        NSString *filename = [NSString stringWithFormat:@"temp-flip-%lu.mov", (unsigned long)index];
        outputPath = [outputFolder URLByAppendingPathComponent:filename];
    } while ([fileManager fileExistsAtPath:[outputPath relativePath] isDirectory:nil]);

    return outputPath;
}

- (UIInterfaceOrientation)orientationForTrack:(AVAssetTrack *)videoTrack
{
    CGSize size = [videoTrack naturalSize];
    CGAffineTransform transform = [videoTrack preferredTransform];

    if (size.width == transform.tx && size.height == transform.ty) {
        return UIInterfaceOrientationLandscapeRight;

    } else if (transform.tx == 0 && transform.ty == 0) {
        return UIInterfaceOrientationLandscapeLeft;

    } else if (transform.tx == 0 && transform.ty == size.width) {
        return UIInterfaceOrientationPortraitUpsideDown;

    } else {
        return UIInterfaceOrientationPortrait;
    }
}

- (CATextLayer *)layerForText:(NSString *)text
{
    CATextLayer *titleLayer = [CATextLayer layer];
    titleLayer.string = text;
    titleLayer.foregroundColor = [[UIColor whiteColor] CGColor];
    titleLayer.shadowOpacity = 0.5;
    titleLayer.alignmentMode = kCAAlignmentCenter;
    titleLayer.font = CGFontCreateWithFontName((CFStringRef)@"AvenirNext-Bold");
    titleLayer.fontSize = 32.0;
    return titleLayer;
}

- (AVAssetTrack *)videoTrackFromAsset:(AVAsset *)asset
{
    return [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
}

- (AVAssetTrack *)audioTrackFromAsset:(AVAsset *)asset
{
    return [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
}

- (CGSize)croppedVideoSize:(AVAssetTrack *)videoTrack
{
    CGFloat squareSide = MIN(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
    CGSize videoSize = CGSizeMake(squareSide, squareSide);

    return videoSize;
}


#pragma mark - Video manipulation

- (CALayer *)squareCroppedVideoLayer:(CALayer *)videoLayer fromTrack:(AVAssetTrack *)videoTrack
{
    CGSize videoSize = [self croppedVideoSize:videoTrack];
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);

    return videoLayer;
}

- (CALayer *)orientationFixedVideoLayer:(CALayer *)videoLayer fromTrack:(AVAssetTrack *)videoTrack
{
    // No need to worry about other orientations while we only support portrait
    if ([self orientationForTrack:videoTrack] == UIInterfaceOrientationLandscapeLeft) {
        CGAffineTransform rotation = CGAffineTransformMakeRotation(-M_PI_2);
        CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(CGRectGetWidth(videoLayer.frame), CGRectGetHeight(videoLayer.frame));

        videoLayer.affineTransform = CGAffineTransformConcat(rotation, translateToCenter);
    }

    return videoLayer;
}

- (AVMutableVideoComposition *)videoCompositionFromImage:(UIImage *)image withText:(NSString *)text
{
    CGSize compositionSize = image.size;

    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = compositionSize;
    videoComposition.frameDuration = CMTimeMake(1, 30);


    CALayer *imageLayer = [CALayer layer];
    imageLayer.contents = CFBridgingRelease(image.CGImage);
    imageLayer.frame = CGRectMake(0, 0, compositionSize.width, compositionSize.height);

    CATextLayer *wordLayer = [self layerForText:text];
    wordLayer.frame = CGRectMake(0, 50, compositionSize.width, 50);

    [imageLayer addSublayer:wordLayer];
    [wordLayer display];

    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithAdditionalLayer:imageLayer asTrackID:kCMPersistentTrackID_Invalid];

    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(30, 30));

    videoComposition.instructions = @[instruction];

    return videoComposition;
}

- (AVMutableVideoComposition *)videoCompositionFromTrack:(AVAssetTrack *)videoTrack withText:(NSString *)text
{
    CGSize croppedVideoSize = [self croppedVideoSize:videoTrack];

    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = croppedVideoSize;
    videoComposition.frameDuration = CMTimeMake(1, 30);

    CALayer *parentLayer = [self squareCroppedVideoLayer:[CALayer layer] fromTrack:videoTrack];

    CALayer *videoLayer = [CALayer layer];
    videoLayer = [self orientationFixedVideoLayer:videoLayer fromTrack:videoTrack];
    [parentLayer addSublayer:videoLayer];

    if (self.renderOverlays) {
        CATextLayer *wordLayer = [self layerForText:text];
        wordLayer.frame = CGRectMake(0, 50, croppedVideoSize.width, 50);
        [parentLayer addSublayer:wordLayer];
        [wordLayer display];
    }

    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    videoLayer.frame = CGRectMake(0, 0, croppedVideoSize.width, croppedVideoSize.height);

    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoTrack.asset.duration);

    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    instruction.layerInstructions = @[layerInstruction];
    videoComposition.instructions = @[instruction];

    return videoComposition;
}

- (AVMutableComposition *)compositionFromVideoAsset:(AVAsset *)videoAsset
{
    return [self compositionFromVideoAsset:videoAsset audioAsset:videoAsset];
}

- (AVMutableComposition *)compositionFromVideoAsset:(AVAsset *)videoAsset audioAsset:(AVAsset *)audioAsset
{
    AVMutableComposition *composition = [AVMutableComposition composition];
    CMTime compositionDuration = videoAsset.duration; // Use video length
    NSError *error;

    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];

    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, compositionDuration)
                                   ofTrack:[self videoTrackFromAsset:videoAsset]
                                    atTime:kCMTimeZero
                                     error:&error];

    if (error) {
        NSLog(@"Could not insert video track: %@", error.localizedDescription);
        return nil;
    }

    AVAssetTrack *audioTrack = [self audioTrackFromAsset:audioAsset];
    if (audioTrack) {
        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                    preferredTrackID:kCMPersistentTrackID_Invalid];

        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, compositionDuration)
                                       ofTrack:audioTrack
                                        atTime:kCMTimeZero
                                         error:&error];

        if (error) {
            NSLog(@"Could not insert audio track: %@", error.localizedDescription);
            return nil;
        }
    }

    return composition;
}

@end
