//
//  SwipeWithOptionsCell.h
//  XboxBuddy
//
//  Created by Christine Wang on 3/2/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SwipeWithOptionsCell;

@protocol SwipeWithOptionsCellDelegate <NSObject>

-(void)cellDidSelectComment:(SwipeWithOptionsCell *)cell;
-(void)cellDidSelectLike:(SwipeWithOptionsCell *)cell;
-(void)cellDidSelect:(SwipeWithOptionsCell *)cell;

@end

extern NSString *const SwipeWithOptionsCellEnclosingTableViewDidBeginScrollingNotification;

@interface SwipeWithOptionsCell : UITableViewCell

@property (nonatomic, weak) id<SwipeWithOptionsCellDelegate> delegate;
@property (nonatomic, weak) UIView *scrollViewContentView;
@property (nonatomic, weak) UIButton *likeButton;
@property (nonatomic, weak) UIButton *commentButton;

@end
