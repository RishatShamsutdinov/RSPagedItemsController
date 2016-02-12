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

@interface RSPagedItemsScrollViewDelegateProxy () <UIScrollViewDelegate> {
    id<UIScrollViewDelegate> __weak _target;

    CGPoint _prevContentOffset;

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
            aSelector == @selector(scrollViewDidEndDecelerating:));
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.decelerating && scrollView.tracking) {
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
        _prevContentOffset = scrollView.contentOffset;
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

- (void)handleContentOffset:(CGPoint)contentOffset ofScrollView:(UIScrollView *)scrollView {
    id delegate = self.delegate;

    if (![delegate respondsToSelector:@selector(scrollView:willScrollToEdge:)]) {
        return;
    }

    CGSize contentSize = scrollView.contentSize;
    CGFloat scrollViewHeight = scrollView.bounds.size.height;

    NSNumber *edgeNum;

    if (contentOffset.y <= scrollViewHeight && contentOffset.y - _prevContentOffset.y < 0) {
        edgeNum = @(RSScrollViewEdgeTop);

        _prevContentOffset = CGPointMake(contentOffset.x, -scrollView.contentInset.top);
    }

    if (contentOffset.y >= (contentSize.height - scrollViewHeight * 2) && contentOffset.y - _prevContentOffset.y > 0) {
        edgeNum = @(RSScrollViewEdgeBottom);

        _prevContentOffset = CGPointMake(contentOffset.x,
                                         contentSize.height - scrollViewHeight + scrollView.contentInset.bottom);
    }

    if (edgeNum) {
        RSScrollViewEdge edge;

        [edgeNum getValue:&edge];
        
        [delegate scrollView:scrollView willScrollToEdge:edge];
    }
}

@end
