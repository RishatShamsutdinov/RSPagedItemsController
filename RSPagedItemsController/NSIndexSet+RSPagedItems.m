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
