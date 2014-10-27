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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Device, Mug, Room, User;

@interface User : NSManagedObject

@property (nonatomic, retain) NSDate * birthday;
@property (nonatomic, retain) NSString * facebookID;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSNumber * me;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSString * photoURL;
@property (nonatomic, retain) NSString * pubnubID;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSOrderedSet *contacts;
@property (nonatomic, retain) NSSet *devices;
@property (nonatomic, retain) NSSet *mugs;
@property (nonatomic, retain) NSSet *rooms;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)insertObject:(User *)value inContactsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromContactsAtIndex:(NSUInteger)idx;
- (void)insertContacts:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeContactsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInContactsAtIndex:(NSUInteger)idx withObject:(User *)value;
- (void)replaceContactsAtIndexes:(NSIndexSet *)indexes withContacts:(NSArray *)values;
- (void)addContactsObject:(User *)value;
- (void)removeContactsObject:(User *)value;
- (void)addContacts:(NSOrderedSet *)values;
- (void)removeContacts:(NSOrderedSet *)values;
- (void)addDevicesObject:(Device *)value;
- (void)removeDevicesObject:(Device *)value;
- (void)addDevices:(NSSet *)values;
- (void)removeDevices:(NSSet *)values;

- (void)addMugsObject:(Mug *)value;
- (void)removeMugsObject:(Mug *)value;
- (void)addMugs:(NSSet *)values;
- (void)removeMugs:(NSSet *)values;

- (void)addRoomsObject:(Room *)value;
- (void)removeRoomsObject:(Room *)value;
- (void)addRooms:(NSSet *)values;
- (void)removeRooms:(NSSet *)values;

@end