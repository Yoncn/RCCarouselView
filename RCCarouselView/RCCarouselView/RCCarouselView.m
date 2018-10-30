//
//  RCCarouselView.m
//  RCCarouselView
//
//  Created by rong on 2018/10/23.
//  Copyright © 2018 rong. All rights reserved.
//

#import "RCCarouselView.h"
#import "RCCarouselViewItem.h"

@interface RCCarouselView ()

/*
 
 Initial order state(Take 5 for example):
 
 0              4
    1       3
        2
*/

@property (nonatomic, strong) UIView *mainView;

@property (nonatomic, strong) NSMutableArray <RCCarouselViewItem *>*itemArray;
@property (nonatomic, assign) int currentIndex;

@property (nonatomic, strong) RCCarouselViewItem *leftMostItem;
@property (nonatomic, strong) RCCarouselViewItem *rightMostItem;

@property (nonatomic, assign) CGPoint startGesturePoint;
@property (nonatomic, assign) CGPoint endGesturePoint;
@property (nonatomic, assign) CGFloat parallaxFactor;

@property (nonatomic, assign) CGFloat beginX;
@property (nonatomic, assign) CGFloat endX;

@end

@implementation RCCarouselView

- (instancetype)init {
    if (self = [super init]) {
        _defaultDistace = 35;
        [self addSubview:self.mainView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.mainView.frame = self.bounds;
    if (_itemArray.count == 0) {
        [self configData];
    }
}

#pragma mark - data

- (void)configData {
    if (self.delegate && [self.delegate respondsToSelector:@selector(numberOfItemsInCarouselView)] && [self.delegate respondsToSelector:@selector(carouselView:itemForRowAtIndex:)]) {
        NSInteger count = self.delegate.numberOfItemsInCarouselView;
        self.itemArray = [NSMutableArray arrayWithCapacity:count];
        for (int i = 0; i < count; i ++) {
            RCCarouselViewItem *item = [self.delegate carouselView:self itemForRowAtIndex:i];
            [self __addItem:item];
        }
        [self __refreshUIWithAnimate:YES];
        self.currentIndex = (int)count/2;
    } else {
        NSLog(@"__configData delegate not exist");
    }
}

#pragma mark - UI

- (void)__addItem:(RCCarouselViewItem *)item {
    _parallaxFactor = (item.bounds.size.width + 10) / _defaultDistace;
    item.center = self.mainView.center;
    [self.itemArray insertObject:item atIndex:item.orderNumber];
    [self.mainView.layer insertSublayer:item.layer atIndex:item.orderNumber];
    
}

- (void)__refreshUIWithAnimate:(BOOL)animated {
    if (_itemArray.count == 0) {
        return;
    }
    
    for (int index = 0; index < _itemArray.count; index ++) {
        
        RCCarouselViewItem *item = _itemArray[index];
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        CGFloat factor = index;
        CGFloat xDistance = _defaultDistace * factor;
        CGFloat zDistance = round(-fabs(xDistance));
        
        CABasicAnimation *xAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
        xAnimation.fromValue = @(item.x);
        xAnimation.toValue = @(xDistance);
        
        CABasicAnimation *zAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.z"];
        zAnimation.fromValue = @(item.z);
        zAnimation.toValue = @(zDistance);
        
        CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
        animationGroup.duration = animated ? 0.33 : 0;
        animationGroup.repeatCount = 1;
        animationGroup.animations = @[xAnimation, zAnimation];
        animationGroup.removedOnCompletion = false;
        animationGroup.fillMode = kCAFillModeRemoved;
        animationGroup.timingFunction = [CAMediaTimingFunction functionWithName:@"easeInEaseOut"];
        [item.layer addAnimation:animationGroup forKey:@"myAnimation"];
        
        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = -1.0/500.0;
        transform = CATransform3DTranslate(transform, xDistance, 0.0, zDistance);
        item.layer.transform = transform;
        
        item.x = xDistance;
        item.z = zDistance;

        if (index == 0) {
            _leftMostItem = item;
        } else if (index == _itemArray.count - 1) {
            _rightMostItem = item;
        }
        
        [CATransaction commit];
    }
}


#pragma mark - action
- (void)moveCarousel:(CGFloat)offset {
    if (offset == 0) {
        return;
    }
    
    for (int index = 0; index < _itemArray.count; index ++) {
        
        RCCarouselViewItem *item = _itemArray[index];
        item.x = item.x - offset;
        item.z = -fabs(item.x);
        CGFloat factor = [self getFactorForX:item.z];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.33 animations:^{
                CATransform3D transform = CATransform3DIdentity;
                transform.m34 = -1.0/500;
                item.layer.transform = CATransform3DTranslate(transform, item.x * factor, 0.0, item.z);
            }];
        });
    }
    
}

- (CGFloat)getFactorForX:(CGFloat)x {
    
    CGPoint pA = CGPointMake(_defaultDistace*1.0/2, _parallaxFactor);
    CGPoint pB = CGPointMake(_defaultDistace, 1);
    
    CGFloat m = (pB.y - pA.y) / (pB.x - pA.x);
    CGFloat y = (pA.y - m * pA.x) + m * fabs(x);
    CGFloat absX = fabs(x);
    if (absX >= 0 && absX < _defaultDistace/2) {
        return _parallaxFactor;
    } else if (absX >= _defaultDistace/2 && absX < _defaultDistace) {
        return y;
    } else {
        return 1;
    }
}

- (void)startDecelerating {
    
    NSLog(@"beginx:%lf, endx:%lf", _beginX, _endX);
    
    CGFloat movedX = _endX - _beginX;
    int oldIndex = self.currentIndex;
    BOOL shouldChange = NO;
    BOOL leftToRight = NO;
    if (fabs(movedX) < _defaultDistace) {//scroll distance < _defaultDistace, not change currentIndex
        oldIndex = self.currentIndex;
    } else {
        if (movedX < 0) {//right to left scroll
            if (oldIndex == _itemArray.count-1) {
                oldIndex = 0;
            } else {
                oldIndex ++;
            }
            shouldChange = YES;
            leftToRight = NO;
            
        } else if (movedX > 0) {//left to right scroll
            if (oldIndex == 0) {
                oldIndex = (int)_itemArray.count - 1;
            } else {
                oldIndex --;
            }
            shouldChange = YES;
            leftToRight = YES;
            
        } else {
            oldIndex = self.currentIndex;
        }
    }
    
    self.currentIndex = oldIndex;
    
    if (shouldChange) {
        if (leftToRight) {
            [self refreshItemIfLeftToRightScroll];
        } else {
            [self refreshItemIfRightToLeftScroll];
        }
    }

}

- (void)refreshItemIfLeftToRightScroll {
    for (RCCarouselViewItem *item in _itemArray) {
        if ([item isEqual:_rightMostItem]) {
            item.x = self.leftMostItem.x - _defaultDistace;
            item.z = -fabs(item.x);
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.33 animations:^{
                    CATransform3D transform = CATransform3DIdentity;
                    transform.m34 = -1.0/500;
                    item.layer.transform = CATransform3DTranslate(transform, item.x, 0.0, item.z);
                } completion:^(BOOL finished) {
                    self.leftMostItem = item;
                    
                    NSInteger newRightIndex = [self.itemArray indexOfObject:item] - 1;
                    newRightIndex = newRightIndex < 0 ? self.itemArray.count - 1 : newRightIndex;
                    self.rightMostItem = self.itemArray[newRightIndex];
                }];
            });
        }
    }
}

- (void)refreshItemIfRightToLeftScroll {
    for (RCCarouselViewItem *item in _itemArray) {
        if ([item isEqual:_leftMostItem]) {
            item.x = self.rightMostItem.x + _defaultDistace;
            item.z = -fabs(item.x);
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.33 animations:^{
                    CATransform3D transform = CATransform3DIdentity;
                    transform.m34 = -1.0/500;
                    item.layer.transform = CATransform3DTranslate(transform, item.x, 0.0, item.z);
                } completion:^(BOOL finished) {
                    self.rightMostItem = item;
                    
                    NSInteger newLeftIndex = [self.itemArray indexOfObject:item] + 1;
                    newLeftIndex = newLeftIndex > self.itemArray.count - 1 ? 0 : newLeftIndex;
                    self.leftMostItem = self.itemArray[newLeftIndex];
                }];
            });
        }
    }
}

- (void)setCurrentIndex:(int)currentIndex {
    _currentIndex = currentIndex;
    NSLog(@"setCurrentIndex:%d", currentIndex);
    [self __moveToIndex:currentIndex];
}

- (void)__moveToIndex:(int)index {
    int offsetIndex = 0;
    if (index >= _leftMostItem.orderNumber) {
        offsetIndex = index - _leftMostItem.orderNumber;
    } else {
        offsetIndex = index + (int)_itemArray.count - _leftMostItem.orderNumber;
    }
    
    CGFloat offsetToAdd = _leftMostItem.x + _defaultDistace * offsetIndex;
    NSLog(@"__moveToIndex offset:%lf--offsetItems:%lf", offsetToAdd, _leftMostItem.x);
    [self moveCarousel:offsetToAdd];
}

#pragma mark - gesture
- (void)tapGestureAction:(UITapGestureRecognizer *)tap {
    
}

- (void)panGestureAction:(UIPanGestureRecognizer *)pan {
    UIView *targetView = pan.view;
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            _startGesturePoint = [pan locationInView:targetView];
            _endX = 0;
            _beginX = _startGesturePoint.x;
        }
            break;
        case UIGestureRecognizerStateChanged: {
            _endGesturePoint = [pan locationInView:targetView];
            
            _endX = _endGesturePoint.x;
            
            CGFloat xOffset = (_startGesturePoint.x - _endGesturePoint.x) * (1 / _parallaxFactor);
            NSLog(@" xOffset:%lf, _endGesturePoint:%lf=%lf", xOffset, _endGesturePoint.x, _endGesturePoint.y);
            [self moveCarousel:xOffset];
            _startGesturePoint = _endGesturePoint;
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded: {
            [self startDecelerating];
            }
            break;
        default:
            break;
    }
}

#pragma mark - lazyload

- (UIView *)mainView {
    if (!_mainView) {
        _mainView = [[UIView alloc] initWithFrame:CGRectZero];
        _mainView.backgroundColor = [UIColor whiteColor];
        _mainView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
        [_mainView addGestureRecognizer:tap];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        [_mainView addGestureRecognizer:pan];
    }
    return _mainView;
}

@end
