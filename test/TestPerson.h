
#import "DSModel.h"
#import "DSAttribute.h"

@class DSCollection;


@interface TestCompany : NSObject <DSSerializableValue> {
  NSString *name;
  NSString *url;
  int employees;
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) int employees;
- (BOOL) isEqualToCompany:(TestCompany *)other;
@end



@interface TestPerson : DSModel {
  NSString *first;
  NSString *last;
  NSString *phone;
  float awesomesauce;
  int age;

  TestPerson *father;
  TestPerson *mother;
  DSCollection *children;

  NSMutableArray *titles;
  NSMutableArray *titles2;
  NSMutableDictionary *computers;
  NSMutableDictionary *computers2;

  TestCompany *company;
  NSMutableArray *previousCompanies;
  NSMutableDictionary *clientCompanies;
}

@property (nonatomic, copy) NSString *first;
@property (nonatomic, copy) NSString *last;
@property (nonatomic, copy) NSString *phone;

@property (nonatomic, assign) float awesomesauce;
@property (nonatomic, assign) int age;


@property (nonatomic, retain) TestPerson *father;
@property (nonatomic, retain) TestPerson *mother;
@property (nonatomic, retain) DSCollection *children;

@property (nonatomic, retain) NSMutableArray *titles;
@property (nonatomic, retain) NSMutableArray *titles2;
@property (nonatomic, retain) NSMutableDictionary *computers;
@property (nonatomic, retain) NSMutableDictionary *computers2;

@property (nonatomic, retain) TestCompany *company;
@property (nonatomic, retain) NSMutableArray *previousCompanies;
@property (nonatomic, retain) NSMutableDictionary *clientCompanies;


+ (DSCollection *) allPeople;

@end
