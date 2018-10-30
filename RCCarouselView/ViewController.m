//
//  ViewController.m
//  RCCarouselView
//
//  Created by rong on 2018/10/23.
//  Copyright © 2018 rong. All rights reserved.
//

#import "ViewController.h"
#import "RCCarouselView.h"
#import "RCCarouselViewItem.h"
#import "SDWebImage/UIImageView+WebCache.h"

@interface ViewController ()<RCCarouselViewDelegate>
@property (nonatomic, strong) RCCarouselView *carouselView;
@property (nonatomic, strong) NSArray *imageArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configUI];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _carouselView.frame = self.view.bounds;
}

- (void)configUI {
    _imageArray = @[@"https://ss1.baidu.com/9vo3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=504c7d57bd51f819ee25054aeab54a76/d6ca7bcb0a46f21fd757a52ffb246b600c33ae6f.jpg", @"https://ss1.baidu.com/-4o3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=047b418c923df8dcb93d8991fd1072bf/aec379310a55b3199f70cd0e4ea98226cffc173b.jpg", @"https://ss3.baidu.com/9fo3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=06f18776399b033b3388fada25cf3620/77c6a7efce1b9d162f210013fedeb48f8d5464da.jpg", @"https://ss1.baidu.com/-4o3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=ff937ebff1039245beb5e70fb795a4a8/b8014a90f603738d952a8450be1bb051f819ec64.jpg", @"https://ss2.baidu.com/-vo3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=72686833932f070840052c00d925b865/d8f9d72a6059252d21946778399b033b5ab5b9cf.jpg"];
    _carouselView = [[RCCarouselView alloc] init];
    _carouselView.delegate = self;
    [self.view addSubview:_carouselView];
    
}

- (void)carouselView:(nonnull RCCarouselView *)carouselView didSelectItemAtIndex:(int)index {
    NSLog(@"%d", index);
}

- (nonnull RCCarouselViewItem *)carouselView:(nonnull RCCarouselView *)carouselView itemForRowAtIndex:(int)index {
    RCCarouselViewItem *item = [[RCCarouselViewItem alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    item.orderNumber = index;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:item.bounds];
    [imageView sd_setImageWithURL:[NSURL URLWithString:_imageArray[index]]];
    [item addSubview:imageView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:item.bounds];
    label.text = [NSString stringWithFormat:@"%d", index];
    label.textAlignment = NSTextAlignmentCenter;
    [item addSubview:label];
    
    return item;
}

- (NSInteger)numberOfItemsInCarouselView {
    return _imageArray.count;
}


@end
