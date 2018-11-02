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

    CGPoint _prevTopInvertedContentOffset;
    CGPoint _prevBottomContentOffset;
    CGPoint _prevLeftInvertedContentOffset;
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
        [self pRS_PISVDP_handleContentOffset:scrollView.contentOffset ofScrollView:scrollView];
    }

    if ([_target respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [_target scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if ([_target respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [_target scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }

    if (velocity.x || velocity.y) {
        [self pRS_PISVDP_handleContentOffset:*targetContentOffset ofScrollView:scrollView];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    BOOL shouldScrollToTop = YES;

    if ([_target respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
        shouldScrollToTop = [_target scrollViewShouldScrollToTop:scrollView];
    }

    if (shouldScrollToTop) {
        _prevBottomContentOffset = scrollView.contentOffset;
        _prevTopInvertedContentOffset = [self pRS_PISVDP_invertedContentOffsetForScrollView: scrollView
                                                                              contentOffset: scrollView.contentOffset];
    }

    return shouldScrollToTop;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self pRS_PISVDP_handleContentOffset:scrollView.contentOffset ofScrollView:scrollView];

    if ([_target respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        [_target scrollViewDidScrollToTop:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self pRS_PISVDP_handleContentOffset:scrollView.contentOffset ofScrollView:scrollView];

    if ([_target respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [_target scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)rs_scrollViewDidChangeContentSize:(UIScrollView *)scrollView {
    [self pRS_PISVDP_handleContentOffset:scrollView.contentOffset ofScrollView:scrollView forced:YES];

    if ([_target respondsToSelector:@selector(rs_scrollViewDidChangeContentSize:)]) {
        [(id<RSScrollViewDelegate>)_target rs_scrollViewDidChangeContentSize:scrollView];
    }
}

- (CGPoint)pRS_PISVDP_invertedContentOffsetForScrollView:(UIScrollView *)scrollView
                                           contentOffset:(CGPoint)contentOffset
{
    CGSize contentSize = scrollView.contentSize;

    return CGPointMake(contentSize.width - contentOffset.x - scrollView.bounds.size.width,
                       contentSize.height - contentOffset.y - scrollView.bounds.size.height);
}

- (void)pRS_PISVDP_handleContentOffset:(CGPoint)contentOffset ofScrollView:(UIScrollView *)scrollView {
    [self pRS_PISVDP_handleContentOffset:contentOffset ofScrollView:scrollView forced:NO];
}

- (void)pRS_PISVDP_handleContentOffset:(CGPoint)contentOffset ofScrollView:(UIScrollView *)scrollView forced:(BOOL)forced {
    id delegate = self.delegate;

    if (![delegate respondsToSelector:@selector(scrollView:willScrollToEdges:)]) {
        return;
    }

    CGSize contentSize = scrollView.contentSize;
    UIEdgeInsets contentInsets = scrollView.contentInset;
    CGFloat scrollViewHeight = scrollView.bounds.size.height;
    CGFloat scrollViewWidth = scrollView.bounds.size.width;

    CGPoint invertedContentOffset = [self pRS_PISVDP_invertedContentOffsetForScrollView: scrollView
                                                                          contentOffset: contentOffset];

    BOOL (^isItCloseToEdge)(CGFloat, CGFloat, CGFloat, CGFloat) = ^BOOL(CGFloat axisOffset, CGFloat prevAxisOffset,
                                                                        CGFloat contentAxisSize, CGFloat viewAxisSize)
    {
        return (axisOffset >= (contentAxisSize - viewAxisSize * 2) &&
                (forced || (contentAxisSize > 0 && axisOffset > prevAxisOffset)));
    };

    RSScrollViewEdges edges = kNilOptions;

    if (isItCloseToEdge(contentOffset.y, _prevBottomContentOffset.y, contentSize.height, scrollViewHeight)) {
        edges |= RSScrollViewEdgesBottom;

        _prevBottomContentOffset = CGPointMake(contentOffset.x,
                                               contentSize.height - scrollViewHeight + contentInsets.bottom);
    }

    if (isItCloseToEdge(contentOffset.x, _prevRightContentOffset.x, contentSize.width, scrollViewWidth)) {
        edges |= RSScrollViewEdgesRight;

        _prevRightContentOffset = CGPointMake(contentSize.width - scrollViewWidth + contentInsets.right,
                                              contentOffset.y);
    }

    if (isItCloseToEdge(invertedContentOffset.y, _prevTopInvertedContentOffset.y,
                        contentSize.height, scrollViewHeight))
    {
        edges |= RSScrollViewEdgesTop;

        _prevTopInvertedContentOffset = CGPointMake(invertedContentOffset.x,
                                                    contentSize.height - scrollViewHeight + contentInsets.top);
    }

    if (isItCloseToEdge(invertedContentOffset.x, _prevLeftInvertedContentOffset.x,
                        contentSize.width, scrollViewWidth))
    {
        edges |= RSScrollViewEdgesLeft;

        _prevLeftInvertedContentOffset = CGPointMake(contentSize.width - scrollViewWidth + contentInsets.left,
                                                     invertedContentOffset.y);
    }

    if (edges != kNilOptions) {
        [delegate scrollView:scrollView willScrollToEdges:edges];
    }
}

@end
