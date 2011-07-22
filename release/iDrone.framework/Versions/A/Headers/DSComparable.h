

@protocol DSComparable<NSObject>
- (NSComparisonResult) compare:(id<DSComparable>)other;
@end

@interface NSString (DSComparable) <DSComparable> 
@end

