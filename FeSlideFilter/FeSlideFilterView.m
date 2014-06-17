//
//  FeSlideFilterView.m
//  FeSlideFilter
//
//  Created by Nghia Tran on 6/11/14.
//  Copyright (c) 2014 Fe. All rights reserved.
//

#import "FeSlideFilterView.h"
typedef NS_ENUM(NSInteger, FeSlideFilterViewPosition) {
    FeSlideFilterViewPositionStart,
    FeSlideFilterViewPositionEnd,
    FeSlideFilterViewPositionMid
};
typedef NS_ENUM(NSInteger, FeSlideFilterViewState) {
    FeSlideFilterViewStateScrollingToLeft,
    FeSlideFilterViewStateScrollingToRight,
    FeSlideFilterViewStateNone
};

@interface FeSlideFilterView () <UIScrollViewDelegate>
{
    CGPoint startPoint;
}
// Front Layer
@property (strong, nonatomic) CALayer *frontLayer;

// Back Layer
@property (strong, nonatomic) CALayer *backLayer;

// Mask Layer
@property (strong, nonatomic) CALayer *maskLayer;

// Scroll View
@property (strong, nonatomic) UIScrollView *scrollView;

// Position
@property (assign, nonatomic) FeSlideFilterViewPosition currentPosition;

// State
@property (assign, nonatomic) FeSlideFilterViewState currentState;

/////////////////////
// Init
-(void) initCommon;
-(void) initFrontLayer;
-(void) initBackLayer;
-(void) initMaskLayer;
-(void) initScrollView;
-(void) configureSlideFilterView;
-(void) configureScrollView;
-(void) configureLayer;

//////////////
// Verify
-(void) verify;
@end

@implementation FeSlideFilterView

#pragma mark - Init
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initCommon];
        
        [self initFrontLayer];
        
        [self initBackLayer];
        
        [self initMaskLayer];
        
        [self initScrollView];
        
        [self configureSlideFilterView];
    }
    return self;
}
-(void) initCommon
{
    _currentIndex = 0;
    _currentPosition = FeSlideFilterViewPositionStart;
    _currentState = FeSlideFilterViewStateNone;
    
}
-(void) initFrontLayer
{
    // Front
    _frontLayer = [CALayer layer];
    _frontLayer.frame = self.bounds;
    
    // Add sublayer
    [self.layer addSublayer:_frontLayer];
}
-(void) initBackLayer
{
    // Back
    _backLayer = [CALayer layer];
    _backLayer.frame = self.bounds;
    
    // Add sublayer
    [self.layer insertSublayer:_backLayer below:_frontLayer];
}
-(void) initMaskLayer
{
    _maskLayer = [CALayer layer];
    _maskLayer.frame = self.bounds;
    _maskLayer.backgroundColor = [UIColor whiteColor].CGColor;
    _maskLayer.anchorPoint = CGPointMake(0, 0);
    _maskLayer.position = CGPointMake(0, 0);
    
    _frontLayer.mask = _maskLayer;
}
-(void) initScrollView
{
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.backgroundColor = [UIColor clearColor];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.delegate = self;
    
    [self addSubview:_scrollView];
}
-(void) configureSlideFilterView
{
    // Verify
    [self verify];
    
    // Number of filter
    _numberOfFilter = [_dataSource numberOfFilter];
    
    // ScrollView
    [self configureScrollView];
    
    // Layer and mask
    [self configureLayer];
}
-(void) configureScrollView
{
    CGRect frame = self.bounds;
    
    // Content size
    _scrollView.contentSize = CGSizeMake(frame.size.width * _numberOfFilter, frame.size.height);
    
    // Create title lable
    for (NSInteger i = 0 ; i < _numberOfFilter; i++)
    {
        CGRect frameLabel = CGRectMake(frame.size.width * i, 0, frame.size.width, frame.size.height);
        UILabel *titleFilter = [[UILabel alloc] initWithFrame:frameLabel];
        titleFilter.backgroundColor = [UIColor clearColor];
        titleFilter.textAlignment = NSTextAlignmentCenter;
        titleFilter.textColor = [UIColor whiteColor];
        
        // Font
        titleFilter.font = [_dataSource FeSlideFilterView:self fontForTitleAtIndex:i];
        
        // Title
        titleFilter.text = [_dataSource FeSlideFilterView:self titleFilterAtIndex:i];
        
        // Subview
        [_scrollView addSubview:titleFilter];
    }
    
    //Paging
    _scrollView.pagingEnabled = YES;
    
    [self addSubview:_scrollView];
}
-(void) configureLayer
{
    if (_currentIndex == 0 && _currentPosition == FeSlideFilterViewPositionStart)
    {
        // Front
        UIImage *originalImage = [_dataSource imageOriginal];
        _frontLayer.contents = (id)originalImage.CGImage;
        
        // Back
        UIImage *nextImage = [_dataSource FeSlideFilterView:self imageAfterFilterAtIndex:_currentIndex + 1];
        _backLayer.contents = (id) nextImage.CGImage;
        
        // mask
        _maskLayer.position = CGPointMake(0, 0);
        
    }
}
-(void) verify
{
    NSAssert(_dataSource, @"Data source is nil");
    NSAssert([_dataSource conformsToProtocol:@protocol(FeSlideFilterViewDataSource)], @"You must comform Data Source");
    NSAssert([_dataSource respondsToSelector:@selector(numberOfFilter)], @"You must implement NumberOfFilter method");
    NSAssert([_dataSource respondsToSelector:@selector(FeSlideFilterView:imageAfterFilterAtIndex:)], @"You must implement FeSlideFilterView:imageAfterFilterAtIndex: method");
    NSAssert([_dataSource respondsToSelector:@selector(FeSlideFilterView:titleFilterAtIndex:)], @"You must implement FeSlideFilterView:titleFilterAtIndex: method");
    NSAssert([_dataSource respondsToSelector:@selector(imageOriginal)], @"You must implement imageOriginal method");
}

#pragma mark - ScrollView Delegate
-(void) scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    CGPoint velocity = [_scrollView.panGestureRecognizer velocityInView:self];
    
    if (_currentIndex == 0 && _currentPosition == FeSlideFilterViewPositionStart && _currentState == FeSlideFilterViewStateNone)
    {
        if (velocity.x < 0)
        {
            // Default
            _maskLayer.position = CGPointZero;
            
            // Position
            // State
            _currentState = FeSlideFilterViewStateScrollingToLeft;
            startPoint = [_scrollView.panGestureRecognizer locationInView:self];
            
        }
    }
}
-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint touchPoint = [_scrollView.panGestureRecognizer locationInView:_scrollView];
    
    if (_currentState == FeSlideFilterViewStateScrollingToLeft)
    {
        CGFloat denta =  scrollView.contentOffset.x - self.bounds.size.width * _currentIndex;
        CGFloat percent = denta / self.bounds.size.width;
        
        // Adjust mask's frame
        if (percent >= 0 && percent <= 1)
        {
            _maskLayer.frame = CGRectMake(0 - percent * self.bounds.size.width, 0, self.bounds.size.width, self.bounds.size.height);
        }
    }
}
-(void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
}
-(void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    
}
@end
