//
//  User.h
//  XboxBuddy
//
//  Created by Christine Wang on 2/17/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const UserDidLoginNotification;
extern NSString *const UserDidLogoutNotification;

@interface User : NSObject

+ (User *)currentUser;
+ (void)setCurrentUser:(User *)currentUser;

- (id)initWithGamerTag:(NSString *)gamerTag;

@property (nonatomic, strong) NSString *gamerTag;

@end
