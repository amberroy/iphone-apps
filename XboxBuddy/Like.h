//
//  Like.h
//  XboxBuddy
//
//  Created by Amber Roy on 2/22/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/PFSubclassing.h>
#import <Parse/PFObject.h>

@interface Like : PFObject<PFSubclassing>

// Like
@property NSDate *timestamp;

// Author
@property NSString *authorGamertag;  // Liked achievement.
@property NSString *authorImageUrl;

// Achievement
@property NSString *gameName;
@property NSString *achievementName;
@property NSString *achievementGamertag;  // Earned achievement.

- (Like *)initWithAchievement:(Achievement *)achievement;

@end
