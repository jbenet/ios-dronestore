//
//  SeventhDay Framework 1.0
//
//  Copyright Seventh Day LLC 2009. All rights reserved.
//

#import "APIModel.h"


@class APICollection;

@protocol APICollectionDelegate

- (void) updatedCollection:(APICollection *)collection;
/*
@optional

- (void) collection:(APICollection *) willInsertModel:(APIModel *)model;
- (void) collection:(APICollection *)  didInsertModel:(APIModel *)model;
- (void) collection:(APICollection *) willRemoveModel:(APIModel *)model;
- (void) collection:(APICollection *)  didRemoveModel:(APIModel *)model;
*/
@end



@interface APICollection : NSObject <NSFastEnumeration> {
    
    NSMutableDictionary *models;
    NSMutableArray *ordered;
    
	NSMutableArray *delegates;
	
	BOOL silent;
}

@property (nonatomic, retain) NSMutableDictionary *models;
@property (nonatomic, retain) NSMutableArray *ordered;
@property (nonatomic, retain) NSMutableArray *delegates;
@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) BOOL silent;

- (id)initWithCapacity:(int)cap;

- (int) count;

- (BOOL) containsObject:(id)object;
- (BOOL) containsModel:(APIModel *)model;

- (void) addDelegate:(id)delegate;

- (void) addObject:(id)object forKey:(NSString *)key;
- (void) addObject:(id)object forKey:(NSString *)key atIndex:(int)index;

- (void) insertModel:(APIModel *)model;
- (void) insertModel:(APIModel *)model atIndex:(int)index;

- (void) removeObjectAtIndex:(int)index;
- (void) removeObjectForKey:(NSString *)key;
- (void) removeModel:(APIModel *)model;
- (void) removeKey:(NSString *)key;

- (void) removeAllObjects;
- (void) clear;

- (APIModel *) modelForKey:(NSString *)key;
- (APIModel *) modelAtIndex:(int)index;

- (id) objectForKey:(NSString *)key;
- (id) objectAtIndex:(int)index;

- (void) sortUsingSelector:(SEL)selector;
- (void) reverse;

+ (APICollection *) collectionWithData:(id)data;
+ (APICollection *) collectionWithCapacity:(int)cap;
+ (APICollection *) collection;

@end
