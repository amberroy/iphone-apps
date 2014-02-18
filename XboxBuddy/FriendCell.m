//
//  FriendCell.m
//  XboxBuddy
//
//  Created by Christine Wang on 2/4/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "FriendCell.h"
#import "Profile.h"

@interface FriendCell ()

@property Profile *profileObj;

@end

@implementation FriendCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initWithProfile:(Profile *)profileObj
{
    self.profileObj = profileObj;
    UIImage *gamerpicImage;
    NSString *gamerpicPath = [XboxLiveClient filePathForImageUrl:profileObj.gamerpicImageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:gamerpicPath]) {
        gamerpicImage = [UIImage imageWithContentsOfFile:gamerpicPath];
    } else {
        NSLog(@"Gamerpic image not found, using placeholder instead of %@", gamerpicPath);
        gamerpicImage = [UIImage imageNamed:@"TempGamerImage.png"];
    }
    self.gamerImage.image = gamerpicImage;
    
    self.gamerTag.text = profileObj.gamertag;
    self.gameName.text = profileObj.gameName;
    self.gamerscore.text = [NSString stringWithFormat:@"%i G", profileObj.gamerscore];
    self.achievementEarnedOn.text = [Achievement timeAgoWithDate:profileObj.achievementEarnedOn];
}

@end
