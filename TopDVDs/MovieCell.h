//
//  MovieCell.h
//  TopDVDs
//
//  Created by Amber Roy on 1/19/14.
//  Copyright (c) 2014 Amber Roy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MovieCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *synopsisLabel;
@property (weak, nonatomic) IBOutlet UILabel *castLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end
