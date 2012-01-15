//
//  FlipsideViewController.m
//  IdentityProviderDemo
//
//  Created by Sascha Lange on 13.01.12.
//  Copyright (c) 2012 Universität Freiburg. All rights reserved.
//

#import "FlipsideViewController.h"
#import "SBJson.h"

@implementation FlipsideViewController

@synthesize delegate = _delegate;
@synthesize login = _login;
@synthesize password = _password;
@synthesize notice = _notice;
@synthesize activityIndicator = _activityIndicator;
@synthesize receivedData = _receivedData;
@synthesize statusCode = _statusCode;
@synthesize headers = _headers;

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
  
  self.receivedData = [NSMutableData data];
  
  NSString* queryString = 
    [NSString stringWithFormat:@"grant_type=password&client_id=XYZ&username=%@&password=%@", self.login.text, self.password.text];
  
  NSMutableURLRequest *request=
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:3000/oauth2/access_token"] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:20.0];
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
  [request setHTTPMethod:@"POST"];
  [request setHTTPBody:[queryString dataUsingEncoding:NSUTF8StringEncoding]];
  
  NSURLConnection *connection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
  
  if (!connection) {
    [self stopActivity];
    self.notice.text = @"Could not establish a connection to the server.";
    self.notice.hidden = NO;
  }
  
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


#pragma mark - NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  [self.receivedData setLength:0];
  
  NSHTTPURLResponse* httpresponse = (NSHTTPURLResponse*)response;

  self.statusCode = httpresponse.statusCode;
  self.headers = [httpresponse allHeaderFields];
  
  NSLog(@"Received response %d - %@", httpresponse.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:httpresponse.statusCode]);
  
  NSLog(@"Header: %@", self.headers);
  
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  NSLog(@"received data");
  [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  self.receivedData = nil;
  [self stopActivity];
  self.notice.text = 
    [NSString stringWithFormat:@"Connection failed! Error - %@ %@",
        [error localizedDescription],
        [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]];
  self.notice.hidden = NO;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  NSLog(@"Succeeded! Received %d bytes of data",[self.receivedData length]);
  
  [self stopActivity];
  
  if (![(NSString*)[self.headers objectForKey:@"Content-Type"] hasPrefix:@"application/json"]) {
    self.notice.text = @"Unexpected format of server response.";
    self.notice.hidden = NO;
    self.receivedData = nil;
    [connection release];
    return ;
  }
  
  if ([self.receivedData length] == 0) {
    self.notice.text = @"Received no data.";
    self.notice.hidden = NO;
    self.receivedData = nil;
    [connection release];
    return ;
  }
  


  NSString* string =[[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
  NSDictionary* content = [string JSONValue];
  
  NSLog(@"Content (%d): %@", [self.receivedData length], string);    
  self.receivedData = nil;

  
  if (!content) {
    self.notice.text = @"Could not parse answer from server.";
    self.notice.hidden = NO;
    return ;
  }
  
  NSLog(@"Parsed Content: %@", content);
  
  
  NSString* message = nil;
  switch (self.statusCode) {
    case 400: 
      if ([(NSString*)[content objectForKey:@"error"] compare:@"invalid_grant"] == NSOrderedSame) {
        message = @"Wrong username or password.";
      }
      else {
        message = [NSString stringWithFormat:@"Bad request. %@", [content objectForKey:@"error_description"]];
      }
      break; 
    
    case 200:
      if ([(NSString*)[content objectForKey:@"token_type"] hasPrefix:@"bearer"] && [content objectForKey:@"access_token"]) {
        [self.delegate setAccessToken:[content objectForKey:@"access_token"]];
        [self done:self];
      }
      else {
        message = @"Unknown access token type.";
      }
      break;  
    default: message = @"Unexpected server response."; break;
  }
  if (message) {
    self.notice.text = message;
    self.notice.hidden = NO;
  }
}

@end
