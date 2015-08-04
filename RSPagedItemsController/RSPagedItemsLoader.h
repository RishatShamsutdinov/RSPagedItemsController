//
//  RSPagedItemsLoader.h
//  RSPagedItemsController
//
//  Created by rishat on 04.08.15.
//
//

#import <Foundation/Foundation.h>

@protocol RSPagedItemsLoaderDelegate;

@protocol RSPagedItemsLoader <NSObject>

@property (nonatomic, weak) id<RSPagedItemsLoaderDelegate> delegate;

- (void)loadMoreIfNeededWithCompletion:(void (^)(BOOL success))completion;

/**
 * @return Copy of current loader with resetted cursor.
 */
- (instancetype)loaderByResettingCursor;

@end

@protocol RSPagedItemsLoaderDelegate <NSObject>
@optional

- (void)pagedItemsLoader:(id<RSPagedItemsLoader>)pagedItemsLoader didLoadItems:(NSArray *)items initial:(BOOL)initial;

- (void)pagedItemsLoader:(id<RSPagedItemsLoader>)pagedItemsLoader didFailLoadWithError:(NSError *)error initial:(BOOL)initial;

- (void)pagedItemsLoaderDidStartLoading:(id<RSPagedItemsLoader>)pagedItemsLoader;
- (void)pagedItemsLoaderDidFinishLoading:(id<RSPagedItemsLoader>)pagedItemsLoader;

@end