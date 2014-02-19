//
//  FriendCell.h
//  XboxBuddy
//
//  Created by Christine Wang on 2/4/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Profile.h"

@interface FriendCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *gamerImage;
@property (strong, nonatomic) IBOutlet UILabel *gamerTag;

@property (weak, nonatomic) IBOutlet UILabel *lastPlayedDetail;


-(void)initWithProfile:(Profile *)profileObj;


@end
