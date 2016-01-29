//
//  RSPagedItemsCollectionProtocol.h
//  RSPagedItemsController
//
//  Created by rishat on 20.01.16.
//
//

#import <Foundation/Foundation.h>

@protocol RSPagedItemsCollection <NSObject>

@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) id firstObject;
@property (nonatomic, readonly) id lastObject;

+ (BOOL)allowsDuplicates;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (id)objectsAtIndexes:(NSIndexSet *)indexes;

- (BOOL)containsObject:(id)obj;

- (NSUInteger)indexOfObject:(id)obj;
- (NSUInteger)indexOfObjectIdenticalTo:(id)obj;
- (NSUInteger)indexOfObjectPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;

- (NSIndexSet *)indexesOfObjectsPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;

- (void)enumerateObjectsUsingBlock:(void (^)(id, NSUInteger, BOOL *))block;

- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts
                         usingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;

- (void)enumerateObjectsAtIndexes:(NSIndexSet *)indexes options:(NSEnumerationOptions)opts
                       usingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;

- (void)insertObjects:(NSArray *)objects atIndexes:(NSIndexSet *)indexes;
- (void)insertObjects:(NSArray *)objects atIndex:(NSUInteger)index;

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes;
- (void)removeObjectsPassingTest:(BOOL (^)(id, NSUInteger, BOOL *))predicate;
- (void)removeAllObjects;

@end
