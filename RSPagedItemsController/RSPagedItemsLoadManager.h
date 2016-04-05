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

#import "RSPagedItemsScrollViewDelegateProxy.h"
#import "RSPagedItemsLoader.h"

@protocol RSPagedItemsLoadManagerDelegate;

#pragma mark -

@interface RSPagedItemsLoadManager : NSObject

@property (nonatomic, readonly) RSScrollViewEdge scrollViewEdge;
@property (nonatomic, readonly) RSPagedItemsScrollViewDelegateProxy *scrollViewDelegateProxy;
@property (nonatomic, weak, readonly) id<RSPagedItemsLoadManagerDelegate> delegate;

/**
 * Default value is YES
 */
@property BOOL enableLoading;

+ (instancetype)managerWithLoader:(id<RSPagedItemsLoader>)pagedItemsLoader
                         delegate:(id<RSPagedItemsLoadManagerDelegate>)delegate
                    forScrollView:(UIScrollView *)scrollView
                   scrollViewEdge:(RSScrollViewEdge)scrollViewEdge
          allowsActivityIndicator:(BOOL)allowsActivityIndicator;

- (void)loadInitialContentWithCompletion:(void (^)(BOOL success))completion;

- (void)disintegrate;

@end

#pragma mark -

@protocol RSPagedItemsLoadManagerDelegate <NSObject>
@optional

- (void)pagedItemsLoadManager:(RSPagedItemsLoadManager *)manager didLoadItems:(NSArray *)items initial:(BOOL)initial;

- (void)pagedItemsLoadManager:(RSPagedItemsLoadManager *)manager didFailLoadWithError:(NSError *)error initial:(BOOL)initial;

@end
