//
//  CommentCell.h
//  XboxBuddy
//
//  Created by Amber Roy on 2/26/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comment.h"

@interface CommentCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *authorImage;
@property (weak, nonatomic) IBOutlet UILabel *authorGamertag;
@property (weak, nonatomic) IBOutlet UILabel *content;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property Comment *commentObj;

- (CommentCell *)initWithComment:(Comment *)commentObj;

@end
