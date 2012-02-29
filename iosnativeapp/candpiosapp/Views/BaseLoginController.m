//
//  BaseLoginController.m
//  candpiosapp
//
//  Created by Andrew Hammond on 2/28/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "BaseLoginController.h"
#import "AppDelegate.h"
#import "AFNetworking.h"
#import "UAPush.h"



@interface BaseLoginController()
-(void)pushAliasUpdate;
-(void)handleCommonCreate:(NSString*)username
                 password:(NSString*)password
                 nickname:(NSString*)nickname
               facebookId:(NSString*)facebookId
               completion:(void (^)(NSError *error, id JSON))completion;
@end

@implementation BaseLoginController
@synthesize httpClient;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self)
	{
		httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kCandPWebServiceUrl]];
	}
	return self;
}

-(void)pushAliasUpdate {
    // Set my UserID as an UrbanAirship alias for push notifications
    NSString *userid = (NSString *)[AppDelegate instance].settings.candpUserId;
    NSLog(@"Pushing aliases to UrbanAirship: %@", userid);
    [[UAPush shared] updateAlias:userid];
}

-(void)handleCommonCreate:(NSString*)username
				 password:(NSString*)password
				 nickname:(NSString*)nickname
			   facebookId:(NSString*)facebookId
			   completion:(void (^)(NSError *error, id JSON))completion
{
	// kick off the request to the candp server
	NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
	[loginParams setObject:@"signup" forKey:@"action"];
	[loginParams setObject:username forKey:@"signupUsername"];
	if(facebookId)
	{
		[loginParams setObject:[NSNumber numberWithInt:1] forKey:@"fb_connect"];
		[loginParams setObject:facebookId forKey:@"fb_id"];
	}
	else
	{
		[loginParams setObject:password forKey:@"signupPassword"];
		[loginParams setObject:password forKey:@"signupConfirm"];
		[loginParams setObject:nickname forKey:@"signupNickname"];
	}
	[loginParams setObject:[NSNumber numberWithInt:1] forKey:@"signupAcceptTerms"];
	[loginParams setObject:@"json" forKey:@"type"];
	NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"signup.php" parameters:loginParams];
	AFJSONRequestOperation *postOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
#if DEBUG        
		NSDictionary *jsonDict = json;
		NSLog(@"Result code: %d (%@)", [response statusCode], [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]] );
		
		NSLog(@"Header fields:" );
		[[response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSLog(@"     %@ : '%@'", key, obj );
			
		}];
		
		NSLog(@"Json fields:" );
		[jsonDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSLog(@"     %@ : '%@'", key, obj );
			
		}];
#endif		
        completion(nil, json);
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		// handle error
		NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription] );
        completion(error, nil);
		
	} ];
	
	[[NSOperationQueue mainQueue] addOperation:postOperation];
}


@end
