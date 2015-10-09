//
//  Comment.m
//  XboxBuddy
//
//  Created by Amber Roy on 2/22/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "Comment.h"
#import <Parse/PFObject+Subclass.h>

@implementation Comment

@dynamic content;
@dynamic timestamp;
@dynamic authorGamertag;
@dynamic authorImageUrl;
@dynamic gameID;
@dynamic achievementID;
@dynamic gameName;
@dynamic achievementName;
@dynamic achievementGamertag;

- (Comment *)initWithContent:(NSString *)content
                 withAchievement:(Achievement *)achievement
{
    
    self = [super init];
    if (self) {
        self.content = content;
        self.timestamp = [NSDate date];
        
        self.gameID = achievement.game.gameID;
        self.achievementID = achievement.achievementID;
        
        self.gameName = achievement.game.name;
        self.achievementName = achievement.name;
        self.achievementGamertag = achievement.gamertag;
        
        Profile *authorProfile = [[XboxLiveClient instance] userProfile];
        self.authorGamertag = authorProfile.gamertag;
        self.authorImageUrl = authorProfile.gamerpicImageUrl;
        
    }
    
    return self;
}


+ (NSString *)parseClassName
{
    return @"Comment";
}

@end
