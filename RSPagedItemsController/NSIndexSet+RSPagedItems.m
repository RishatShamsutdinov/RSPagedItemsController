//
//  NSIndexSet+RSPagedItems.m
//  RSPagedItemsController
//
//  Created by rishat on 04.08.15.
//
//

#import "NSIndexSet+RSPagedItems.h"
#import <UIKit/UIKit.h>

@implementation NSIndexSet (RSPagedItems)

- (NSArray *)_rs_mapToIndexPath:(NSIndexPath * (^)(NSUInteger idx))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];

    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [result addObject:block(idx)];
    }];

    return result;
}

- (NSArray *)rs_indexPathsForRowsInSection:(NSInteger)section {
    return [self _rs_mapToIndexPath:^NSIndexPath *(NSUInteger idx) {
        return [NSIndexPath indexPathForRow:idx inSection:section];
    }];
}

- (NSArray *)rs_indexPathsForItemsInSection:(NSInteger)section {
    return [self _rs_mapToIndexPath:^NSIndexPath *(NSUInteger idx) {
        return [NSIndexPath indexPathForItem:idx inSection:section];
    }];
}

@end
