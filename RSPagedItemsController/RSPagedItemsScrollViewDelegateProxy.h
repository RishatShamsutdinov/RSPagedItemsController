//
//  RSPagedItemsScrollViewDelegateProxy.h
//  RSPagedItemsController
//
//  Created by rishat on 04.08.15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "RSPagedItemsTypes.h"

@protocol RSPagedItemsScrollViewDelegateProxyDelegate;

@interface RSPagedItemsScrollViewDelegateProxy : NSProxy

@property (nonatomic, weak) id<RSPagedItemsScrollViewDelegateProxyDelegate> delegate;

+ (instancetype)proxyWithTarget:(id<UIScrollViewDelegate>)target
                       delegate:(id<RSPagedItemsScrollViewDelegateProxyDelegate>)delegate;

- (instancetype)initWithTarget:(id<UIScrollViewDelegate>)target;

@end

@protocol RSPagedItemsScrollViewDelegateProxyDelegate <NSObject>
@optional

- (void)scrollView:(UIScrollView *)scrollView willScrollToEdge:(RSScrollViewEdge)edge;

@end