//
//  RSPagedItemsController.h
//  RSPagedItemsController
//
//  Created by rishat on 04.08.15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "RSPagedItemsTypes.h"
#import "RSPagedItemsLoader.h"
#import "NSIndexSet+RSPagedItems.h"

@protocol RSPagedItemsControllerDelegate, RSPaLoad;

typedef NS_ENUM(NSUInteger, RSPagedItemsChangeType) {
    RSPagedItemsChangeReplace,
    RSPagedItemsChangeAppend,
    RSPagedItemsChangeInsert,
    RSPagedItemsChangeUpdate,
    RSPagedItemsChangeDelete
};

typedef void(^RSPagedItemsControllerHandler)(NSArray *items);
typedef void(^RSPagedItemsControllerLoadingBlock)(RSPagedItemsControllerHandler handler);

@interface RSPagedItemsController : NSObject

@property (nonatomic, readonly) id firstItem;
@property (nonatomic, readonly) id lastItem;

@property (nonatomic, readonly) NSUInteger itemsCount;

@property (nonatomic, weak) id<RSPagedItemsControllerDelegate> delegate;


+ (instancetype)controllerWithDelegate:(id<RSPagedItemsControllerDelegate>)delegate;

- (void)integrateWithScrollView:(UIScrollView *)scrollView onEdge:(RSScrollViewEdge)edge
                    usingLoader:(id<RSPagedItemsLoader>)loader;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;

- (void)addObject:(id)obj;
- (void)addObjects:(NSArray *)objects;

- (void)insertObject:(id)obj atIndex:(NSUInteger)index;
- (void)insertObjects:(NSArray *)objects atIndex:(NSUInteger)index;

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes;
- (void)removeObjectsPassingTest:(BOOL (^)(id obj, NSUInteger idx))predicate;

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

- (void)pagedItemsController:(RSPagedItemsController *)pagedItemsController
     didChangeItemsAtIndexes:(NSIndexSet *)indexes forChangeType:(RSPagedItemsChangeType)changeType;

@end


@interface UITableViewController (RSPagedItemsController) <RSPagedItemsControllerDelegate>

- (NSInteger)sectionOfPagedItemsController:(RSPagedItemsController *)controller;

@end