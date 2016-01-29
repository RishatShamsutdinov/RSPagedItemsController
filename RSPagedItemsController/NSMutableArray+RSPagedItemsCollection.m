//
//  NSMutableArray+RSPagedItemsCollection.m
//  RSPagedItemsController
//
//  Created by rishat on 20.01.16.
//
//

#import "NSMutableArray+RSPagedItemsCollection.h"

#import <RSFoundationUtils/NSMutableArray+FoundationUtils.h>

@implementation NSMutableArray (RSPagedItemsCollection)

+ (BOOL)allowsDuplicates {
    return YES;
}

- (void)insertObjects:(NSArray *)objects atIndex:(NSUInteger)index {
    [self rs_insertObjects:objects atIndex:index];
}

- (void)removeObjectsPassingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate {
    [self rs_removeObjectsPassingTest:predicate];
}

@end
