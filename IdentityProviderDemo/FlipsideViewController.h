//
//  FlipsideViewController.h
//  IdentityProviderDemo
//
//  Created by Sascha Lange on 13.01.12.
//  Copyright (c) 2012 Universität Freiburg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FlipsideViewController;

@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

@interface FlipsideViewController : UIViewController <UITextFieldDelegate>

@property (assign, nonatomic) IBOutlet id <FlipsideViewControllerDelegate> delegate;

@property (assign, nonatomic) IBOutlet UITextField* login;
@property (assign, nonatomic) IBOutlet UITextField* password;
@property (assign, nonatomic) IBOutlet UILabel* notice;
@property (assign, nonatomic) IBOutlet UIActivityIndicatorView* activityIndicator;

- (IBAction)done:(id)sender;
- (IBAction)connect:(id)sender;

@end

