//
//  HomeCell.h
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Achievement.h"

@interface HomeCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *gamerImage;
@property (strong, nonatomic) IBOutlet UILabel *gamerTag;
@property (weak, nonatomic) IBOutlet UILabel *gameName;

@property (strong, nonatomic) IBOutlet UILabel *achievementEarnedOn;
@property (weak, nonatomic) IBOutlet UIImageView *achievementImage;
@property (weak, nonatomic) IBOutlet UILabel *achievementPoints;

-(void)initWithAchievement:(Achievement *)achievementObj;

@end
