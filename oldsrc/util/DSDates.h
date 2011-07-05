//
//  SeventhDay Framework 1.0
//
//  Copyright Seventh Day LLC 2009. All rights reserved.
//

@interface APIDates : NSObject {
    
  NSDateFormatter *dater;
	NSDateFormatter *UTCISODater;
	NSDateFormatter *localISODater;
	NSDateFormatter *shortDater;
	
}

@property (nonatomic, retain) NSDateFormatter *dater;
@property (nonatomic, retain) NSDateFormatter *UTCISODater;
@property (nonatomic, retain) NSDateFormatter *localISODater;
@property (nonatomic, retain) NSDateFormatter *shortDater;


- (NSString *) stringFromUTCDate:(NSDate *)date;
- (NSString *) stringFromLocalDate:(NSDate *)date;
- (NSString *) shortStringFromDate: (NSDate *)date;
- (NSString *) stringFromDate: (NSDate *)date;

+ (APIDates *) dates;

@end