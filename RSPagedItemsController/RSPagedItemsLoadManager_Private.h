//
//  RSPagedItemsLoadManager_Private.h
//  RSPagedItemsController
//
//  Created by rishat on 06.10.16.
//
//

#import "RSPagedItemsLoadManager.h"

@interface RSPagedItemsLoadManager ()

+ (instancetype)managerWithLoader:(id<RSPagedItemsLoader>)pagedItemsLoader
                         delegate:(id<RSPagedItemsLoadManagerDelegate>)delegate
                   scrollViewEdge:(RSScrollViewEdge)scrollViewEdge
          allowsActivityIndicator:(BOOL)allowsActivityIndicator;

- (void)loadInitialContentWithCompletion:(void (^)(BOOL success))completion;

- (void)integrateWithScrollView:(UIScrollView *)scrollView;

- (void)disintegrate;

@end
