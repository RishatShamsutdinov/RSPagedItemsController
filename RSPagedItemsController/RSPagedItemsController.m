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
#import "RSPagedItemsLoadManager_Private.h"
#import "RSFoundationUtils.h"
#import "NSMutableArray+RSPagedItemsCollection.h"

NSString * const RSPagedItemsControllerIndexesKey = @"RSPagedItemsControllerIndexesKey";
NSString * const RSPagedItemsControllerObjectsKey = @"RSPagedItemsControllerObjectsKey";
NSString * const RSPagedItemsControllerAreObjectsFromLoaderKey = @"RSPagedItemsControllerAreObjectsFromLoaderKey";

@interface RSPagedItemsController () <RSPagedItemsLoadManagerDelegate> {
    id<RSPagedItemsCollection> _items;
    BOOL _collectionAllowsDuplicates;
    NSUUID *_itemsUUID;

    RSPagedItemsLoadManager *_itemsLoadManager;
}

@end

@implementation RSPagedItemsController

+ (instancetype)controllerWithDelegate:(id<RSPagedItemsControllerDelegate>)delegate
                                  edge:(RSScrollViewEdge)edge loader:(id<RSPagedItemsLoader>)loader
               allowsActivityIndicator:(BOOL)allowsActivityIndicator
{
    return [self controllerWithDelegate:delegate collectionClass:nil edge:edge
                                 loader:loader allowsActivityIndicator:allowsActivityIndicator];
}

+ (instancetype)controllerWithDelegate:(id<RSPagedItemsControllerDelegate>)delegate
                       collectionClass:(__unsafe_unretained Class<RSPagedItemsCollection>)aClass
                                  edge:(RSScrollViewEdge)edge loader:(id<RSPagedItemsLoader>)loader
               allowsActivityIndicator:(BOOL)allowsActivityIndicator
{
    RSPagedItemsController *controller = [[self alloc] initWithCollectionClass:aClass edge:edge loader:loader
                                                       allowsActivityIndicator:allowsActivityIndicator];

    controller.delegate = delegate;

    return controller;
}

- (instancetype)initWithCollectionClass:(Class<RSPagedItemsCollection>)aClass
                                   edge:(RSScrollViewEdge)edge loader:(id<RSPagedItemsLoader>)loader
                allowsActivityIndicator:(BOOL)allowsActivityIndicator
{
    if (self = [super init]) {
        _items = [[(id)(aClass ?: [NSMutableArray class]) alloc] init];
        _collectionAllowsDuplicates = [[_items class] allowsDuplicates];
        _clearItemsOnReplace = YES;

        _itemsLoadManager = [RSPagedItemsLoadManager managerWithLoader:loader delegate:self scrollViewEdge:edge
                                               allowsActivityIndicator:allowsActivityIndicator];
    }

    return self;
}

- (BOOL)enableAutoLoading {
    return _itemsLoadManager.enableLoading;
}

- (void)setEnableAutoLoading:(BOOL)enableAutoLoading {
    _itemsLoadManager.enableLoading = enableAutoLoading;
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

- (id)objectsAtIndexes:(NSIndexSet *)indexes {
    return [_items objectsAtIndexes:indexes];
}

- (BOOL)containsObject:(id)obj {
    return [_items containsObject:obj];
}

- (BOOL)containsObjectIdenticalTo:(id)obj {
    return ([_items indexOfObjectIdenticalTo:obj] != NSNotFound);
}

- (NSUInteger)indexOfObject:(id)obj {
    return [_items indexOfObject:obj];
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)obj {
    return [_items indexOfObjectIdenticalTo:obj];
}

- (NSUInteger)indexOfObjectPassingTest:(BOOL (^)(id, NSUInteger))predicate {
    return [_items indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return predicate(obj, idx);
    }];
}

- (NSIndexSet *)indexesOfObjectsPassingTest:(BOOL (^)(id, NSUInteger))predicate {
    return [_items indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return predicate(obj, idx);
    }];
}

- (void)enumerateObjectsUsingBlock:(void (^)(id, NSUInteger, BOOL *))block {
    [_items enumerateObjectsUsingBlock:block];
}

static NSEnumerationOptions pRS_PIC_NSEnumerationOptions(RSPagedItemsEnumerationOptions opts) {
    return (opts & (RSPagedItemsEnumerationReverse));
}

- (void)enumerateObjectsWithOptions:(RSPagedItemsEnumerationOptions)opts
                         usingBlock:(void (^)(id, NSUInteger, BOOL *))block
{
    [_items enumerateObjectsWithOptions:pRS_PIC_NSEnumerationOptions(opts) usingBlock:block];
}

- (void)enumerateObjectsAtIndexes:(NSIndexSet *)indexSet options:(RSPagedItemsEnumerationOptions)opts
                       usingBlock:(void (^)(id, NSUInteger, BOOL *))block
{
    [_items enumerateObjectsAtIndexes:indexSet options:pRS_PIC_NSEnumerationOptions(opts) usingBlock:block];
}

- (void)pRS_PIC_didChageItemsAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects
                               forType:(RSPagedItemsChangeType)changeType fromLoader:(BOOL)fromLoader
{
    if (!indexes.count && changeType != RSPagedItemsChangeReplace) {
        return;
    }

    id delegate = self.delegate;

    if ([delegate respondsToSelector:@selector(pagedItemsController:didChangeItemsForType:userInfo:)]) {
        [delegate pagedItemsController:self didChangeItemsForType:changeType
                              userInfo:@{RSPagedItemsControllerIndexesKey: indexes,
                                         RSPagedItemsControllerObjectsKey: objects,
                                         RSPagedItemsControllerAreObjectsFromLoaderKey: @(fromLoader)}];
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
    if (objects.count && !_collectionAllowsDuplicates) {
        objects = [objects rs_filteredArrayUsingBlock:^BOOL(id obj) {
            return ![self->_items containsObject:obj];
        }];

        if (objects.count > 1) {
            objects = [NSOrderedSet orderedSetWithArray:objects].array;
        }
    }

    if (!objects.count) {
        return;
    }

    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(index, objects.count)];

    [_items insertObjects:objects atIndexes:indexes];

    [self pRS_PIC_didChageItemsAtIndexes:indexes withObjects:objects forType:changeType fromLoader:NO];
}

- (void)loadItemsUsingBlock:(RSPagedItemsControllerLoadingBlock)block
                withHandler:(void (^)(NSArray *items))handler completion:(void (^)())completion
{
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
                                     completion:(void (^)())completion
{
    typeof(self) __weak weakSelf = self;

    [self loadItemsUsingBlock:block withHandler:^(NSArray *items) {
        voidWithStrongSelf(weakSelf, ^(typeof(self) strongSelf) {
            [strongSelf insertObjects:items atIndex:0];
        });
    } completion:completion];
}

- (void)removeObject:(id)obj {
    NSUInteger index = [self indexOfObject:obj];

    if (index != NSNotFound) {
        [self removeObjectsAtIndexes:[NSIndexSet indexSetWithIndex:index]];
    }
}

- (void)removeObjects:(NSArray *)objects {
    NSIndexSet *indexes = [self indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx) {
        return [objects containsObject:obj];
    }];

    if (indexes.count) {
        [self removeObjectsAtIndexes:indexes];
    }
}

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes {
    NSArray *objects = [_items objectsAtIndexes:indexes];

    [_items removeObjectsAtIndexes:indexes];

    [self pRS_PIC_didChageItemsAtIndexes:indexes withObjects:objects forType:RSPagedItemsChangeDelete fromLoader:NO];
}

- (void)removeObjectsPassingTest:(BOOL (^)(id, NSUInteger))predicate {
    NSMutableArray *objects = [NSMutableArray new];
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];

    [_items removeObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if (predicate(obj, idx)) {
            [indexes addIndex:idx];
            [objects addObject:obj];

            return YES;
        }

        return NO;
    }];

    [self pRS_PIC_didChageItemsAtIndexes:indexes withObjects:objects forType:RSPagedItemsChangeDelete fromLoader:NO];
}

- (void)removeAllObjects {
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:_items.count];

    [_items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [objects addObject:obj];
    }];

    [_items removeAllObjects];

    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, objects.count)];

    [self pRS_PIC_didChageItemsAtIndexes:indexes withObjects:objects forType:RSPagedItemsChangeDelete fromLoader:NO];
}

- (void)updateObjectsUsingBlock:(BOOL (^)(id, NSUInteger, BOOL *))block {
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];
    NSMutableArray *objects = [NSMutableArray new];

    BOOL invalidateHash = [_items respondsToSelector:@selector(invalidateHashOfObjectAtIndex:)];

    [_items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (block(obj, idx, stop)) {
            [indexes addIndex:idx];
            [objects addObject:obj];

            if (invalidateHash) {
                [self->_items invalidateHashOfObjectAtIndex:idx];
            }
        }
    }];

    [self pRS_PIC_didChageItemsAtIndexes:indexes withObjects:objects forType:RSPagedItemsChangeUpdate fromLoader:NO];
}

- (void)replaceObjectsUsingBlock:(id (^)(id, NSUInteger, BOOL *))block {
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];
    NSMutableArray *objects = [NSMutableArray new];

    [_items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id newObj = block(obj, idx, stop);

        if (newObj != obj) {
            [indexes addIndex:idx];
            [objects addObject:newObj];
        }
    }];

    NSUInteger __block currentObjectsIdx = 0;

    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        self->_items[idx] = objects[currentObjectsIdx++];
    }];

    [self pRS_PIC_didChageItemsAtIndexes:indexes withObjects:objects forType:RSPagedItemsChangeReplace fromLoader:NO];
}

#pragma mark -

- (void)integrateWithScrollView:(UIScrollView *)scrollView {
    [_itemsLoadManager integrateWithScrollView:scrollView];
}

- (void)disintegrate {
    [_itemsLoadManager disintegrate];
}

- (void)loadInitialContentWithCompletion:(void (^)(BOOL))completion {
    [_itemsLoadManager loadInitialContentWithCompletion:completion];
}

#pragma mark - RSPagedItemsLoadManagerDelegate

- (void)pagedItemsLoadManager:(RSPagedItemsLoadManager *)manager didLoadItems:(NSArray *)items initial:(BOOL)initial {
    RSPagedItemsChangeType changeType = RSPagedItemsChangeReplace;
    NSIndexSet *indexes;
    NSEnumerator *enumerator;
    NSUInteger indexForInsert;

    id<RSPagedItemsControllerDelegate> delegate = self.delegate;

    if ([delegate respondsToSelector:@selector(pagedItemsController:willAddLoadedItems:)]) {
        [delegate pagedItemsController:self willAddLoadedItems:items];
    }
    else if ([delegate respondsToSelector:@selector(pagedItemsController:willAddItems:)]) {
        [delegate pagedItemsController:self willAddItems:items];
    }

    if (items.count && !_collectionAllowsDuplicates) {
        items = [items rs_filteredArrayUsingBlock:^BOOL(id obj) {
            return ![self->_items containsObject:obj];
        }];

        if (items.count > 1) {
            items = [NSOrderedSet orderedSetWithArray:items].array;
        }
    }

    if (initial) {
        _itemsUUID = [NSUUID UUID];

        changeType = RSPagedItemsChangeReplace;

        if (self.clearItemsOnReplace) {
            [_items removeAllObjects];
        }
    }

    if (_itemsLoadManager.scrollViewEdge == RSScrollViewEdgeTop) {
        if (!initial) {
            changeType = RSPagedItemsChangeInsert;
        }

        indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, items.count)];
        enumerator = [items reverseObjectEnumerator];
        indexForInsert = 0;
    } else {
        if (!initial) {
            changeType = RSPagedItemsChangeAppend;
        }

        indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_items.count, items.count)];
        enumerator = [items objectEnumerator];
        indexForInsert = _items.count;
    }

    NSArray *objects = [enumerator allObjects];

    [_items insertObjects:objects atIndex:indexForInsert];

    [self pRS_PIC_didChageItemsAtIndexes:indexes withObjects:objects forType:changeType fromLoader:YES];
}

@end

@implementation UITableViewController (RSPagedItemsController)

- (NSInteger)sectionOfPagedItemsController:(RSPagedItemsController *)controller {
    return 0;
}

- (void)pagedItemsController:(RSPagedItemsController *)pagedItemsController
       didChangeItemsForType:(RSPagedItemsChangeType)changeType userInfo:(NSDictionary *)userInfo
{
    NSInteger section = [self sectionOfPagedItemsController:pagedItemsController];
    NSArray *indexPaths = [userInfo[RSPagedItemsControllerIndexesKey] rs_indexPathsForRowsInSection:section];

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
