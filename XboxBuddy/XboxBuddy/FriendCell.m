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
    if (profileObj.recentGames) {
        Game *lastGame = profileObj.recentGames[0];
        NSString *gameName = lastGame.name;
        NSString *timestamp = [Achievement timeAgoWithDate:lastGame.lastPlayed];
        if ([timestamp rangeOfString:@"/"].location != NSNotFound) {
            // If timestamp is a date, display as "on 02/14/14"
            timestamp = [NSString stringWithFormat:@"on %@", timestamp];
        }
        self.lastPlayedDetail.text = [NSString stringWithFormat:@"Last played %@ %@.", gameName, timestamp];
    } else {
        self.lastPlayedDetail.text = @"Recent games not shared by player.";
    }
}

@end
