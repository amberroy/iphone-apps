//
//  AchievementCell.m
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "AchievementCell.h"
#import "Achievement.h"
#import "AchievementCellContentView.h"

@interface AchievementCell ()

@property Achievement *achievementObj;
@property AchievementCellContentView *cellContentView;

@end

@implementation AchievementCell

-(void)awakeFromNib {
    [super awakeFromNib];
    [self setupContent];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupContent];
    }
    return self;
}

-(void)setupContent {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSArray *views = [mainBundle loadNibNamed:@"AchievementCellContentView"
                                        owner:self
                                      options:nil];
    self.cellContentView = (AchievementCellContentView *)views[0];
    [self.scrollViewContentView addSubview:self.cellContentView];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)initWithAchievement:(Achievement *)achievementObj
{
    if (achievementObj.gamertag) {
        self.achievementObj = achievementObj;
    }
    [super setAchievementObj:achievementObj];
    [self.cellContentView initWithAchievement:achievementObj];
    
}

@end
