//
//  SeventhDay Framework 1.0
//
//  Copyright Seventh Day LLC 2009. All rights reserved.
//

#import "APIDates.h"
#import "APIConnection.h"

@implementation APIDates

@synthesize dater, localISODater, UTCISODater, shortDater;

- (id) init
{
    if (self = [super init])
    {
    	self.dater = [[NSDateFormatter alloc] init];
		[dater setDateStyle:NSDateFormatterMediumStyle];
		[dater setTimeStyle:NSDateFormatterShortStyle];
//        [dater setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];

    	self.localISODater = [[NSDateFormatter alloc] init];
		[localISODater setDateFormat:@"yyyy-MM-dd'T'HH:mm:SS"];

    	self.UTCISODater = [[NSDateFormatter alloc] init];
		[UTCISODater setDateFormat:@"yyyy-MM-dd'T'HH:mm:SS"];
        [UTCISODater setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];

    	self.shortDater = [[NSDateFormatter alloc] init];
		[shortDater setDateStyle:NSDateFormatterShortStyle];
		[shortDater setTimeStyle:NSDateFormatterShortStyle];
//        [shortDater setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
		
    }
    return self;
}

- (NSString *) stringFromUTCDate:(NSDate *)date
{
    return [UTCISODater stringFromDate:date];
}

- (NSString *) stringFromLocalDate:(NSDate *)date
{
    return [localISODater stringFromDate:date];
}

- (NSString *) shortStringFromDate: (NSDate *)date
{
    return [shortDater stringFromDate:date];
}

- (NSString *) stringFromDate: (NSDate *)date 
{
    return [dater stringFromDate:date];
}

+ (APIDates *) dates
{
    return [[APIConnection main] dates];
}

- (void) dealloc
{
    self.dater = nil;
    self.UTCISODater = nil;
    self.localISODater = nil;
    self.shortDater = nil;
    [super dealloc];
}

@end