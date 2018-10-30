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

@property (nonatomic, strong) UIView *mainView;

@property (nonatomic, strong) NSMutableArray <RCCarouselViewItem *>*itemArray;
@property (nonatomic, assign) int currentIndex;
//@property (nonatomic, assign) BOOL isDecelerating;
@property (nonatomic, strong) RCCarouselViewItem *leftMostItem;
@property (nonatomic, strong) RCCarouselViewItem *rightMostItem;

@property (nonatomic, assign) CGPoint startGesturePoint;
@property (nonatomic, assign) CGPoint endGesturePoint;
@property (nonatomic, assign) CGFloat currentGestureVelocity;
@property (nonatomic, assign) CGFloat parallaxFactor;
@property (nonatomic, assign) CGFloat bounceMargin;
@property (nonatomic, assign) BOOL loopFinished;
//@property (nonatomic, assign) CGFloat leftRightPadding;

@property (nonatomic, assign) CGFloat endX;
@property (nonatomic, assign) CGFloat beginX;

@end

@implementation RCCarouselView

- (instancetype)init {
    if (self = [super init]) {
        _defaultDistace = 35;
        _bounceMargin = 10;
        [self addSubview:self.mainView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.mainView.frame = self.bounds;
    if (_itemArray.count == 0) {
        [self configData];
    } else {
        [self refreshData];
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

- (void)refreshData {
    
}

- (void)resetData {
    
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
        
//        CGFloat factor = ((index + 1)/2) * pow(-1.0, (index + 1)%2 + 1);
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
//        if (index == _itemArray.count - 2) {
//            _leftMostItem = item;
//        } else if (index == _itemArray.count - 1) {
//            _rightMostItem = item;
//        }
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
    
//    BOOL detected = NO;
    
    for (int index = 0; index < _itemArray.count; index ++) {
//        if (_itemArray.firstObject.x >= _bounceMargin) {
//            detected = YES;
//            if (offset < 0 && _loopFinished) {
//                return;
//            }
//        }
//
//        if (_itemArray.lastObject.x <= -_bounceMargin) {
//            detected = YES;
//            if (offset > 0 && _loopFinished) {
//                return;
//            }
//        }
        
        
        
        RCCarouselViewItem *item = _itemArray[index];
        item.x = item.x - offset;
        item.z = -fabs(item.x);
        CGFloat factor = [self getFactorForX:item.z];
        
        
//        if ([item isEqual:_leftMostItem]) {
//            NSLog(@"系数：%f, 偏移：%f", factor, offset);
//        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.33 animations:^{
                CATransform3D transform = CATransform3DIdentity;
                transform.m34 = -1.0/500;
                item.layer.transform = CATransform3DTranslate(transform, item.x * factor, 0.0, item.z);
            }];
        });
        
//        _loopFinished = (index == _itemArray.count - 1 && detected);
        
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
    if (fabs(movedX) < _defaultDistace) {//滑动距离小于一个距离就不移动到下个index
        oldIndex = self.currentIndex;
    } else {
        if (movedX < 0) {//往左滑了
            if (oldIndex == _itemArray.count-1) {
                oldIndex = 0;
            } else {
                oldIndex ++;
            }
            shouldChange = YES;
            leftToRight = NO;
            
        } else if (movedX > 0) {//往右滑了
            if (oldIndex == 0) {
                oldIndex = (int)_itemArray.count - 1;
            } else {
                oldIndex --;
            }
            shouldChange = YES;
            leftToRight = YES;
            
        } else {//回到原处
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
    
//    [self refreshMostItemWithOldIndex:oldIndex];
    
    return;
//    _isDecelerating = YES;
    
//    CGFloat acceleration = -_currentGestureVelocity * 25;
//    CGFloat distance = acceleration == 0 ? 0 : (-pow(_currentGestureVelocity, 2.0) / (2.0 * acceleration));
//    NSLog(@"distance:%lf", distance);
//    CGFloat offsetItems = _itemArray.firstObject.x;
//    CGFloat endOffsetItems = distance + offsetItems;
//    int oldIndex = self.currentIndex;
//    self.currentIndex = -(int)(round(endOffsetItems / _defaultDistace));
//    _isDecelerating = NO;
    
//    for (RCCarouselViewItem *item in _itemArray) {
//        if (distance > 0) {//从左往右滑
//            if ([item isEqual:_rightMostItem]) {
//
//                item.x = self.leftMostItem.x - _defaultDistace;
//                item.z = -fabs(item.x);
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [UIView animateWithDuration:0.33 animations:^{
//                        CATransform3D transform = CATransform3DIdentity;
//                        transform.m34 = -1.0/500;
//                        item.layer.transform = CATransform3DTranslate(transform, item.x, 0.0, item.z);
//                    } completion:^(BOOL finished) {
//
//                        self.leftMostItem = item;
//
//                        NSInteger newRightIndex = [self.itemArray indexOfObject:item] - 1;
//                        newRightIndex = newRightIndex < 0 ? self.itemArray.count - 1 : newRightIndex;
//                        //                        newRightIndex = newRightIndex > self.itemArray.count - 1 ? 0 : newRightIndex;
//                        self.rightMostItem = self.itemArray[newRightIndex];
//                    }];
//                });
//            }
//        } else {//从右往左滑
//            if ([item isEqual:_leftMostItem]) {
//                item.x = self.rightMostItem.x + _defaultDistace;
//                item.z = -fabs(item.x);
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [UIView animateWithDuration:0.33 animations:^{
//                        CATransform3D transform = CATransform3DIdentity;
//                        transform.m34 = -1.0/500;
//                        item.layer.transform = CATransform3DTranslate(transform, item.x, 0.0, item.z);
//                    } completion:^(BOOL finished) {
//
//                        self.rightMostItem = item;
//
//                        NSInteger newLeftIndex = [self.itemArray indexOfObject:item] + 1;
//                        newLeftIndex = newLeftIndex > self.itemArray.count - 1 ? 0 : newLeftIndex;
//                        //                        newLeftIndex = newLeftIndex < 0 ? self.itemArray.count - 1 : newLeftIndex;
//                        self.leftMostItem = self.itemArray[newLeftIndex];
//                    }];
//                });
//            }
//        }
//    }
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self refreshMostItemWithOldIndex:oldIndex];
//    });
    
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

//- (void)refreshMostItemWithOldIndex:(int)oldIndex {
//    NSLog(@"--%d---%d", oldIndex, self.currentIndex);
//    if (oldIndex == self.currentIndex || self.currentIndex < 0) {
//        return;
//    }
//    BOOL leftToRightScroll = NO;
//        if (oldIndex > self.currentIndex || (oldIndex == 0 && self.currentIndex == _itemArray.count - 1)) {
//            leftToRightScroll = YES;
//        }
//        if (oldIndex < self.currentIndex || (oldIndex == _itemArray.count - 1 && self.currentIndex == 0)) {
//            leftToRightScroll = NO;
//        }
////    RCCarouselViewItem *currenItem = _itemArray[self.currentIndex];
////    int leftCount = 0;
////    int rightCount = 0;
////    for (RCCarouselViewItem *item in _itemArray) {
////        if (item.x < currenItem.x) {
////            leftCount ++;
////        } else if (item.x > currenItem.x) {
////            rightCount ++;
////        }
////    }
////    leftToRightScroll = rightCount > leftCount;
//    for (RCCarouselViewItem *item in _itemArray) {
//        if (leftToRightScroll) {//从左往右滑
//            if ([item isEqual:_rightMostItem]) {
//
//                item.x = self.leftMostItem.x - _defaultDistace;
//                item.z = -fabs(item.x);
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [UIView animateWithDuration:0.33 animations:^{
//                        CATransform3D transform = CATransform3DIdentity;
//                        transform.m34 = -1.0/500;
//                        item.layer.transform = CATransform3DTranslate(transform, item.x, 0.0, item.z);
//                    } completion:^(BOOL finished) {
//
//                        self.leftMostItem = item;
//
//                        NSInteger newRightIndex = [self.itemArray indexOfObject:item] - 1;
//                        newRightIndex = newRightIndex < 0 ? self.itemArray.count - 1 : newRightIndex;
//                        //                        newRightIndex = newRightIndex > self.itemArray.count - 1 ? 0 : newRightIndex;
//                        self.rightMostItem = self.itemArray[newRightIndex];
//                    }];
//                });
//            }
//        } else {//从右往左滑
//            if ([item isEqual:_leftMostItem]) {
//                item.x = self.rightMostItem.x + _defaultDistace;
//                item.z = -fabs(item.x);
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [UIView animateWithDuration:0.33 animations:^{
//                        CATransform3D transform = CATransform3DIdentity;
//                        transform.m34 = -1.0/500;
//                        item.layer.transform = CATransform3DTranslate(transform, item.x, 0.0, item.z);
//                    } completion:^(BOOL finished) {
//
//                        self.rightMostItem = item;
//
//                        NSInteger newLeftIndex = [self.itemArray indexOfObject:item] + 1;
//                        newLeftIndex = newLeftIndex > self.itemArray.count - 1 ? 0 : newLeftIndex;
//                        //                        newLeftIndex = newLeftIndex < 0 ? self.itemArray.count - 1 : newLeftIndex;
//                        self.leftMostItem = self.itemArray[newLeftIndex];
//                    }];
//                });
//            }
//        }
//    }
//}

- (void)setCurrentIndex:(int)currentIndex {
    _currentIndex = currentIndex;
    NSLog(@"real index:%d", currentIndex);
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
    NSLog(@"real offset:%lf--offsetItems:%lf", offsetToAdd, _leftMostItem.x);
    [self moveCarousel:offsetToAdd];
}

#pragma mark - gesture
- (void)tapGestureAction:(UITapGestureRecognizer *)tap {
    
}

- (void)panGestureAction:(UIPanGestureRecognizer *)pan {
    UIView *targetView = pan.view;
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            _currentGestureVelocity = 0;
            _startGesturePoint = [pan locationInView:targetView];
            _endX = 0;
            _beginX = _startGesturePoint.x;
        }
            break;
        case UIGestureRecognizerStateChanged: {
            _currentGestureVelocity = [pan velocityInView:targetView].x;
            _endGesturePoint = [pan locationInView:targetView];
            
            _endX = _endGesturePoint.x;
            
            CGFloat xOffset = (_startGesturePoint.x - _endGesturePoint.x) * (1 / _parallaxFactor);
            NSLog(@"_currentGestureVelocity:%lf, xOffset:%lf, _endGesturePoint:%lf=%lf",_currentGestureVelocity, xOffset, _endGesturePoint.x, _endGesturePoint.y);
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
