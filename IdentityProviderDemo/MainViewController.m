//
//  MainViewController.m
//  IdentityProviderDemo
//
//  Created by Sascha Lange on 13.01.12.
//  Copyright (c) 2012 Universität Freiburg. All rights reserved.
//

#import "MainViewController.h"
#import "SBJson.h"

#define SERVER_BASE @"http://localhost:3000"

@interface MainViewController(InternalProtocol)
-(IBAction)togglePopover:(id)sender;
@end

@implementation MainViewController

@synthesize flipsidePopoverController = _flipsidePopoverController;
@synthesize accessToken = _accessToken;
@synthesize receivedData = _receivedData;
@synthesize statusCode = _statusCode;
@synthesize headers = _headers;
@synthesize activityIndicator = _activityIndicator;
@synthesize nicknameLabel = _nicknameLabel;
@synthesize nameLabel = _nameLabel;
@synthesize emailLabel = _emailLabel;
@synthesize reloadButton = _reloadButton;
@synthesize signoutButton = _signoutButton;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];

}

- (void)viewDidUnload
{
  [self setReloadButton:nil];
  [self setSignoutButton:nil];
  [self setNicknameLabel:nil];
  [self setNameLabel:nil];
  [self setEmailLabel:nil];
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (!self.accessToken) {
    [self togglePopover:self];
  }
  else {
    [self reload:self];
  }
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

#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{

  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    [self reload:self];
  }
  [self dismissModalViewControllerAnimated:YES];    
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.flipsidePopoverController = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
        
/*        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            self.flipsidePopoverController = popoverController;
            popoverController.delegate = self;
        } */
    }
}

- (void)dealloc
{
  [_flipsidePopoverController release];
  self.accessToken = nil;
  self.receivedData = nil;
  self.headers = nil;
  [_reloadButton release];
  [_signoutButton release];
  [_nicknameLabel release];
  [_nameLabel release];
  [_emailLabel release];
  [super dealloc];
}

- (IBAction)togglePopover:(id)sender
{
    if (self.flipsidePopoverController) {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
        self.flipsidePopoverController = nil;
    } else {
        [self performSegueWithIdentifier:@"showAlternate" sender:sender];
    }
}


#pragma mark - UI State Changes


-(void)startActivity
{
  self.nicknameLabel.text = self.nameLabel.text = self.emailLabel.text = nil;
  self.reloadButton.userInteractionEnabled = NO;
  self.signoutButton.userInteractionEnabled = NO;
  [self.activityIndicator startAnimating];
}

-(void)stopActivity
{
  [self.activityIndicator stopAnimating];
  self.reloadButton.userInteractionEnabled = YES;
  self.signoutButton.userInteractionEnabled = YES;
}

#pragma mark - NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  [self.receivedData setLength:0];
  
  NSHTTPURLResponse* httpresponse = (NSHTTPURLResponse*)response;
  
  self.statusCode = httpresponse.statusCode;
  self.headers = [httpresponse allHeaderFields];
  
  NSLog(@"Received response %d - %@", httpresponse.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:httpresponse.statusCode]);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  self.receivedData = nil;
  [self stopActivity];
  [NSString stringWithFormat:@"Connection failed! Error - %@ %@",
   [error localizedDescription],
   [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  [self stopActivity];
  [connection release];

  
  if (![(NSString*)[self.headers objectForKey:@"Content-Type"] hasPrefix:@"application/json"]) {
    self.receivedData = nil;
    return ;
  }
  
  if ([self.receivedData length] == 0) {
    self.receivedData = nil;
    return ;
  }
  
  
  NSString* string =[[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
  NSDictionary* content = [string JSONValue];
  
  self.receivedData = nil;
  
  if (content) {
    NSLog(@"Parsed Content: %@", content);
  }
  else {
    NSLog(@"No parseable Content.");
  }
  
  
  NSString* message = nil;
  switch (self.statusCode) {
    case 400:  // bad request
      message = @"Bad request. Possible protocol error.";
      [self signout:self];
      break; 
    case 401:  // unauthorized: expired, malformed or no access token
      message = @"Unauthorized access.";
      [self signout:self];
      break;
    case 402:  // forbidden: wrong scope!
      message = @"Invalid scope. Requested wrong scope?";
      [self signout:self];
      break;
    case 200:
      if ([content objectForKey:@"nickname"]) {
        self.nicknameLabel.text = [content objectForKey:@"nickname"];
        NSString* firstname = [content objectForKey:@"firstname"];
        NSString* surname = [content objectForKey:@"surname"];
        if (firstname && surname) {
          self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", firstname, surname];
        }
        else if (firstname) {
          self.nameLabel.text = firstname;
        }
        else { // surname or nil
          self.nameLabel.text = surname;
        }
        self.emailLabel.text = [content objectForKey:@"email"];        
      }
      else {
        message = @"Unknown message type.";
      }
      break;  
    default: message = @"Unexpected server response."; break;
  }
  if (message) {
    NSLog(@"Error processing response from server: %@", message);
  }
}


/** This is important: when being redirected, the controller needs to 
 modify the resulting, automatically constructed request by (re-)inserting
 the Authorization header. Otherwise, the NSURLConnection will do an 
 unauthorized request to the server. */
-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse
{
  NSURLRequest* newRequest = request;
  if (redirectResponse) { // in case of a redirect insert bearer token!
    NSMutableURLRequest *authRequest = [request mutableCopy];
    NSString* authString = [NSString stringWithFormat:@"Bearer %@", self.accessToken];  
    [authRequest setValue:authString forHTTPHeaderField:@"Authorization"];
    newRequest = authRequest;
  }
  return newRequest;
}

#pragma mark - Actions

- (IBAction)reload:(id)sender {
  if (!self.accessToken) {
    [self togglePopover:self];
    return ;
  }
    
  [self startActivity];
  
  self.receivedData = [NSMutableData data];
  NSString* authString = [NSString stringWithFormat:@"Bearer %@", self.accessToken];  
  
  NSMutableURLRequest *request=
  [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[SERVER_BASE stringByAppendingString:@"/en/identities/self"]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  [request setValue:authString forHTTPHeaderField:@"Authorization"];
  
  NSURLConnection *connection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
  
  if (!connection) {
    [self stopActivity];
  }
}

- (IBAction)signout:(id)sender {
  self.accessToken = nil;
  self.nicknameLabel.text = self.nameLabel.text = self.emailLabel.text = nil;
  [self togglePopover:self];
}
@end
