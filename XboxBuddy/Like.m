//
//  Like.m
//  XboxBuddy
//
//  Created by Amber Roy on 2/22/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "Like.h"
#import <Parse/PFObject+Subclass.h>
#import <Parse/PFQuery.h>

@implementation Like

@dynamic timestamp;
@dynamic authorGamertag;
@dynamic authorImageUrl;
@dynamic gameName;
@dynamic achievementName;
@dynamic achievementGamertag;

- (Like *)initWithContent:(NSString *)content
                 withAchievement:(Achievement *)achievement
{
    
    self = [super init];
    if (self) {
        self.timestamp = [NSDate date];
        
        self.gameName = achievement.gameName;
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
    return @"Like";
}

@end
