
@class DSDrone;

@interface DroneTest : GHTestCase {
}
- (void) subtest_basic:(DSDrone *)drone;
- (void) subtest_stress:(NSArray *)array people:(int)numpeople;
@end

