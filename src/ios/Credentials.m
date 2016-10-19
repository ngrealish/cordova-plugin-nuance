//
//
//

#import "Credentials.h"

@implementation Credentials
@synthesize appId, appKey;

//PLEASE ENTER YOUR APP ID INSIDE THE QUOTES BELOW
NSString* APP_ID = @"";
NSString* SKSAppKey = @"";
NSString* SKSServerHost = @"sslsandbox.nmdp.nuancemobility.net";
NSString* SKSServerPort = @"443";

-(NSString *) getAppId {
    return [NSString stringWithString:APP_ID];
};

-(NSString *) getServerUrl {
    return [NSString stringWithFormat:@"nmsps://%@@%@:%@", APP_ID, SKSServerHost, SKSServerPort];
};

@end
