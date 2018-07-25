/**
 *
 * Copyright 2015 Rishat Shamsutdinov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#import "RSPagedItemsScrollViewDelegateProxy.h"
#import "RSScrollViewDelegate.h"

@interface RSPagedItemsScrollViewDelegateProxy () <RSScrollViewDelegate> {
    id<UIScrollViewDelegate> __weak _target;

    CGPoint _prevTopContentOffset;
    CGPoint _prevBottomContentOffset;
    CGPoint _prevLeftContentOffset;
    CGPoint _prevRightContentOffset;

    NSMapTable<NSString *, NSMethodSignature *> *_methodSignaturesCache;
}

@end

@implementation RSPagedItemsScrollViewDelegateProxy

+ (instancetype)proxyWithTarget:(id<UIScrollViewDelegate>)target
                       delegate:(id<RSPagedItemsScrollViewDelegateProxyDelegate>)delegate
{
    RSPagedItemsScrollViewDelegateProxy *proxy = [[self alloc] initWithTarget:target];

    proxy.delegate = delegate;

    return proxy;
}

- (instancetype)initWithTarget:(id<UIScrollViewDelegate>)target {
    _target = target;
    _methodSignaturesCache = [NSMapTable strongToStrongObjectsMapTable];

    return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:_target];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if (!_target) {
        return [[self class] instanceMethodSignatureForSelector:sel];
    }

    NSString *key = NSStringFromSelector(sel);
    NSMethodSignature *methodSig = [_methodSignaturesCache objectForKey:key];

    if (!methodSig) {
        methodSig = [(NSObject *)_target methodSignatureForSelector:sel];

        [_methodSignaturesCache setObject:methodSig forKey:key];
    }

    return methodSig;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return ([_target respondsToSelector:aSelector] ||
            aSelector == @selector(scrollViewDidScroll:) ||
            aSelector == @selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:) ||
            aSelector == @selector(scrollViewDidScrollToTop:) ||
            aSelector == @selector(scrollViewShouldScrollToTop:) ||
            aSelector == @selector(scrollViewDidEndDecelerating:) ||
            aSelector == @selector(rs_scrollViewDidChangeContentSize:));
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.decelerating) {
        [self handleContentOffset:scrollView.contentOffset ofScrollView:scrollView];
    }

    if ([_target respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [_target scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {

    if ([_target respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [_target scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }

    if (velocity.y) {
        [self handleContentOffset:*targetContentOffset ofScrollView:scrollView];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    BOOL shouldScrollToTop = YES;

    if ([_target respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
        shouldScrollToTop = [_target scrollViewShouldScrollToTop:scrollView];
    }

    if (shouldScrollToTop) {
        _prevTopContentOffset = _prevBottomContentOffset = scrollView.contentOffset;
    }

    return shouldScrollToTop;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self handleContentOffset:scrollView.contentOffset ofScrollView:scrollView];

    if ([_target respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        [_target scrollViewDidScrollToTop:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self handleContentOffset:scrollView.contentOffset ofScrollView:scrollView];

    if ([_target respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [_target scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)rs_scrollViewDidChangeContentSize:(UIScrollView *)scrollView {
    [self handleContentOffset:scrollView.contentOffset ofScrollView:scrollView forced:YES];

    if ([_target respondsToSelector:@selector(rs_scrollViewDidChangeContentSize:)]) {
        [(id<RSScrollViewDelegate>)_target rs_scrollViewDidChangeContentSize:scrollView];
    }
}

- (void)handleContentOffset:(CGPoint)contentOffset ofScrollView:(UIScrollView *)scrollView {
    [self handleContentOffset:contentOffset ofScrollView:scrollView forced:NO];
}

- (void)handleContentOffset:(CGPoint)contentOffset ofScrollView:(UIScrollView *)scrollView forced:(BOOL)forced {
    id delegate = self.delegate;

    if (![delegate respondsToSelector:@selector(scrollView:willScrollToEdges:)]) {
        return;
    }

    CGSize contentSize = scrollView.contentSize;
    CGFloat scrollViewHeight = scrollView.bounds.size.height;
    CGFloat scrollViewWidth = scrollView.bounds.size.width;

    RSScrollViewEdges edges = kNilOptions;

    if (contentOffset.y <= scrollViewHeight && (forced || contentOffset.y - _prevTopContentOffset.y < 0)) {
        edges |= RSScrollViewEdgesTop;

        _prevTopContentOffset = CGPointMake(contentOffset.x, -scrollView.contentInset.top);
    }

    if (contentOffset.y >= (contentSize.height - scrollViewHeight * 2) &&
        (forced || contentOffset.y - _prevBottomContentOffset.y > 0))
    {
        edges |= RSScrollViewEdgesBottom;

        _prevBottomContentOffset = CGPointMake(contentOffset.x,
                                               contentSize.height - scrollViewHeight + scrollView.contentInset.bottom);
    }

    if (contentOffset.x <= scrollViewWidth && (forced || contentOffset.x - _prevLeftContentOffset.x < 0)) {
        edges |= RSScrollViewEdgesLeft;

        _prevLeftContentOffset = CGPointMake(-scrollView.contentInset.left, contentOffset.y);
    }

    if (contentOffset.x >= (contentSize.width - scrollViewWidth * 2) &&
        (forced || contentOffset.x - _prevRightContentOffset.x > 0))
    {
        edges |= RSScrollViewEdgesRight;

        _prevRightContentOffset = CGPointMake(contentSize.width - scrollViewWidth + scrollView.contentInset.right,
                                              contentOffset.y);
    }

    if (edges != kNilOptions) {
        [delegate scrollView:scrollView willScrollToEdges:edges];
    }
}

@end
