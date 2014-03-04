//
//  SwipeWithOptionsCell.m
//  XboxBuddy
//
//  Created by Christine Wang on 3/2/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "SwipeWithOptionsCell.h"

NSString *const SwipeWithOptionsCellEnclosingTableViewDidBeginScrollingNotification = @"SwipeWithOptionsCellEnclosingTableViewDidScrollNotification";

#define optionViewWidth 140

@interface SwipeWithOptionsCell () <UIScrollViewDelegate>

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIView *scrollViewButtonView;
@property (nonatomic, weak) UILabel *scrollViewLabel;

@end

@implementation SwipeWithOptionsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    UIColor *greenColor = [UIColor colorWithRed:0.0/255.0 green:147.0/255.0 blue:69.0/255.0 alpha:1.0];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
    scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds) + optionViewWidth, CGRectGetHeight(self.bounds));
    scrollView.delegate = self;
    scrollView.showsHorizontalScrollIndicator = NO;
    
    [self.contentView addSubview:scrollView];
    self.scrollView = scrollView;
    
    UIView *scrollViewButtonView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) - optionViewWidth, 0, optionViewWidth, CGRectGetHeight(self.bounds))];
    self.scrollViewButtonView = scrollViewButtonView;
    [self.scrollView addSubview:scrollViewButtonView];
    
    UIButton *likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    likeButton.backgroundColor = greenColor;
    likeButton.frame = CGRectMake(0, 0, optionViewWidth / 2.0f, CGRectGetHeight(self.bounds));
    [likeButton setImage:[UIImage imageNamed:@"icon_like.png"] forState:UIControlStateNormal];
    likeButton.imageEdgeInsets = UIEdgeInsetsMake(33, 25, 33, 7);
    [likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [likeButton addTarget:self action:@selector(userPressedLikeButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollViewButtonView addSubview:likeButton];
    self.likeButton = likeButton;
    
    UIButton *commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    commentButton.backgroundColor = greenColor;
    commentButton.frame = CGRectMake(optionViewWidth / 2.0f, 0, optionViewWidth / 2.0f, CGRectGetHeight(self.bounds));
    [commentButton setImage:[UIImage imageNamed:@"icon_comment.png"] forState:UIControlStateNormal];
    commentButton.imageEdgeInsets = UIEdgeInsetsMake(37, 17, 32, 22);
    [commentButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [commentButton addTarget:self action:@selector(userPressedCommentButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollViewButtonView addSubview:commentButton];
    self.commentButton = commentButton;
    
    UIView *scrollViewContentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
    scrollViewContentView.backgroundColor = [UIColor whiteColor];
    [self.scrollView addSubview:scrollViewContentView];
    self.scrollViewContentView = scrollViewContentView;
    
    UILabel *scrollViewLabel = [[UILabel alloc] initWithFrame:CGRectInset(self.scrollViewContentView.bounds, 10, 0)];
    self.scrollViewLabel = scrollViewLabel;
    [self.scrollViewContentView addSubview:scrollViewLabel];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedCell:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    tapGestureRecognizer.enabled = YES;
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.scrollViewContentView addGestureRecognizer:tapGestureRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enclosingTableViewDidScroll) name:SwipeWithOptionsCellEnclosingTableViewDidBeginScrollingNotification  object:nil];
}

- (void)enclosingTableViewDidScroll {
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}

#pragma mark - Private Methods 

- (void)userPressedCommentButton:(id)sender {
    [self.scrollView setContentOffset:CGPointZero animated:YES];
    [self.delegate cellDidSelectComment:self];
}

- (void)userPressedLikeButton:(id)sender {
    [self.delegate cellDidSelectLike:self];
}

- (void)userTappedCell:(id)sender {
    if (self.scrollView.contentOffset.x != 0) {
        [self.scrollView setContentOffset:CGPointZero animated:YES];
    } else {
        [self.delegate cellDidSelect:self];
    }
}

#pragma mark - Overridden Methods

- (void)layoutSubviews {
    [super layoutSubviews];

    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds) + optionViewWidth, CGRectGetHeight(self.bounds));
    self.scrollView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    self.scrollViewButtonView.frame = CGRectMake(CGRectGetWidth(self.bounds) - optionViewWidth, 0, optionViewWidth, CGRectGetHeight(self.bounds));
    self.scrollViewContentView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.scrollView setContentOffset:CGPointZero animated:NO];
}

// TODO: check if we still need this
-(UILabel *)textLabel {
    // Kind of a cheat to reduce our external dependencies
    return self.scrollViewLabel;
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    if (scrollView.contentOffset.x > optionViewWidth / 2) {
        targetContentOffset->x = optionViewWidth;
    } else {
        *targetContentOffset = CGPointZero;
        
        // Need to call this subsequently to remove flickering -- TODO: check why
        dispatch_async(dispatch_get_main_queue(), ^{
            [scrollView setContentOffset:CGPointZero animated:YES];
        });
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.x < 0) {
        scrollView.contentOffset = CGPointZero;
    }
    self.scrollViewButtonView.frame = CGRectMake(scrollView.contentOffset.x + (CGRectGetWidth(self.bounds) - optionViewWidth), 0.0f, optionViewWidth, CGRectGetHeight(self.bounds));
}

@end

#undef optionViewWidth