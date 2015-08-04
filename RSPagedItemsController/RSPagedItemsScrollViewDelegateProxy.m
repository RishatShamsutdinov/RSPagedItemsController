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

    NSNumber *_prevEdgeNum;
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

    return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:_target];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if (!_target) {
        return [[self class] instanceMethodSignatureForSelector:sel];
    }

    return [(NSObject *)_target methodSignatureForSelector:sel];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return ([_target respondsToSelector:aSelector] ||
            aSelector == @selector(scrollViewDidScroll:) ||
            aSelector == @selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:));
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

- (void)handleContentOffset:(CGPoint)contentOffset ofScrollView:(UIScrollView *)scrollView {
    id delegate = self.delegate;

    if (![delegate respondsToSelector:@selector(scrollView:willScrollToEdge:)]) {
        return;
    }

    CGSize contentSize = scrollView.contentSize;
    CGFloat scrollViewHeight = scrollView.bounds.size.height;

    NSNumber *edgeNum;

    if (contentOffset.y <= scrollViewHeight) {
        edgeNum = @(RSScrollViewEdgeTop);
    }

    if (contentOffset.y >= (contentSize.height - scrollViewHeight * 2)) {
        edgeNum = @(RSScrollViewEdgeBottom);
    }

    if (_prevEdgeNum && edgeNum && [_prevEdgeNum compare:edgeNum] == NSOrderedSame) {
        return;
    }

    _prevEdgeNum = edgeNum;

    if (edgeNum) {
        RSScrollViewEdge edge;

        [edgeNum getValue:&edge];

        [delegate scrollView:scrollView willScrollToEdge:edge];
    }
}

@end
