//
//  Mug.h
//  mugchat
//
//  Created by Bruno Bruggemann on 10/13/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Mug : NSManagedObject

@property (nonatomic, retain) NSString * backgroundURL;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSNumber * isPrivate;
@property (nonatomic, retain) NSString * soundURL;
@property (nonatomic, retain) NSString * word;
@property (nonatomic, retain) User *owner;

@end
