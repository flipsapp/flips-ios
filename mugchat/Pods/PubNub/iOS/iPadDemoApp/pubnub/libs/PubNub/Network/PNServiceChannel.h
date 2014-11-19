//
//  PNServiceChannel.h
//  pubnub
//
//  This channel is required to manage
//  service message sending to PubNub service.
//  Will send messages like:
//      - publish
//      - time
//      - history
//      - here now (list of participants)
//      - push notification state manipulation
//      - "ping" (latency measurement if enabled)
//
//  Notice: don't try to create more than
//          one messaging channel on MacOS
//
//
//  Created by Sergey Mamontov on 12/15/12.
//
//

#import "PNConnectionChannel.h"
#import "PNConnectionChannelDelegate.h"
#import "PNMacro.h"


@protocol PNServiceChannelDelegate;


@interface PNServiceChannel : PNConnectionChannel


#pragma mark Properties

// Stores reference on service channel delegate which is
// interested in service message event tracking
@property (nonatomic, pn_desired_weak) id<PNServiceChannelDelegate> serviceDelegate;


#pragma mark - Class methods

/**
<<<<<<< HEAD
 * Return reference on configured service communication
 * channel with specified delegate
 */
+ (PNServiceChannel *)serviceChannelWithDelegate:(id<PNConnectionChannelDelegate>)delegate;
=======
 Return reference on configured service communication channel with specified delegate

 @param configuration
 Reference on \b PNConfiguration instance which should be used by connection channel and accompany classes.

 @param delegate
 Reference on delegate which will accept all general callbacks from underlay connection channel class.

 @return Reference on fully configured and ready to use instance.
 */
+ (PNServiceChannel *)serviceChannelWithConfiguration:(PNConfiguration *)configuration
                                          andDelegate:(id<PNConnectionChannelDelegate>)delegate;
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba


#pragma mark - Instance methods

#pragma mark - Messages processing methods

/**
 * Generate object sending request to specified channel
 */
- (PNMessage *)sendMessage:(id)object toChannel:(PNChannel *)channel compressed:(BOOL)shouldCompressMessage
            storeInHistory:(BOOL)shouldStoreInHistory;

/**
 * Sends configured message request to the PubNub service
 */
- (void)sendMessage:(PNMessage *)message;


#pragma mark - PAM manipulation methods

/**
<<<<<<< HEAD
 Change access rights for specific object (object defined by set of parameters).

 @param channels
 Array of \b PNChannel instances for which access rights should be applied. There can be only one channel and one or
 more client access keys or many channels and no authorization keys.

 @param accessRights
 Bit mask for access rights which should be applied: PNReadAccessRight, PNWriteAccessRight, PNNoAccessRights.

 @param authorizationKeys
 Array of \a NSString instances which describe scope of authorization keys for which access rights is applied. There
 can be no authorization key and many \b PNChannel instances in \a 'channels' parameter or many keys and single \b
 PNChannel.

 @param accessPeriod
 Period during which granted access rights will be valid. As soon as it will be exhausted all rights from specific
 object will be revoked.

 @note Depending on parameters configuration, access rights can be changed on three levels: application (if there is
 no values in \a 'channels' and \a 'authorizationKeys' parameters), channel (if there is no values in
 \a 'authorizationKeys' parameter) and user (if there is values for both \a 'channels' and \a 'authorizationKeys'
 parameters).

 @see \b PNChannel class

 @see \a -auditAccessRightsForChannels:clients:
 */
- (void)changeAccessRightsForChannels:(NSArray *)channels accessRights:(PNAccessRights)accessRights
                    authorizationKeys:(NSArray *)authorizationKeys forPeriod:(NSInteger)accessPeriod;
=======
 @brief Change access rights to set of data feed objects in linkage to client's authorization keys.
 
 @discussion This method allow to modify access rights for set of data feed objects and link them to concrete client 
 using it's authorization key.
 
 @param channelObjects    List of objects (which conforms to \b PNChannelProtocol data feed object protocol) for which
                          \b PubNub client should change access rights.
 @param accessRights      Bit field which allow to specify set of options. Bit options specified in 
                          \c PNAccessRights
 @param authorizationKeys List of \a NSString instances which specify list of client for which access rights should be 
                          changed.
 @param accessPeriod      Duration in minutes during which provided access rights should be active for provided objects.
 
 @since 3.7.0
 */
- (void)changeAccessRightsFor:(NSArray *)channelObjects accessRights:(PNAccessRights)accessRights
            authorizationKeys:(NSArray *)authorizationKeys onPeriod:(NSInteger)accessPeriod;
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba

/**
 Audit access rights for specific object (object defined by set of parameters).

<<<<<<< HEAD
 @param channels
 Array of \b PNChannel instances for which access wights should be audited.
=======
 @param channelObjects
 Array of objects (which conforms to \b PNChannelProtocol data feed object protocol) like \b PNChannel, 
 \b PNChannelGroup or \b PNChannelGroupNamespace for which access wights should be audited.
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba

 @param clientsAuthorizationKeys
 Array of \a NSString instances which describes scope of authorization keys for which access rights should be audited.

 @note If there is no values in \a 'channels' and \a 'clientsAuthorizationKeys' parameters,
 access rights will be audited on \a 'application' level. If only \a 'channels' parameter specified,
 then access rights will be audited on \a 'channel' level for specified channels. If both \a 'channels' and
 \a 'clientsAuthorizationKeys' parameters specified, access rights will be audited on \a 'user' level. Audition can
 be performed on: \a 'application' level, \a 'channel' level (if there us no value in \a 'clientsAuthorizationKeys'
 parameter than it is possible audit multiple channels) and \a 'user' level (if there is only one channel is is
 possible to audit multiple clients).

 @see \b PNChannel class
<<<<<<< HEAD

 @see \a -changeAccessRightsForChannels:accessRights:authorizationKeys:forPeriod:
 */
- (void)auditAccessRightsForChannels:(NSArray *)channels clients:(NSArray *)clientsAuthorizationKeys;
=======
 */
- (void)auditAccessRightsFor:(NSArray *)channelObjects clients:(NSArray *)clientsAuthorizationKeys;
>>>>>>> 0176047a5fd5f839466f621bacdb66d9affd19ba


#pragma mark -


@end
