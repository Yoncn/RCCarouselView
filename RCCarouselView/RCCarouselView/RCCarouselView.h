//
//  RCCarouselView.h
//  RCCarouselView
//
//  Created by rong on 2018/10/23.
//  Copyright © 2018 rong. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RCCarouselViewItem, RCCarouselView;

@protocol RCCarouselViewDelegate <NSObject>
- (NSInteger)numberOfItemsInCarouselView;
- (RCCarouselViewItem *)carouselView:(RCCarouselView *)carouselView itemForRowAtIndex:(int)index;
- (void)carouselView:(RCCarouselView *)carouselView didSelectItemAtIndex:(int)index;
@end

@interface RCCarouselView : UIView
@property (nonatomic, weak) id<RCCarouselViewDelegate> delegate;
@property (nonatomic, assign) CGFloat defaultDistace;

@end

NS_ASSUME_NONNULL_END
