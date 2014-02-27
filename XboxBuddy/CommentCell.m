//
//  CommentCell.m
//  XboxBuddy
//
//  Created by Amber Roy on 2/26/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "CommentCell.h"

@interface CommentCell ()

@property Comment *commentObj;

@end

@implementation CommentCell

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

- (CommentCell *)initWithComment:(Comment *)commentObj
{
    self.commentObj = commentObj;
    UIImage *authorImage;
    NSString *authorImagePath = [XboxLiveClient filePathForImageUrl:commentObj.authorImageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:authorImagePath]) {
        authorImage = [UIImage imageWithContentsOfFile:authorImagePath];
    } else {
        NSLog(@"Author image image not found, using placeholder instead of %@", authorImage);
        authorImage = [UIImage imageNamed:@"TempGamerImage.png"];
    }
    self.authorImage.image = authorImage;
    
    self.content.text = commentObj.content;
    self.authorGamertag.text = commentObj.authorGamertag;
    self.timestamp.text = [Achievement timeAgoWithDate:commentObj.timestamp];
    
    return self;
}

@end
