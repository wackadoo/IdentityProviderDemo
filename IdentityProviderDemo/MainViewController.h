//
//  MainViewController.h
//  IdentityProviderDemo
//
//  Created by Sascha Lange on 13.01.12.
//  Copyright (c) 2012 Universität Freiburg. All rights reserved.
//

#import "FlipsideViewController.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, UIPopoverControllerDelegate>

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;

@property (assign, nonatomic) IBOutlet UIActivityIndicatorView* activityIndicator;

@property (retain, nonatomic) IBOutlet UILabel *nicknameLabel;
@property (retain, nonatomic) IBOutlet UILabel *nameLabel;
@property (retain, nonatomic) IBOutlet UILabel *emailLabel;
@property (retain, nonatomic) IBOutlet UIButton *reloadButton;
@property (retain, nonatomic) IBOutlet UIButton *signoutButton;

@property (strong, nonatomic) NSString* accessToken;


@property (retain, nonatomic) NSMutableData* receivedData;
@property int statusCode;
@property (retain, nonatomic) NSDictionary* headers;

- (IBAction)reload:(id)sender;
- (IBAction)signout:(id)sender;

@end
