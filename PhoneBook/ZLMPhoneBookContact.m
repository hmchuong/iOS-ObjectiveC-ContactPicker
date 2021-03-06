//
//  PhoneBookContact.m
//  PhoneBook
//
//  Created by chuonghm on 8/10/17.
//  Copyright © 2017 VNG Corp., Zalo Group. All rights reserved.
//

@import UIKit;
#import "ZLMPhoneBookContact.h"
#import "ZLMImageCache.h"

@implementation ZLMPhoneBookContact

- (instancetype)init {
    
    self = [super init];
    
    _firstName = @"";
    _middleName = @"";
    _lastName = @"";
    _identifier = @"";
    
    return self;
}

- (instancetype)initWithCNContact:(CNContact *)cnContact {
    
    self = [super init];
    
    _firstName = cnContact.givenName;
    _middleName = cnContact.middleName;
    _lastName = cnContact.familyName;
    _identifier = cnContact.identifier;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        UIImage *avatar = [UIImage imageWithData:[cnContact imageData]];
        
        // if has avatar -> store to cache
        if (avatar != nil) {
            [ZLMImageCache.sharedInstance storeImage:avatar
                                          withKey:self.identifier];
        }
    });
    
    return self;
}

- (instancetype)initWithABRecordRef:(ABRecordRef)aBRecordRef {
    
    self = [super init];
    
    // Name
    CFStringRef firstName, middleName, lastName;
    firstName = ABRecordCopyValue(aBRecordRef, kABPersonFirstNameProperty);
    middleName = ABRecordCopyValue(aBRecordRef, kABPersonMiddleNameProperty);
    lastName = ABRecordCopyValue(aBRecordRef, kABPersonLastNameProperty);
    
    _firstName = [NSString stringWithFormat:@"%@",firstName];
    _middleName = [NSString stringWithFormat:@"%@",middleName];
    _lastName = [NSString stringWithFormat:@"%@",lastName];

    // ID
    ABRecordID recordID = ABRecordGetRecordID(aBRecordRef);
    _identifier = [NSString stringWithFormat:@"%d", recordID];
    
    // Avatar
    UIImage *avatar;
    if (ABPersonHasImageData(aBRecordRef)) {
        avatar = [UIImage imageWithData:(__bridge NSData *)ABPersonCopyImageData(aBRecordRef)];
    }
    
    // Store to cache
    if (avatar != nil) {
        [ZLMImageCache.sharedInstance storeImage:avatar
                                      withKey:_identifier];
    }
    
    return self;
}

@end
