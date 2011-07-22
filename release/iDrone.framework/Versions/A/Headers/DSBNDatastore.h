
#import <BsonNetwork/BsonNetwork.h>
#import "DSDatastore.h"
#import "DSQuery.h"

@interface DSBNDatastore : DSDatastore <BNRemoteServiceDelegate> {
  NSMutableDictionary *responsesByToken_;
  BNRemoteService *service_;
  int lastToken_;
}


- (id) initWithRemoteService:(BNRemoteService *)servie;

@end
