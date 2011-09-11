
#import <BsonNetwork/BsonNetwork.h>
#import "DSDatastore.h"
#import "DSQuery.h"

@interface DSBNDatastore : DSDatastore <BNRemoteServiceDelegate> {
  NSMutableDictionary *responsesByToken_;
  BNRemoteService *service_;
  int lastToken_;

  NSTimeInterval timeoutTimeInterval;
}

@property (nonatomic, assign) NSTimeInterval timeoutTimeInterval;

- (id) initWithRemoteService:(BNRemoteService *)servie;

@end
