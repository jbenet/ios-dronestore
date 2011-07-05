//
//  SeventhDay Framework 1.0
//
//  Copyright Seventh Day LLC 2009. All rights reserved.
//

#import "APICollection.h"

@implementation APICollection

@synthesize models, ordered, delegates, silent;


- (id) init
{
    self = [self initWithCapacity:10];
	silent = NO;
    return self;
}

- (id) initWithCapacity:(int)cap
{
    if (self = [super init])
    {
        self.models = [NSMutableDictionary dictionaryWithCapacity: cap];
        self.ordered = [NSMutableArray arrayWithCapacity: cap];
		silent = NO;
    }
    return self;
}

- (void) addDelegate:(id)delegate
{
	if (delegate != nil) [delegates addObject:delegate];
}

- (void)setDelegate:(id)delegate
{
	[self addDelegate:delegate];
}

- (id)delegate
{
	return [delegates objectAtIndex:0];
}

- (void) updated
{
	if (silent) return;
	
	for (id d in delegates)
		[d updatedCollection:self];
}

- (int) count
{
    return [self.ordered count];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
	return [self.ordered countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (void)setSilent:(BOOL)s
{
	silent = s;
	[self updated];
}


- (BOOL) containsObject:(id)object
{
    return [self.ordered containsObject:object];
}

- (BOOL) containsModel:(APIModel *)model
{
    return [self.models objectForKey:model.APIKey] != nil;
}

- (void) addCollection:(APICollection *)c
{
	BOOL mode = self.silent;
	self.silent = YES;
	for (APIModel *m in c)
		[self insertModel:m];
	
	self.silent = mode;
}


- (void) addObject:(id)object forKey:(NSString *)key
{
    [self.ordered removeObject:[self.models objectForKey:key]];
	[self.models setObject:object forKey:key];
    [self.ordered addObject:object];
	[self updated];
}

- (void) addObject:(id)object forKey:(NSString *)key atIndex:(int)index
{
    [self.ordered removeObject:[self.models objectForKey:key]];
	[self.models setObject:object forKey:key];
    [self.ordered insertObject:object atIndex:index];
	[self updated];
}

- (void) insertModel:(APIModel *)model
{
	if (![model respondsToSelector:@selector(APIKey)] || model.APIKey == nil || [model.APIKey length] < 1)
		return; 
	
	[self.ordered removeObject:[self.models objectForKey:model.APIKey]];
    [self.models setObject:model forKey:model.APIKey];
    [self.ordered addObject:model];
	[self updated];
}

- (void) insertModel:(APIModel *)model atIndex:(int)index
{
    [self.ordered removeObject:[self.models objectForKey:model.APIKey]];
    [self.models setObject:model forKey:model.APIKey];
    [self.ordered insertObject:model atIndex:index];
	[self updated];
}

- (void) removeModel:(APIModel *)model
{
    [self.ordered removeObject:[self.models objectForKey:model.APIKey]];
    [self.models removeObjectForKey:model.APIKey];
	[self updated];
}

- (void) removeObjectAtIndex:(int)index
{
	NSObject *o = [self.ordered objectAtIndex:index];
	[self.ordered removeObjectAtIndex:index];
	if ([o respondsToSelector:@selector(APIKey)])
		[self.models removeObjectForKey:[(APIModel *)o APIKey]];
	[self updated];
}

- (void) removeObjectForKey:(NSString *)key
{
    [self removeKey:key];
}

- (void) removeKey:(NSString *)key
{
    [self.ordered removeObject:[self modelForKey:key]];
    [self.models removeObjectForKey:key];
	[self updated];
}


- (void) removeAllObjects
{
	[self.ordered removeAllObjects];
	[self.models removeAllObjects];
	[self updated];
}

- (void) clear
{
	[self removeAllObjects];
	[self updated];
}

- (APIModel *) modelForKey:(NSString *)key
{
    return [self.models objectForKey:key];
}

- (APIModel *) modelAtIndex:(int)index
{
    return [self.ordered objectAtIndex:index];
}

- (id) objectForKey:(NSString *)key
{
    return [self.models objectForKey:key];
}

- (id) objectAtIndex:(int)index
{
    return [self.ordered objectAtIndex:index];
}


- (void) sortUsingSelector:(SEL)selector
{
    [self.ordered sortUsingSelector:selector];
	[self updated];
}

- (void) dealloc
{
    self.models = nil;
    self.ordered = nil;
	self.delegates = nil;
    [super dealloc];
}

+ (APICollection *) collection
{
    return [[[APICollection alloc] init] autorelease];
}

+ (APICollection *) collectionWithCapacity:(int)cap
{
    return [[[APICollection alloc] initWithCapacity:cap] autorelease];
}

+ (APICollection *) collectionWithData:(id)data
{
	if ([data isKindOfClass:[APICollection class]])
		return (APICollection *)data;
	
	APICollection *c = [APICollection collectionWithCapacity:[data count]];
	for (APIModel *m in data)
		[c insertModel:m];
    return c;
}



@end


