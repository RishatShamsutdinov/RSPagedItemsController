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

#import "RSPagedItemsController.h"
#import "RSPagedItemsLoadManager.h"
#import "RSFoundationUtils.h"

@interface RSPagedItemsController () <RSPagedItemsLoadManagerDelegate> {
    NSMutableArray *_items;
    NSUUID *_itemsUUID;

    RSPagedItemsLoadManager *_itemsLoadManager;
}

@end

@implementation RSPagedItemsController

+ (instancetype)controllerWithDelegate:(id<RSPagedItemsControllerDelegate>)delegate {
    RSPagedItemsController *controller = [self new];

    controller.delegate = delegate;

    return controller;
}

- (instancetype)init {
    if (self = [super init]) {
        _items = [NSMutableArray new];
    }

    return self;
}

#pragma mark - Working with items

- (NSUInteger)itemsCount {
    return _items.count;
}

- (id)firstItem {
    return _items.firstObject;
}

- (id)lastItem {
    return _items.lastObject;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    return _items[idx];
}

- (void)_didChageItemsAtIndexes:(NSIndexSet *)indexes forChangeType:(RSPagedItemsChangeType)changeType {
    id delegate = self.delegate;

    if ([delegate respondsToSelector:@selector(pagedItemsController:didChangeItemsAtIndexes:forChangeType:)]) {
        [delegate pagedItemsController:self didChangeItemsAtIndexes:indexes forChangeType:changeType];
    }
}

- (void)addObject:(id)obj {
    if (obj) {
        [self addObjects:@[obj]];
    }
}

- (void)addObjects:(NSArray *)objects {
    [self _insertObjects:objects atIndex:_items.count withChangeType:RSPagedItemsChangeAppend];
}

- (void)insertObject:(id)obj atIndex:(NSUInteger)index {
    if (obj) {
        [self insertObjects:@[obj] atIndex:index];
    }
}

- (void)insertObjects:(NSArray *)objects atIndex:(NSUInteger)index {
    [self _insertObjects:objects atIndex:index withChangeType:RSPagedItemsChangeInsert];
}

- (void)_insertObjects:(NSArray *)objects atIndex:(NSUInteger)index withChangeType:(RSPagedItemsChangeType)changeType {
    if (!objects.count) {
        return;
    }

    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, objects.count)];

    [_items insertObjects:objects atIndexes:indexes];

    [self _didChageItemsAtIndexes:indexes forChangeType:changeType];
}

- (void)loadItemsUsingBlock:(RSPagedItemsControllerLoadingBlock)block
                withHandler:(void (^)(NSArray *items))handler completion:(void (^)())completion {

    if (!_itemsUUID) {
        return;
    }

    NSUUID *itemsUUID = _itemsUUID;

    typeof(self) __weak weakSelf = self;

    completion = [completion copy];

    block(^(NSArray *items) {
        rs_dispatch_async_main(^{
            voidWithStrongSelf(weakSelf, ^(typeof(self) strongSelf) {
                if (![itemsUUID isEqual:strongSelf->_itemsUUID]) {
                    return;
                }

                handler(items);
            });

            if (completion) {
                completion();
            }
        });
    });
}

- (void)addObjectsUsingBlock:(RSPagedItemsControllerLoadingBlock)block completion:(void (^)())completion {
    typeof(self) __weak weakSelf = self;

    [self loadItemsUsingBlock:block withHandler:^(NSArray *items) {
        voidWithStrongSelf(weakSelf, ^(typeof(self) strongSelf) {
            [strongSelf addObjects:items];
        });
    } completion:completion];
}

- (void)insertObjectsAtItemsBeginningUsingBlock:(RSPagedItemsControllerLoadingBlock)block
                                     completion:(void (^)())completion {

    typeof(self) __weak weakSelf = self;

    [self loadItemsUsingBlock:block withHandler:^(NSArray *items) {
        voidWithStrongSelf(weakSelf, ^(typeof(self) strongSelf) {
            [strongSelf insertObjects:items atIndex:0];
        });
    } completion:completion];
}

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes {
    [_items removeObjectsAtIndexes:indexes];

    [self _didChageItemsAtIndexes:indexes forChangeType:RSPagedItemsChangeDelete];
}

- (void)removeObjectsPassingTest:(BOOL (^)(id, NSUInteger))predicate {
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    [_items rs_removeObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if (predicate(obj, idx)) {
            [indexes addIndex:idx];

            return YES;
        }

        return NO;
    }];

    [self _didChageItemsAtIndexes:[indexes copy] forChangeType:RSPagedItemsChangeDelete];
}

- (void)updateObjectsUsingBlock:(BOOL (^)(id, NSUInteger, BOOL *))block {
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    [_items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (block(obj, idx, stop)) {
            [indexes addIndex:idx];
        }
    }];

    [self _didChageItemsAtIndexes:[indexes copy] forChangeType:RSPagedItemsChangeUpdate];
}

- (void)replaceObjectsUsingBlock:(id (^)(id, NSUInteger, BOOL *))block {
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    [_items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id newObj = block(obj, idx, stop);

        if (newObj != obj) {
            [indexes addIndex:idx];
        }
    }];

    [self _didChageItemsAtIndexes:[indexes copy] forChangeType:RSPagedItemsChangeReplace];
}

#pragma mark -

- (void)integrateWithScrollView:(UIScrollView *)scrollView onEdge:(RSScrollViewEdge)edge
                    usingLoader:(id<RSPagedItemsLoader>)loader
{
    if (_itemsLoadManager) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Already integrated with scroll view"
                                     userInfo:nil];
    }

    _itemsLoadManager = [RSPagedItemsLoadManager managerWithLoader:loader delegate:self
                                                     forScrollView:scrollView scrollViewEdge:edge];
}

#pragma mark - RSPagedItemsLoadManagerDelegate

- (void)pagedItemsLoadManager:(RSPagedItemsLoadManager *)manager didLoadItems:(NSArray *)items initial:(BOOL)initial {
    RSPagedItemsChangeType changeType;
    NSIndexSet *indexes;

    if (initial) {
        _itemsUUID = [NSUUID UUID];

        changeType = RSPagedItemsChangeReplace;

        [_items setArray:items];

        indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _items.count)];
    } else if (_itemsLoadManager.scrollViewEdge == RSScrollViewEdgeTop) {
        changeType = RSPagedItemsChangeInsert;

        indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, items.count)];

        [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [_items insertObject:obj atIndex:0];
        }];
    } else {
        changeType = RSPagedItemsChangeAppend;

        indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_items.count, items.count)];

        [_items addObjectsFromArray:items];
    }

    [self _didChageItemsAtIndexes:indexes forChangeType:changeType];
}

@end

@implementation UITableViewController (RSPagedItemsController)

- (NSInteger)sectionOfPagedItemsController:(RSPagedItemsController *)controller {
    return 0;
}

- (void)pagedItemsController:(RSPagedItemsController *)pagedItemsController
     didChangeItemsAtIndexes:(NSIndexSet *)indexes forChangeType:(RSPagedItemsChangeType)changeType
{
    NSInteger section = [self sectionOfPagedItemsController:pagedItemsController];
    NSArray *indexPaths = [indexes rs_indexPathsForRowsInSection:section];

    switch (changeType) {
        case RSPagedItemsChangeReplace:
            [self.tableView reloadData];
            break;

        case RSPagedItemsChangeInsert:
        case RSPagedItemsChangeAppend:
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            break;

        case RSPagedItemsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case RSPagedItemsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}

@end
