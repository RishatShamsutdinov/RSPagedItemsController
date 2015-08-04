//
//  NSIndexSet+RSPagedItems.h
//  RSPagedItemsController
//
//  Created by rishat on 04.08.15.
//
//

#import <Foundation/Foundation.h>

@interface NSIndexSet (RSPagedItems)

- (NSArray *)rs_indexPathsForRowsInSection:(NSInteger)section;

- (NSArray *)rs_indexPathsForItemsInSection:(NSInteger)section;

@end
