//
//  RSPagedItemsLoadManager.h
//  RSPagedItemsController
//
//  Created by rishat on 04.08.15.
//
//

#import <Foundation/Foundation.h>

#import "RSPagedItemsScrollViewDelegateProxy.h"
#import "RSPagedItemsLoader.h"

@protocol RSPagedItemsLoadManagerDelegate;

#pragma mark -

@interface RSPagedItemsLoadManager : NSObject

@property (nonatomic, readonly) RSScrollViewEdge scrollViewEdge;
@property (nonatomic, readonly) RSPagedItemsScrollViewDelegateProxy *scrollViewDelegateProxy;
@property (nonatomic, readonly) id<RSPagedItemsLoadManagerDelegate> delegate;

/**
 * Default value is YES
 */
@property BOOL enableLoading;

+ (instancetype)managerWithLoader:(id<RSPagedItemsLoader>)pagedItemsLoader
                         delegate:(id<RSPagedItemsLoadManagerDelegate>)delegate
                    forScrollView:(UIScrollView *)scrollView scrollViewEdge:(RSScrollViewEdge)scrollViewEdge;

- (void)loadInitialContentWithCompletion:(void (^)(BOOL success))completion;

@end

#pragma mark -

@protocol RSPagedItemsLoadManagerDelegate <NSObject>
@optional

- (void)pagedItemsLoadManager:(RSPagedItemsLoadManager *)manager didLoadItems:(NSArray *)items initial:(BOOL)initial;

- (void)pagedItemsLoadManager:(RSPagedItemsLoadManager *)manager didFailLoadWithError:(NSError *)error initial:(BOOL)initial;

@end
