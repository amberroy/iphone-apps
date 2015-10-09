//
//  UserAchievementCell.h
//  XboxBuddy
//
//  Created by Christine Wang on 2/4/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Achievement.h"

@interface UserAchievementCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *gamertag;
@property (weak, nonatomic) IBOutlet UILabel *achievementPoints;
@property (weak, nonatomic) IBOutlet UILabel *gameName;
@property (strong, nonatomic) IBOutlet UILabel *achievementEarnedOn;

@property (weak, nonatomic) IBOutlet UIImageView *gamerImage;
@property (strong, nonatomic) IBOutlet UIImageView *achievementImage;

-(void)initWithAchievement:(Achievement *)achievementObj;

@end
