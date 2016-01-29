//
//  NSMutableOrderedSet+RSPagedItemsCollection.m
//  RSPagedItemsController
//
//  Created by rishat on 20.01.16.
//
//

#import "NSMutableOrderedSet+RSPagedItemsCollection.h"

@implementation NSMutableOrderedSet (RSPagedItemsCollection)

+ (BOOL)allowsDuplicates {
    return NO;
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)obj {
    return [self indexOfObjectPassingTest:^BOOL(id enumObj, NSUInteger idx, BOOL *stop) {
        return (obj == enumObj);
    }];
}

- (void)removeObjectsPassingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate {
    NSIndexSet *indexes = [self indexesOfObjectsPassingTest:predicate];

    [self removeObjectsAtIndexes:indexes];
}

- (void)insertObjects:(NSArray *)objects atIndex:(NSUInteger)index {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, objects.count)];

    [self insertObjects:objects atIndexes:indexSet];
}

@end
