//
//  ContactPhoneBook.m
//  PhoneBook
//
//  Created by chuonghm on 7/26/17.
//  Copyright © 2017 VNG Corp., Zalo Group. All rights reserved.
//

#import "ContactPhoneBook.h"
#import "ImageCache.h"

/**
 Macro for get UIColor from hex value

 @param hexValue - hex value
 @return - UIColor representing rgbValue
 */
#define UIColorFromHex(hexValue) \
    [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0 \
                    green:((float)((hexValue & 0x00FF00) >>  8))/255.0 \
                     blue:((float)((hexValue & 0x0000FF) >>  0))/255.0 \
                    alpha:1.0]

@implementation ContactPhoneBook

#pragma mark - Constructors

- (instancetype)initWithCNContact:(CNContact *)cnContact {
    
    self = [super init];
    // init name
    self.firstname = [cnContact givenName];
    self.lastname = [cnContact familyName];
    self.middlename = [cnContact middleName];
    
    // init avatar key
    self.avatarKey = [cnContact identifier];
    UIImage *avatar = [UIImage imageWithData:[cnContact imageData]];
    
    // Generate avatar
    if (avatar == nil) {
        [self generateAvatarImage];
    }
    
    return self;
}

#pragma mark - Getters

/**
 Getter of fullname

 @return - fullname: lastname + middlename + firstname
 */
- (NSString *)fullname {
    
    NSMutableString *showingName = [[NSMutableString alloc] init];
    
    if (_lastname != nil && [_lastname length] > 0) {
        [showingName appendString:_lastname];
    }
    if (_middlename != nil && [_middlename length] > 0) {
        [showingName appendFormat:@" %@",_middlename];
    }
    if (_firstname != nil && [_firstname length] > 0) {
        [showingName appendFormat:@" %@",_firstname];
    }
    
    // Trim space and endline at beginning and ending of name
    NSCharacterSet* charsToTrim = [NSCharacterSet characterSetWithCharactersInString:@" \n"];
    return [showingName stringByTrimmingCharactersInSet:charsToTrim];
}

#pragma mark - Override methods

- (UIImage *)getAvatarImage {
    
    return [ImageCache.sharedInstance imageFromKey:_avatarKey];
}

- (BOOL)isEqual:(id)object {
    
    ContactPhoneBook *compareObject = (ContactPhoneBook *)object;
    if ([[self fullname] isEqual:[compareObject fullname]] && [self.avatarKey isEqual:compareObject.avatarKey]) {
        return YES;
    }
    return NO;
}

#pragma mark - Utilities

/**
 Make image avatar and store to cache
 */
- (void)generateAvatarImage {
    
    // Create label contains text
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UILabel *lblNameInitialize = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        lblNameInitialize.textColor = [UIColor whiteColor];
        [lblNameInitialize setFont:[UIFont fontWithName:@"Helvetica" size:40]];
        lblNameInitialize.text = [self getRepresentCharacters];
        lblNameInitialize.textAlignment = NSTextAlignmentCenter;
        lblNameInitialize.backgroundColor = UIColorFromHex(0x49BA96);
        
        // Render label to image
        UIGraphicsBeginImageContext(lblNameInitialize.frame.size);
        [lblNameInitialize.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // Store data to cache
        [ImageCache.sharedInstance storeImage:returnImage
                                      withKey:self.avatarKey];

    });
}

/**
 Get represent characters from name

 @return - characters represent the contact's name
 */
- (NSString *)getRepresentCharacters {
    
    NSArray *tokensOfFullname = [[self fullname] componentsSeparatedByString:@" "];
    NSString *representName;
    
    if ([tokensOfFullname count] > 1) {   // fullname has more than 1 word.
        @try {
            // Get first characters of first and last word.
            NSString *firstToken = [tokensOfFullname objectAtIndex:0];
            NSString *lastToken = [tokensOfFullname objectAtIndex:[tokensOfFullname count]-1];
            
            // Link the two characters.
            representName = [[NSString alloc] initWithFormat:@"%c%c",[firstToken characterAtIndex:0],[lastToken characterAtIndex:0]];
        } @catch (NSException *exception) {
            representName = @"";
        }
        
    } else {
        // Get only the first character of the only word for representing name.
        @try {
            NSString *firstToken = [tokensOfFullname objectAtIndex:0];
            representName = [[NSString alloc] initWithFormat:@"%c",[firstToken characterAtIndex:0]];
        } @catch (NSException *exception) {
            representName = @"";
        }
        
    }
    return representName;
}


@end
