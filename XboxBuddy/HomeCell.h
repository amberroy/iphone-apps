//
//  HomeCell.h
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HomeCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *userImage;
@property (strong, nonatomic) IBOutlet UILabel *userName;
@property (strong, nonatomic) IBOutlet UILabel *userScreenName;
@property (strong, nonatomic) IBOutlet UILabel *gameAchievement;
@property (strong, nonatomic) IBOutlet UILabel *timestamp;

@end
