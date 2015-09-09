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

@interface RSPagedItemsLoadManager () <RSPagedItemsLoaderDelegate, RSPagedItemsScrollViewDelegateProxyDelegate> {
    UIScrollView __weak *_scrollView;
    id<UIScrollViewDelegate> __weak _originalDelegate;
    RSPagedItemsScrollViewDelegateProxy *_scrollViewDelegateProxy;

    id<RSPagedItemsLoader> _loader;

    UIActivityIndicatorView *_activityIndicatorView;
    UIView *_activityIndicatorViewContainer;

    NSOperationQueue *_operationQueue;

    BOOL _readyForLoading;
    BOOL _firstInitialLoad;
}

@end

@implementation RSPagedItemsLoadManager

@synthesize scrollViewDelegateProxy = _scrollViewDelegateProxy;

+ (instancetype)managerWithLoader:(id<RSPagedItemsLoader>)pagedItemsLoader
                         delegate:(id<RSPagedItemsLoadManagerDelegate>)delegate
                    forScrollView:(UIScrollView *)scrollView
                   scrollViewEdge:(RSScrollViewEdge)scrollViewEdge
{
    RSPagedItemsLoadManager *manager = [[self alloc] initWithLoader:pagedItemsLoader scrollView:scrollView
                                                     scrollViewEdge:scrollViewEdge];

    manager.delegate = delegate;

    return manager;
}

- (instancetype)initWithLoader:(id<RSPagedItemsLoader>)loader scrollView:(UIScrollView *)scrollView
                scrollViewEdge:(RSScrollViewEdge)scrollViewEdge
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

        _operationQueue = [NSOperationQueue new];
        _operationQueue.maxConcurrentOperationCount = 1;

        [self configureActivityIndicator];
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

    return [NSBlockOperation blockOperationWithBlock:^{
        if (loader != _loader) {
            return;
        }

        copiedBlock();
    }];
}

- (void)queueOperationForLoader:(id<RSPagedItemsLoader>)loader withBlock:(void (^)())block {
    [_operationQueue addOperation:[self blockOperationForLoader:loader withBlock:block]];
}

#pragma mark - Appearance of activity indicator

- (void)showActivityIndicatorForScrollViewIfNeeded:(UIScrollView *)scrollView {
    if (_activityIndicatorViewContainer.superview || ![scrollView isKindOfClass:[UITableView class]]) {
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
    if (!_readyForLoading) {
        return;
    }

    CGSize __block contentSize;

    rs_dispatch_sync_main_safe(^{
        contentSize = [self contentSizeOfElementsInScrollView];
    });

    if (contentSize.height && edge == self.scrollViewEdge) {
        _readyForLoading = NO;

        [_loader loadMoreIfNeededWithCompletion:nil];
    }
}

#pragma mark - RSPagedItemsLoaderDelegate

- (void)pagedItemsLoaderDidStartLoading:(id<RSPagedItemsLoader>)pagedItemsLoader {
    [self queueOperationForLoader:pagedItemsLoader withBlock:^{
        rs_dispatch_sync_main_safe(^{
            [self showActivityIndicatorForScrollViewIfNeeded:_scrollView];
        });
    }];
}

- (void)pagedItemsLoaderDidFinishLoading:(id<RSPagedItemsLoader>)pagedItemsLoader {
    [self queueOperationForLoader:pagedItemsLoader withBlock:^{
        rs_dispatch_sync_main_safe(^{
            [self hideActivityIndicatorForScrollViewIfNeeded:_scrollView];
        });
    }];
}

- (void)pagedItemsLoader:(id<RSPagedItemsLoader>)pagedItemsLoader didLoadItems:(NSArray *)items initial:(BOOL)initial {
    [_operationQueue addOperations:@[[self blockOperationForLoader:pagedItemsLoader withBlock:^{
        rs_dispatch_sync_main_safe(^{
            id delegate = self.delegate;

            if ([delegate respondsToSelector:@selector(pagedItemsLoadManager:didLoadItems:initial:)]) {
                [delegate pagedItemsLoadManager:self didLoadItems:items initial:initial];
            }

            CGSize contentSize = [self contentSizeOfElementsInScrollView];

            if (contentSize.height < _scrollView.bounds.size.height && self.enableLoading) {
                [self queueOperationForLoader:pagedItemsLoader withBlock:^{
                    _readyForLoading = YES;

                    [self tryToLoadMoreWithScrollViewEdge:self.scrollViewEdge];
                }];
            } else {
                _readyForLoading = YES;
            }
        });
    }]] waitUntilFinished:YES];
}

- (void)pagedItemsLoader:(id<RSPagedItemsLoader>)pagedItemsLoader didFailLoadWithError:(NSError *)error
                 initial:(BOOL)initial
{
    [_operationQueue addOperations:@[[self blockOperationForLoader:pagedItemsLoader withBlock:^{
        _readyForLoading = YES;

        id delegate = self.delegate;

        if ([delegate respondsToSelector:@selector(pagedItemsLoader:didFailLoadWithError:initial:)]) {
            rs_dispatch_sync_main_safe(^{
                [delegate pagedItemsLoadManager:self didFailLoadWithError:error initial:initial];
            });
        }
    }]] waitUntilFinished:YES];
}

#pragma mark -

- (void)loadInitialContentWithCompletion:(void (^)(BOOL success))completion {
    [_operationQueue cancelAllOperations];

    [_operationQueue addOperationWithBlock:^{
        _readyForLoading = NO;

        if (!_firstInitialLoad) {
            _loader.delegate = nil;

            _loader = [_loader loaderByResettingCursor];

            _loader.delegate = self;
        }

        _firstInitialLoad = NO;

        [_loader loadMoreIfNeededWithCompletion:completion];
    }];
}

- (void)dealloc {
    _scrollView.delegate = _originalDelegate;
}

@end
