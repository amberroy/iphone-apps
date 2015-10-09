//
//  AchievementCell.h
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Achievement.h"
#import "SwipeWithOptionsCell.h"

@interface AchievementCell : SwipeWithOptionsCell

-(void)initWithAchievement:(Achievement *)achievementObj;

@end
