//
//  Comment.m
//  XboxBuddy
//
//  Created by Amber Roy on 2/22/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "Comment.h"
#import <Parse/PFObject+Subclass.h>
#import <Parse/PFQuery.h>

@implementation Comment

@dynamic content;
@dynamic timestamp;
@dynamic authorGamertag;
@dynamic authorImageUrl;
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
        
        self.gameName = achievement.gameName;
        self.achievementName = achievement.name;
        self.achievementGamertag = achievement.gamertag;
        
        Profile *authorProfile = [[XboxLiveClient instance] userProfile];
        self.authorGamertag = authorProfile.gamertag;
        self.authorImageUrl = authorProfile.gamerpicImageUrl;
        
    }
    
    return self;
}

+ (PFQuery *)queryWithAchievement:(Achievement *)achievement
{
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:@"achievementName" equalTo:achievement.name];
    [query whereKey:@"achievementGamertag" equalTo:achievement.gamertag];
    return query;
}


+ (NSString *)parseClassName
{
    return @"Comment";
}

@end
