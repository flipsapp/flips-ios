//
//  PNAccessRightsInformation.m
//  pubnub
//
//  Created by Sergey Mamontov on 11/3/13.
//  Copyright (c) 2013 PubNub Inc. All rights reserved.
//


#import "PNAccessRightsInformation+Protected.h"
#import "PNAccessRightOptions+Protected.h"
#import "PNChannel.h"
#import "PNHelper.h"
#import "PNMacro.h"


// ARC check
#if !__has_feature(objc_arc)
#error PubNub channel access right information data object must be built with ARC.
// You can turn on ARC for only PubNub files by adding '-fobjc-arc' to the build phase for each of its files.
#endif


#pragma mark - Public interface implementation

@implementation PNAccessRightsInformation


#pragma mark - Class methods

+ (PNAccessRightsInformation *)accessRightsInformationForLevel:(PNAccessRightsLevel)level rights:(PNAccessRights)rights
                                                applicationKey:(NSString *)subscriptionKey forChannel:(PNChannel *)channel
                                                        client:(NSString *)clientAuthorizationKey
                                                  accessPeriod:(NSUInteger)accessPeriodDuration {

    return [[self alloc] initWithAccessLevel:level rights:rights applicationKey:subscriptionKey channel:channel
                                      client:clientAuthorizationKey accessPeriod:accessPeriodDuration];
}

+ (NSArray *)accessRightsInformationForLevel:(PNAccessRightsLevel)accessRightsLevel fromList:(NSArray *)accessRightsInformation {

    return [accessRightsInformation filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.level = %d", accessRightsLevel]];
}


#pragma mark - Instance methods

- (id)initWithAccessLevel:(PNAccessRightsLevel)level rights:(PNAccessRights)rights
           applicationKey:(NSString *)subscriptionKey channel:(PNChannel *)channel
                   client:(NSString *)clientAuthorizationKey accessPeriod:(NSUInteger)accessPeriodDuration {

    // Check whether initialization was successful or not
    if ((self = [super init])) {

        self.level = level;
        self.rights = rights;
        self.subscriptionKey = subscriptionKey;
<<<<<<< HEAD
        self.channel = channel;
=======
        self.object = channel;
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
        self.authorizationKey = clientAuthorizationKey;
        self.accessPeriodDuration = accessPeriodDuration;
    }


    return self;
}

- (BOOL)hasReadRight {

    return [PNBitwiseHelper is:self.rights containsBit:PNReadAccessRight];
}

- (BOOL)hasWriteRight {
    
    return [PNBitwiseHelper is:self.rights containsBit:PNWriteAccessRight];
}

- (BOOL)hasAllRights {

    return [PNBitwiseHelper is:self.rights strictly:YES containsBits:PNReadAccessRight, PNWriteAccessRight, BITS_LIST_TERMINATOR];
}

<<<<<<< HEAD
=======
- (BOOL)hasManagementRight {
    
    return [PNBitwiseHelper is:self.rights containsBit:PNManagementRight];
}

>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
- (BOOL)isAllRightsRevoked {

    return ![self hasAllRights];
}

- (NSString *)description {

    NSMutableString *description = [NSMutableString stringWithFormat:@"%@ (%p) <",
                                                    NSStringFromClass([self class]), self];

    NSString *level = @"application";
<<<<<<< HEAD
    if (self.level == PNChannelAccessRightsLevel) {

=======
    if (self.level == PNChannelGroupAccessRightsLevel) {

        level = @"channel-group";
    }
    else if (self.level == PNChannelAccessRightsLevel) {
        
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
        level = @"channel";
    }
    else if (self.level == PNUserAccessRightsLevel) {

        level = @"user";
    }
    [description appendFormat:@"level: %@;", level];

    NSString *rights = @"none (revoked)";
    if ([self hasReadRight] || [self hasWriteRight]) {

        rights = [self hasReadRight] ? @"read" : @"";
        if ([self hasWriteRight]) {

            rights = ([rights length] > 0) ? [rights stringByAppendingString:@" / write"] : @"write";
        }
    }
<<<<<<< HEAD
=======
    if ([self hasManagementRight]) {
        
        rights = ([rights length] > 0) ? [rights stringByAppendingString:@" / management"] : @"management";
    }
    
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
    [description appendFormat:@" rights: %@;", rights];

    [description appendFormat:@" application: %@;", PNObfuscateString(self.subscriptionKey)];

<<<<<<< HEAD
    if (self.level == PNChannelAccessRightsLevel) {

        [description appendFormat:@" channel: %@;", self.channel];
=======
    if (self.level == PNChannelGroupAccessRightsLevel) {

        [description appendFormat:@" channel-group: %@;", self.object];
    }
    else if (self.level == PNChannelAccessRightsLevel) {
        
        [description appendFormat:@" channel: %@;", self.object];
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
    }
    else if (self.level == PNUserAccessRightsLevel) {

        [description appendFormat:@" user: %@;", self.authorizationKey];
<<<<<<< HEAD
        [description appendFormat:@" channel: %@;", self.channel];
=======
        [description appendFormat:@" object: %@;", self.object];
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
    }

    [description appendFormat:@" access period duration: %lu>", (unsigned long)self.accessPeriodDuration];


    return description;
}

- (NSString *)logDescription {
    
    NSString *level = @"application";
<<<<<<< HEAD
    if (self.level == PNChannelAccessRightsLevel) {
=======
    if (self.level == PNChannelGroupAccessRightsLevel) {
        
        level = @"channel-group";
    }
    else if (self.level == PNChannelAccessRightsLevel) {
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
        
        level = @"channel";
    }
    else if (self.level == PNUserAccessRightsLevel) {
        
        level = @"user";
    }
    NSMutableString *logDescription = [NSMutableString stringWithFormat:@"<%@|%@|%@|%lu", level, PNObfuscateString(self.subscriptionKey),
                                       @(self.rights), (unsigned long)self.accessPeriodDuration];
<<<<<<< HEAD
    if (self.level == PNChannelAccessRightsLevel) {
        
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wundeclared-selector"
        [logDescription appendFormat:@"|%@", (self.channel ? [self.channel performSelector:@selector(logDescription)] : [NSNull null])];
=======
    if (self.level == PNChannelGroupAccessRightsLevel || self.level == PNChannelAccessRightsLevel) {
        
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wundeclared-selector"
        [logDescription appendFormat:@"|%@", (self.object ? [self.object performSelector:@selector(logDescription)] : [NSNull null])];
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
        #pragma clang diagnostic pop
    }
    else if (self.level == PNUserAccessRightsLevel) {
        
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wundeclared-selector"
        [logDescription appendFormat:@"|%@|%@", self.authorizationKey,
<<<<<<< HEAD
         (self.channel ? [self.channel performSelector:@selector(logDescription)] : [NSNull null])];
=======
         (self.object ? [self.object performSelector:@selector(logDescription)] : [NSNull null])];
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba
        #pragma clang diagnostic pop
    }
    [logDescription appendString:@">"];

    
    return logDescription;
}

#pragma mark -


@end
