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

#import "RSPagedItemsLoadManager.h"
#import "RSFoundationUtils.h"

static NSTimeInterval const kDelayAfterItemsLoad = 0.1;

#define ASSERT_MAIN_THREAD \
    if (![NSThread isMainThread]) { \
        @throw [NSException exceptionWithName: NSInternalInconsistencyException \
                                       reason: @"Must be called on main thread" \
                                     userInfo: nil]; \
    }

@interface RSPagedItemsLoadManager () <RSPagedItemsLoaderDelegate, RSPagedItemsScrollViewDelegateProxyDelegate> {
    UIScrollView __weak *_scrollView;
    id<UIScrollViewDelegate> __weak _originalDelegate;
    RSPagedItemsScrollViewDelegateProxy *_scrollViewDelegateProxy;

    id<RSPagedItemsLoader> _loader;

    UIActivityIndicatorView *_activityIndicatorView;
    UIView *_activityIndicatorViewContainer;

    BOOL _readyForLoading;
    BOOL _firstInitialLoad;
    BOOL _needsLoadMore;

    NSPointerArray *_operations;
}

@end

@implementation RSPagedItemsLoadManager

@synthesize scrollViewDelegateProxy = _scrollViewDelegateProxy;

+ (instancetype)managerWithLoader:(id<RSPagedItemsLoader>)pagedItemsLoader
                         delegate:(id<RSPagedItemsLoadManagerDelegate>)delegate
                    forScrollView:(UIScrollView *)scrollView
                   scrollViewEdge:(RSScrollViewEdge)scrollViewEdge
          allowsActivityIndicator:(BOOL)allowsActivityIndicator
{
    RSPagedItemsLoadManager *manager = [[self alloc] initWithLoader: pagedItemsLoader
                                                         scrollView: scrollView
                                                     scrollViewEdge: scrollViewEdge
                                            allowsActivityIndicator: allowsActivityIndicator];

    manager.delegate = delegate;

    return manager;
}

- (instancetype)initWithLoader:(id<RSPagedItemsLoader>)loader scrollView:(UIScrollView *)scrollView
                scrollViewEdge:(RSScrollViewEdge)scrollViewEdge allowsActivityIndicator:(BOOL)allowsActivityIndicator
{
    if (self = [self init]) {
        _originalDelegate = scrollView.delegate;
        _scrollViewDelegateProxy = [RSPagedItemsScrollViewDelegateProxy proxyWithTarget:scrollView.delegate
                                                                               delegate:self];

        scrollView.delegate = (id)_scrollViewDelegateProxy;

        _scrollView = scrollView;
        _scrollViewEdge = scrollViewEdge;
        _enableLoading = YES;
        _firstInitialLoad = YES;

        _loader = loader;
        _loader.delegate = self;

        _operations = [NSPointerArray weakObjectsPointerArray];

        if (allowsActivityIndicator) {
            [self configureActivityIndicator];
        }
    }
    
    return self;
}

- (void)setDelegate:(id<RSPagedItemsLoadManagerDelegate>)delegate {
    _delegate = delegate;
}

- (void)configureActivityIndicator {
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                              UIActivityIndicatorViewStyleGray];
    _activityIndicatorViewContainer = [UIView new];

    static CGFloat const inset = 10;

    _activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    _activityIndicatorViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [_activityIndicatorViewContainer addSubview:_activityIndicatorView];

    NSDictionary *binds = NSDictionaryOfVariableBindings(_activityIndicatorView);

    [_activityIndicatorViewContainer addConstraint:
     [NSLayoutConstraint constraintWithItem:_activityIndicatorView attribute:NSLayoutAttributeCenterX
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:_activityIndicatorViewContainer attribute:NSLayoutAttributeCenterX
                                 multiplier:1 constant:0]];

    [_activityIndicatorViewContainer addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0)-[_activityIndicatorView]" options:kNilOptions
                                             metrics:nil views:binds]];

    [_activityIndicatorViewContainer addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-i-[_activityIndicatorView]-i-|" options:kNilOptions
                                             metrics:@{@"i": @(inset)} views:binds]];

    CGSize size = [_activityIndicatorViewContainer systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

    _activityIndicatorViewContainer.frame = CGRectMake(0, 0, size.width, size.height);
}

- (CGSize)contentSizeOfElementsInScrollView {
    CGSize contentSize = _scrollView.contentSize;

    if ([_scrollView isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (id)_scrollView;

        contentSize.height = MAX(0, (contentSize.height - tableView.tableHeaderView.frame.size.height
                                     - tableView.tableFooterView.frame.size.height));
    }
    else if ([_scrollView isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (id)_scrollView;

        contentSize = [collectionView.collectionViewLayout collectionViewContentSize];
    }

    return contentSize;
}

- (NSBlockOperation *)blockOperationForLoader:(id<RSPagedItemsLoader>)loader withBlock:(void (^)())block {
    void __block (^copiedBlock)() = [block copy];

    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        if (loader != _loader || _loader == nil) {
            return;
        }

        copiedBlock();
    }];

    [_operations compact];
    [_operations addPointer:(__bridge void *)op];

    return op;
}

- (void)queueOperationForLoader:(id<RSPagedItemsLoader>)loader withBlock:(void (^)())block {
    [[NSOperationQueue mainQueue] addOperation:[self blockOperationForLoader:loader withBlock:block]];
}

#pragma mark - Appearance of activity indicator

- (void)showActivityIndicatorForScrollViewIfNeeded:(UIScrollView *)scrollView {
    if (!_activityIndicatorViewContainer || _activityIndicatorViewContainer.superview ||
        ![scrollView isKindOfClass:[UITableView class]])
    {
        return;
    }

    UITableView *tableView = (id)scrollView;

    CGRect frame = _activityIndicatorViewContainer.frame;

    frame.size.width = CGRectGetWidth(tableView.bounds);

    _activityIndicatorViewContainer.frame = frame;

    [_activityIndicatorViewContainer layoutIfNeeded];

    switch (self.scrollViewEdge) {
        case RSScrollViewEdgeBottom: {
            if (tableView.tableFooterView) {
                return;
            }

            tableView.tableFooterView = _activityIndicatorViewContainer;

            break;
        }

        case RSScrollViewEdgeTop: {
            if (tableView.tableHeaderView) {
                return;
            }

            tableView.tableHeaderView = _activityIndicatorViewContainer;

            break;
        }
    }

    [_activityIndicatorView startAnimating];
}

- (void)hideActivityIndicatorForScrollViewIfNeeded:(UIScrollView *)scrollView {
    if (!_activityIndicatorViewContainer.superview) {
        return;
    }

    UITableView *tableView = (id)scrollView;

    if (tableView.tableHeaderView == _activityIndicatorViewContainer) {
        tableView.tableHeaderView = nil;
    }
    else if (tableView.tableFooterView == _activityIndicatorViewContainer) {
        tableView.tableFooterView = nil;
    }
    
    [_activityIndicatorView stopAnimating];
}

#pragma mark - RSPagedItemsScrollViewDelegateProxyDelegate

- (void)scrollView:(UIScrollView *)scrollView willScrollToEdge:(RSScrollViewEdge)edge {
    if (self.enableLoading) {
        typeof(self) __weak weakSelf = self;

        [self queueOperationForLoader:_loader withBlock:^{
            voidWithStrongSelf(weakSelf, ^(typeof(self) strongSelf) {
                [strongSelf tryToLoadMoreWithScrollViewEdge:edge];
            });
        }];
    }
}

- (void)tryToLoadMoreWithScrollViewEdge:(RSScrollViewEdge)edge {
    CGSize contentSize = [self contentSizeOfElementsInScrollView];

    if (contentSize.height && edge == self.scrollViewEdge) {
        if (!_readyForLoading) {
            _needsLoadMore = YES;
            return;
        }

        _needsLoadMore = NO;
        _readyForLoading = NO;

        [_loader loadMoreIfNeededWithCompletion:nil];
    }
}

#pragma mark - RSPagedItemsLoaderDelegate

- (void)pagedItemsLoaderDidStartLoading:(id<RSPagedItemsLoader>)pagedItemsLoader {
    [self queueOperationForLoader:pagedItemsLoader withBlock:^{
        [self showActivityIndicatorForScrollViewIfNeeded:_scrollView];
    }];
}

- (void)pagedItemsLoaderDidFinishLoading:(id<RSPagedItemsLoader>)pagedItemsLoader {
    [self queueOperationForLoader:pagedItemsLoader withBlock:^{
        [self hideActivityIndicatorForScrollViewIfNeeded:_scrollView];
    }];
}

- (void)pagedItemsLoader:(id<RSPagedItemsLoader>)pagedItemsLoader didLoadItems:(NSArray *)items initial:(BOOL)initial {
    [[NSOperationQueue mainQueue] addOperations:@[[self blockOperationForLoader:pagedItemsLoader withBlock:^{
        id delegate = self.delegate;

        if ([delegate respondsToSelector:@selector(pagedItemsLoadManager:didLoadItems:initial:)]) {
            [delegate pagedItemsLoadManager:self didLoadItems:items initial:initial];
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kDelayAfterItemsLoad * NSEC_PER_SEC)),
                       dispatch_get_main_queue(),
                       ^{
                           CGSize contentSize = [self contentSizeOfElementsInScrollView];

                           if (self.enableLoading &&
                               (_needsLoadMore || contentSize.height < _scrollView.bounds.size.height))
                           {
                               [self queueOperationForLoader:pagedItemsLoader withBlock:^{
                                   _readyForLoading = YES;

                                   [self tryToLoadMoreWithScrollViewEdge:self.scrollViewEdge];
                               }];
                           } else {
                               _readyForLoading = YES;
                           }

                           _needsLoadMore = NO;
                       });
    }]] waitUntilFinished:YES];
}

- (void)pagedItemsLoader:(id<RSPagedItemsLoader>)pagedItemsLoader didFailLoadWithError:(NSError *)error
                 initial:(BOOL)initial
{
    [[NSOperationQueue mainQueue] addOperations:@[[self blockOperationForLoader:pagedItemsLoader withBlock:^{
        _readyForLoading = YES;

        id delegate = self.delegate;

        if ([delegate respondsToSelector:@selector(pagedItemsLoader:didFailLoadWithError:initial:)]) {
            [delegate pagedItemsLoadManager:self didFailLoadWithError:error initial:initial];
        }
    }]] waitUntilFinished:YES];
}

#pragma mark -

- (void)loadInitialContentWithCompletion:(void (^)(BOOL success))completion {
    ASSERT_MAIN_THREAD

    [_operations compact];

    for (NSOperation *op in _operations) {
        [op cancel];
    }

    _readyForLoading = NO;

    if (!_firstInitialLoad) {
        _loader.delegate = nil;

        _loader = [_loader loaderByResettingCursor];

        _loader.delegate = self;
    }

    _firstInitialLoad = NO;

    [_loader loadMoreIfNeededWithCompletion:completion];
}

- (void)disintegrate {
    ASSERT_MAIN_THREAD

    [self hideActivityIndicatorForScrollViewIfNeeded:_scrollView];

    _scrollView.delegate = _originalDelegate;

    _originalDelegate = nil;
    _scrollView = nil;
    _scrollViewDelegateProxy = nil;
    _activityIndicatorView = nil;
    _activityIndicatorViewContainer = nil;
    _loader = nil;

    for (NSOperation *op in _operations) {
        [op cancel];
    }
}

@end
