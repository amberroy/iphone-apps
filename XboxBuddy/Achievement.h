//
//  Achievement.h
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Achievement : NSObject

@property NSString *name;
@property NSString *gamertag;

+(NSArray *)achievementsWithArray:(NSArray *)array;


@end
