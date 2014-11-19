//
//  PNHeartbeatRequest.m
//  pubnub
//
//  Created by Sergey Mamontov on 1/7/14.
//  Copyright (c) 2014 PubNub Inc. All rights reserved.
//

#import "PNBaseRequest+Protected.h"
#import "PNServiceResponseCallbacks.h"
<<<<<<< HEAD
#import "NSString+PNAddition.h"
#import "PNHeartbeatRequest.h"
#import "PubNub+Protected.h"
=======
#import "PNJSONSerialization.h"
#import "NSString+PNAddition.h"
#import "PNHeartbeatRequest.h"
#import "PNConfiguration.h"
#import "PNMacro.h"
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba


// ARC check
#if !__has_feature(objc_arc)
#error PubNub heartbeat request must be built with ARC.
// You can turn on ARC for only PubNub files by adding '-fobjc-arc' to the build phase for each of its files.
#endif


#pragma mark Private interface declaration

@interface PNHeartbeatRequest ()


#pragma mark - Properties

/**
 Stores reference on list of channels for which heartbeat will be performed.
 */
@property (nonatomic, strong) NSArray *channels;

/**
<<<<<<< HEAD
 Stores reference on client identifier for which heartbeat should be sent.
 */
@property (nonatomic, copy) NSString *clientIdentifier;

/**
=======
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
 Stores reference on state \b NSDictionary instance which should be sent along with acknowledgment that client is
 still active.
 */
@property (nonatomic, strong) NSDictionary *state;

<<<<<<< HEAD
=======
/**
 Storing configuration dependant parameters
 */
@property (nonatomic, assign) NSInteger presenceHeartbeatTimeout;
@property (nonatomic, copy) NSString *subscriptionKey;

>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
#pragma mark -


@end


#pragma mark - Public interface implementation

@implementation PNHeartbeatRequest


#pragma mark - Class methods

+ (PNHeartbeatRequest *)heartbeatRequestForChannel:(PNChannel *)channel withClientState:(NSDictionary *)clientState {

    return [self heartbeatRequestForChannels:@[channel] withClientState:clientState];
}

+ (PNHeartbeatRequest *)heartbeatRequestForChannels:(NSArray *)channels withClientState:(NSDictionary *)clientState {

    return [[self alloc] initWithChannels:channels withClientState:clientState];
}


#pragma mark - Instance methods

- (id)initWithChannels:(NSArray *)channels withClientState:(NSDictionary *)clientState {

    // Check whether initialization successful or not
    if ((self = [super init])) {

        self.sendingByUserRequest = NO;
        self.channels = [NSArray arrayWithArray:channels];
<<<<<<< HEAD
        self.clientIdentifier = [PubNub escapedClientIdentifier];
=======
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
        self.state = clientState;
    }


    return self;
}

<<<<<<< HEAD
- (NSString *)resourcePath {

    NSString *heartbeatValue = @"";
    if ([PubNub sharedInstance].configuration.presenceHeartbeatTimeout > 0.0f) {
        
        heartbeatValue = [NSString stringWithFormat:@"&heartbeat=%d", [PubNub sharedInstance].configuration.presenceHeartbeatTimeout];
=======
- (void)finalizeWithConfiguration:(PNConfiguration *)configuration clientIdentifier:(NSString *)clientIdentifier {
    
    [super finalizeWithConfiguration:configuration clientIdentifier:clientIdentifier];
    
    self.presenceHeartbeatTimeout = configuration.presenceHeartbeatTimeout;
    self.subscriptionKey = configuration.subscriptionKey;
    self.clientIdentifier = clientIdentifier;
}

- (NSString *)resourcePath {

    NSString *heartbeatValue = @"";
    if (self.presenceHeartbeatTimeout > 0.0f) {
        
        heartbeatValue = [NSString stringWithFormat:@"&heartbeat=%ld", (long)self.presenceHeartbeatTimeout];
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
    }

    NSString *state = @"";
    if (self.state) {

        state = [NSString stringWithFormat:@"&state=%@",
                        [[PNJSONSerialization stringFromJSONObject:self.state] pn_percentEscapedString]];
    }
<<<<<<< HEAD

    return [NSString stringWithFormat:@"/v2/presence/sub-key/%@/channel/%@/heartbeat?uuid=%@%@%@%@&pnsdk=%@",
                                      [[PubNub sharedInstance].configuration.subscriptionKey pn_percentEscapedString],
                                      [[self.channels valueForKey:@"escapedName"] componentsJoinedByString:@","],
                                      self.clientIdentifier, state, heartbeatValue,
                                      ([self authorizationField] ? [NSString stringWithFormat:@"&%@",
                                                                                              [self authorizationField]] : @""),
                                      [self clientInformationField]];
}

- (NSString *)debugResourcePath {

    NSMutableArray *resourcePathComponents = [[[self resourcePath] componentsSeparatedByString:@"/"] mutableCopy];
    [resourcePathComponents replaceObjectAtIndex:4 withObject:PNObfuscateString([[PubNub sharedInstance].configuration.subscriptionKey pn_percentEscapedString])];

    return [resourcePathComponents componentsJoinedByString:@"/"];
=======
    
    // Compose filtering predicate to retrieve list of channels which are not presence observing channels
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"isPresenceObserver = NO"];
    NSArray *channelsToLeave = [self.channels filteredArrayUsingPredicate:filterPredicate];
    NSString *channelsListParameter = nil;
    NSString *groupsListParameter = nil;
    if ([channelsToLeave count]) {
        
        NSArray *channels = [channelsToLeave filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.isChannelGroup = NO"]];
        NSArray *groups = [channelsToLeave filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.isChannelGroup = YES"]];
        if ([channels count]) {
            
            channelsListParameter = [[channels valueForKey:@"escapedName"] componentsJoinedByString:@","];
        }
        if ([groups count]) {
            
            groupsListParameter = [[groups valueForKey:@"escapedName"] componentsJoinedByString:@","];
            if (!channelsListParameter) {
                
                channelsListParameter = @",";
            }
        }
    }
    

    return [NSString stringWithFormat:@"/v2/presence/sub-key/%@/channel/%@/heartbeat?uuid=%@%@%@%@%@&pnsdk=%@",
            [self.subscriptionKey pn_percentEscapedString], (channelsListParameter ? channelsListParameter : @""),
            [self.clientIdentifier stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], state, heartbeatValue,
            (groupsListParameter ? [NSString stringWithFormat:@"&channel-group=%@", groupsListParameter] : @""),
            ([self authorizationField] ? [NSString stringWithFormat:@"&%@", [self authorizationField]] : @""),
            [self clientInformationField]];
}

- (NSString *)debugResourcePath {
    
    NSString *subscriptionKey = [self.subscriptionKey pn_percentEscapedString];
    return [[self resourcePath] stringByReplacingOccurrencesOfString:subscriptionKey withString:PNObfuscateString(subscriptionKey)];
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"<%@|%@>", NSStringFromClass([self class]), [self debugResourcePath]];
}

#pragma mark -


@end
