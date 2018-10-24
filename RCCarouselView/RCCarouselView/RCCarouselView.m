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
@property (nonatomic, assign) BOOL isDecelerating;

@property (nonatomic, assign) CGPoint startGesturePoint;
@property (nonatomic, assign) CGPoint endGesturePoint;
@property (nonatomic, assign) CGFloat currentGestureVelocity;
@property (nonatomic, assign) CGFloat parallaxFactor;
@property (nonatomic, assign) CGFloat bounceMargin;
@property (nonatomic, assign) BOOL loopFinished;

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
    [self reloadData];
}

#pragma mark - data

- (void)reloadData {
    if (self.delegate && [self.delegate respondsToSelector:@selector(numberOfItemsInCarouselView)] && [self.delegate respondsToSelector:@selector(carouselView:itemForRowAtIndex:)]) {
        NSInteger count = self.delegate.numberOfItemsInCarouselView;
        self.itemArray = [NSMutableArray arrayWithCapacity:count];
        for (int i = 0; i < count; i ++) {
            RCCarouselViewItem *item = [self.delegate carouselView:self itemForRowAtIndex:i];
            [self __addItem:item];
        }
        [self __refreshUIWithAnimate:YES];
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
        
        CGFloat factor = ((index + 1)/2) * pow(-1.0, (index + 1)%2 + 1);
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
        if (index == 0) {
            NSLog(@"系数：%f", factor);
        }
        
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
    _isDecelerating = YES;
    
    CGFloat acceleration = -_currentGestureVelocity * 25;
    CGFloat distance = acceleration == 0 ? 0 : (-pow(_currentGestureVelocity, 2.0) / (2.0 * acceleration));
    CGFloat offsetItems = _itemArray.firstObject.x;
    CGFloat endOffsetItems = distance + offsetItems;
    self.currentIndex = -(int)(round(endOffsetItems / _defaultDistace));
    
    _isDecelerating = NO;
}

- (void)setCurrentIndex:(int)currentIndex {
    [self __moveToIndex:currentIndex];
}

- (void)__moveToIndex:(int)index {
    CGFloat offsetItems = _itemArray.firstObject.x;
    CGFloat offsetToAdd = _defaultDistace * -index - offsetItems;
    [self moveCarousel:-offsetToAdd];
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
        }
            break;
        case UIGestureRecognizerStateChanged: {
            _currentGestureVelocity = [pan velocityInView:targetView].x;
            _endGesturePoint = [pan locationInView:targetView];
            
            CGFloat xOffset = (_startGesturePoint.x - _endGesturePoint.x) * (1 / _parallaxFactor);
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
