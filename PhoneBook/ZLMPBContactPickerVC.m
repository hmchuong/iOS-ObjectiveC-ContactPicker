//
//  ZLMPBContactPickerVC.m
//  PhoneBook
//
//  Created by chuonghm on 8/7/17.
//  Copyright © 2017 VNG Corp., Zalo Group. All rights reserved.
//

#import "ZLMPBContactPickerVC.h"
#import "MBProgressHUD.h"
#import "HMCThreadSafeMutableArray.h"
#import "HMCThreadSafeMutableDictionary.h"
#import "NSString+Extension.h"

@interface ZLMPBContactPickerVC ()

@property (weak, nonatomic) IBOutlet ZLMContactPickerView *contactPicker;

@end

@implementation ZLMPBContactPickerVC

#pragma mark - Life cycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self updateContactData];
    
    // Listen when contacts change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateContactData)
                                                 name:CNContactStoreDidChangeNotification
                                               object:nil];
}

#pragma mark - Utilities

/**
 Update phone book contacts Data
 */
- (void)updateContactData {
    
    // Show progress view
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    });
    
    [ZLMPhoneBookContactLoader.sharedInstance getPhoneBookContactsWithCompletion: ^(BOOL granted, NSArray *contacts) {
        
        NSLog(@"No. loaded contacts: %lu",(unsigned long)[contacts count]);
        
        if (!granted && [contacts count] == 0) {
            // Hide progress view
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            
            // Request permission
            [self showContactPermissionRequest];
        }
        
        NSDate *_operation = [NSDate date];

        // Set sectioned contacts for contact picker
        [self.contactPicker setSectionedContacts:[self sectionedArrayFromContacts:contacts]];
        
        // Hide progress view
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
        
        NSLog(@"Loading contacts time: %.3f s", -[_operation timeIntervalSinceNow]);
    } callbackQueue:[NSOperationQueue currentQueue]];
}

/**
 Get sectioned contacts array

 @param contacts - ZLMPhoneBookContact array to get
 @return - sectioned contacts array to pass to ContactPicker
 */
- (NSArray *)sectionedArrayFromContacts:(NSArray<ZLMPhoneBookContact *> *) contacts {
    
    // Group contacts in sections
    NSDictionary *tableContents = [self groupPhoneBookContacts:contacts];
    
    // Build array from sections
    NSMutableArray *sectionedContacts = [[NSMutableArray alloc] init];
    NSArray *sortedKeys = [[tableContents allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    for (id key in sortedKeys) {
        [sectionedContacts addObject:key];
        [sectionedContacts addObjectsFromArray:tableContents[key]];
    }
    
    return sectionedContacts;
}

/**
 Group contacts to sections

 @param contacts - ZLMPhoneBookContact array
 @return - dictionary includes sections, each section contains contacts
 */
- (NSDictionary *)groupPhoneBookContacts:(NSArray<ZLMPhoneBookContact *> *) contacts {
    
    NSMutableDictionary *tableContents = [[NSMutableDictionary alloc] init];
    
    for (ZLMPhoneBookContact *contact in contacts) {
        
        // Init contact cell from contact
        ZLMPhoneBookContactNIO *contactCell = [[ZLMPhoneBookContactNIO alloc] initWithPhoneBookContact: contact];
        if ([[contactCell fullname] length] == 0) {
            continue;
        }
        
        NSString *section = [contactCell.fullname getFirstChar];
        
        // Add contact to section
        NSMutableArray *sectionArray = tableContents[section];
        if (sectionArray == nil) {
            sectionArray = [[NSMutableArray alloc] init];
        }
        [sectionArray addObject:contactCell];
        tableContents[section] = sectionArray;
    }
    
    return tableContents;
}

/**
 Show pop up request allowing this app accesses phonebook contacts
 */
- (void)showContactPermissionRequest {
    
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Access phone book"
                                                                  message:@"This application request to access phone book contact for right behavior. Click 'Setting' and turn on 'Phone book' permission"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Setting"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          
                                                          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                      }];
    
    UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"Cancel"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}



@end
