//
//  FlipsideViewController.m
//  IdentityProviderDemo
//
//  Created by Sascha Lange on 13.01.12.
//  Copyright (c) 2012 Universität Freiburg. All rights reserved.
//

#import "FlipsideViewController.h"

@implementation FlipsideViewController

@synthesize delegate = _delegate;
@synthesize login = _login;
@synthesize password = _password;
@synthesize notice = _notice;
@synthesize activityIndicator = _activityIndicator;

- (void)awakeFromNib
{
  self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [self.login becomeFirstResponder];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
      return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
      return YES;
  }
}


#pragma mark - UI State Changes


-(void)startActivity
{
  self.login.userInteractionEnabled = NO;
  self.password.userInteractionEnabled = NO;
  self.notice.hidden = YES;
  [self.activityIndicator startAnimating];
}

-(void)stopActivity
{
  self.login.userInteractionEnabled = YES;
  self.password.userInteractionEnabled = YES;
  [self.activityIndicator stopAnimating];
  
  self.notice.text = @"Could not connect to server.";
  self.notice.hidden = NO;
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

- (IBAction)connect:(id)sender
{
  if ([self.login.text length] == 0 ||
      [self.password.text length] == 0) {
    return;
  }
  
  [self.login resignFirstResponder];
  [self.password resignFirstResponder];
  
  [self startActivity];
  
  
  [NSTimer scheduledTimerWithTimeInterval:10. target:self selector:@selector(stopActivity) userInfo:nil repeats:NO];
  
  
//  [self stopActivity];
}


#pragma mark - Textfield delegate

-(void)textFieldDidBeginEditing:(UITextField *)textField
{  
  self.notice.hidden = YES;
};

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  [self connect:self];
  return YES;
};

@end
