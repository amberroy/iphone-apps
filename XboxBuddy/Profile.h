//
//  Profile.h
//  XboxBuddy
//
//  Created by Amber Roy on 2/2/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Profile : NSObject

@property NSString *gamertag;
@property NSInteger gamerscore;
@property NSString *gamerImageUrl;
@property NSString *onlineStatus;


+(NSArray *)profilesWithArray:(NSArray *)array;
- (Profile *)initWithDictionary:(NSDictionary *)dict;

@end
