//
//  User.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CPVenue.h"

#define kDaysOfTrialAccessWithoutInviteCode 30

@interface User : NSObject <NSCoding>

@property (strong, nonatomic) NSString *nickname;
@property (nonatomic) int userID;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *jobTitle;
@property (strong, nonatomic) NSString *status;
@property (strong, nonatomic) NSArray *skills;
@property (nonatomic, readonly) BOOL hasAnyTopSkills;
@property (nonatomic) CLLocationCoordinate2D location;
@property (strong, nonatomic) NSString *bio;
@property (nonatomic) int sponsorId;
@property (strong, nonatomic) NSString *sponsorNickname;
@property (nonatomic) BOOL facebookVerified;
@property (nonatomic) BOOL linkedInVerified;
@property (strong, nonatomic) NSString *hourlyRate;
@property (nonatomic) double totalEarned;
@property (nonatomic) int totalHours;
@property (nonatomic) double totalSpent;
@property (strong, nonatomic) NSString *photoURLString;
@property (nonatomic) double distance;
@property (nonatomic) BOOL checkedIn;
@property (strong, nonatomic) CPVenue *placeCheckedIn;
@property (strong, nonatomic) NSDate *checkoutEpoch;
@property (strong, nonatomic) NSString *join_date;
@property (nonatomic) int trusted_by;
@property (strong, nonatomic) NSArray *workInformation;
@property (nonatomic, readonly) BOOL hasAnyWorkInformation;
@property (strong, nonatomic) NSArray *educationInformation;
@property (nonatomic, readonly) BOOL hasAnyEducationInformation;
@property (nonatomic, readonly) BOOL hasAnyBadges;
@property (strong, nonatomic) NSDictionary *reviews;
@property (strong, nonatomic) NSMutableArray *checkInHistory;
@property (nonatomic, readonly) NSMutableArray *favoritePlaces;
@property (nonatomic, readonly) BOOL hasAnyFavoritePlaces;
@property (strong, nonatomic) NSString *majorJobCategory;
@property (strong, nonatomic) NSString *minorJobCategory;
@property (nonatomic) BOOL enteredInviteCode;
@property (strong, nonatomic) NSDate *joinDate;
@property (strong, nonatomic) NSMutableArray *badges;
@property (strong, nonatomic) NSString *smartererName;
@property (nonatomic) BOOL checkInIsVirtual;
@property (nonatomic) BOOL contactsOnlyChat;
@property (nonatomic) BOOL isContact;
@property (nonatomic) BOOL hasChatHistory;
@property (strong, nonatomic) NSString *linkedInPublicProfileUrl;
@property (strong, nonatomic) NSNumber *numberOfContactRequests;
@property (strong, nonatomic) NSString *profileURLVisibility;


-(void)loadUserResumeData:(void (^)(NSError *error))completion;
-(id)initFromDictionary:(NSDictionary *)userDict;
-(NSString *)firstName;

-(NSURL *)photoURL;

- (void)setEnteredInviteCodeFromJSONString:(NSString *)enteredInviteCodeString;
- (void)setJoinDateFromJSONString:(NSString *)dateString;

- (BOOL)isDaysOfTrialAccessWithoutInviteCodeOK;
- (NSComparisonResult) compareDistanceToUser:(User *)otherUser;

@end