//
//  Comment.h
//  XboxBuddy
//
//  Created by Amber Roy on 2/22/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/PFSubclassing.h>
#import <Parse/PFObject.h>

@interface Comment : PFObject<PFSubclassing>

// Comment
@property NSString *content;
@property NSDate *timestamp;

// Author
@property NSString *authorGamertag;  // Commented on achievement.
@property NSString *authorImageUrl;

// Achievement
@property NSString *gameName;
@property NSString *achievementName;
@property NSString *achievementGamertag;  // Earned achievement.

- (Comment *)initWithContent:(NSString *)content
                 withAchievement:(Achievement *)achievement;

+ (PFQuery *)queryWithAchievement:(Achievement *)achievement;

@end
