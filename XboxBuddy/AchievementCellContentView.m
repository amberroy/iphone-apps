//
//  AchievementCellContentView.m
//  XboxBuddy
//
//  Created by Christine Wang on 3/2/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "AchievementCellContentView.h"

@implementation AchievementCellContentView

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    // TODO: add this back in in place of loading nib in Achievement cell
    // Figure out why this crashes
    /*
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSArray *views = [mainBundle loadNibNamed:@"AchievementCellContentView"
                                        owner:nil
                                      options:nil];
    [self addSubview:views[0]];
    */
}

-(void)initWithAchievement:(Achievement *)achievementObj {
    
    if (!achievementObj.gamertag) {
        self.gamerTag.text = nil;
        self.achievementPoints.text = nil;
        self.gameName.text = nil;
        self.achievementEarnedOn.text = nil;
        return;
    }
    
    UIImage *gamerpicImage;
    NSString *gamerpicPath = [XboxLiveClient filePathForImageUrl:achievementObj.gamerpicImageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:gamerpicPath]) {
        gamerpicImage = [UIImage imageWithContentsOfFile:gamerpicPath];
    } else {
        NSLog(@"Gamerpic image not found, using placeholder instead of %@", gamerpicPath);
        gamerpicImage = [UIImage imageNamed:@"TempGamerImage.png"];
    }
    self.gamerImage.image = gamerpicImage;
    
    UIImage *achievemntImage;
    NSString *achievementPath = [XboxLiveClient filePathForImageUrl:achievementObj.imageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:achievementPath]) {
        achievemntImage = [UIImage imageWithContentsOfFile:achievementPath];
    } else {
        NSLog(@"Achievemnt image not found, using placeholder instead of %@", gamerpicPath);
        achievemntImage = [UIImage imageNamed:@"TempAchievementImage.png"];
    }
    self.achievementImage.image = achievemntImage;
    
    self.gamerTag.text = achievementObj.gamertag;
    self.achievementPoints.text = [NSString stringWithFormat:@"%ld G achievement", achievementObj.points];
    self.gameName.text = [NSString stringWithFormat:@"%@", achievementObj.game.name];
    self.achievementEarnedOn.text = [Achievement timeAgoWithDate:achievementObj.earnedOn];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
