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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "RSPagedItemsTypes.h"
#import "RSPagedItemsLoader.h"
#import "NSIndexSet+RSPagedItems.h"
#import "RSPagedItemsCollectionProtocol.h"

@protocol RSPagedItemsControllerDelegate, RSPaLoad;

typedef NS_ENUM(NSUInteger, RSPagedItemsChangeType) {
    RSPagedItemsChangeReplace,
    RSPagedItemsChangeAppend,
    RSPagedItemsChangeInsert,
    RSPagedItemsChangeUpdate,
    RSPagedItemsChangeDelete
};

typedef NS_OPTIONS(NSUInteger, RSPagedItemsEnumerationOptions) {
    RSPagedItemsEnumerationReverse = NSEnumerationReverse
};

typedef void(^RSPagedItemsControllerHandler)(NSArray *items);
typedef void(^RSPagedItemsControllerLoadingBlock)(RSPagedItemsControllerHandler handler);

extern NSString * const RSPagedItemsControllerIndexesKey;
extern NSString * const RSPagedItemsControllerObjectsKey;

/**
 * @warning Call \c disintegrate before dealloc.
 */
@interface RSPagedItemsController : NSObject

@property (nonatomic, readonly) id firstItem;
@property (nonatomic, readonly) id lastItem;

@property (nonatomic, readonly) NSUInteger itemsCount;

/**
 * Default is YES.
 */
@property (nonatomic) BOOL enableAutoLoading;
@property (nonatomic) BOOL clearItemsOnReplace;

@property (nonatomic, weak) id<RSPagedItemsControllerDelegate> delegate;


- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)controllerWithDelegate:(id<RSPagedItemsControllerDelegate>)delegate edge:(RSScrollViewEdge)edge
                                loader:(id<RSPagedItemsLoader>)loader
               allowsActivityIndicator:(BOOL)allowsActivityIndicator;

+ (instancetype)controllerWithDelegate:(id<RSPagedItemsControllerDelegate>)delegate
                       collectionClass:(Class<RSPagedItemsCollection>)aClass
                                  edge:(RSScrollViewEdge)edge loader:(id<RSPagedItemsLoader>)loader
               allowsActivityIndicator:(BOOL)allowsActivityIndicator;

- (instancetype)initWithCollectionClass:(Class<RSPagedItemsCollection>)aClass
                                   edge:(RSScrollViewEdge)edge loader:(id<RSPagedItemsLoader>)loader
                allowsActivityIndicator:(BOOL)allowsActivityIndicator;

- (void)integrateWithScrollView:(UIScrollView *)scrollView;

/**
 * @warning Must be called before dealloc.
 */
- (void)disintegrate;

- (void)loadInitialContentWithCompletion:(void (^)(BOOL success))completion;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (id)objectsAtIndexes:(NSIndexSet *)indexes;

- (BOOL)containsObject:(id)obj;
- (BOOL)containsObjectIdenticalTo:(id)obj;

- (NSUInteger)indexOfObject:(id)obj;
- (NSUInteger)indexOfObjectIdenticalTo:(id)obj;
- (NSUInteger)indexOfObjectPassingTest:(BOOL (^)(id obj, NSUInteger idx))predicate;

- (NSIndexSet *)indexesOfObjectsPassingTest:(BOOL (^)(id obj, NSUInteger idx))predicate;

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;
- (void)enumerateObjectsWithOptions:(RSPagedItemsEnumerationOptions)opts
                         usingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;
- (void)enumerateObjectsAtIndexes:(NSIndexSet *)indexSet options:(RSPagedItemsEnumerationOptions)opts
                       usingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;


- (void)addObject:(id)obj;
- (void)addObjects:(NSArray *)objects;

- (void)insertObject:(id)obj atIndex:(NSUInteger)index;
- (void)insertObjects:(NSArray *)objects atIndex:(NSUInteger)index;

- (void)removeObject:(id)obj;
- (void)removeObjects:(NSArray *)objects;

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes;
- (void)removeObjectsPassingTest:(BOOL (^)(id obj, NSUInteger idx))predicate;

- (void)removeAllObjects;

/**
 * @param block returns YES if `obj` was updated
 */
- (void)updateObjectsUsingBlock:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))block;

- (void)replaceObjectsUsingBlock:(id (^)(id obj, NSUInteger idx, BOOL *stop))block;

/**
 * @param completion Invoked on main thread.
 */
- (void)addObjectsUsingBlock:(RSPagedItemsControllerLoadingBlock)block completion:(void (^)())completion;

/**
 * @param completion Invoked on main thread.
 */
- (void)insertObjectsAtItemsBeginningUsingBlock:(RSPagedItemsControllerLoadingBlock)block
                                     completion:(void (^)())completion;

@end


@protocol RSPagedItemsControllerDelegate <NSObject>
@optional

- (void)pagedItemsController:(RSPagedItemsController *)pagedItemsController
       didChangeItemsForType:(RSPagedItemsChangeType)changeType userInfo:(NSDictionary *)userInfo;

@end


@interface UITableViewController (RSPagedItemsController) <RSPagedItemsControllerDelegate>

- (NSInteger)sectionOfPagedItemsController:(RSPagedItemsController *)controller;

@end
