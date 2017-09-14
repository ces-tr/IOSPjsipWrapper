//
//  SWViewController.h
//  Swig
//
//  Created by Pierre-Marc Airoldi on 09/01/2014.
//  Copyright (c) 2014 Pierre-Marc Airoldi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SWViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *txtaddress;

@property (weak, nonatomic) IBOutlet UITextField *txtdomain;

@property (weak, nonatomic) IBOutlet UITextField *txtusername;

@property (weak, nonatomic) IBOutlet UITextField *txtpswd;

@property (weak, nonatomic) IBOutlet UITextField *txtProxy;


-(IBAction)makeCall:(id)sender;
-(IBAction)answer:(id)sender;
-(IBAction)mute:(id)sender;
-(IBAction)speaker:(id)sender;
- (IBAction)makeVideoCall:(id)sender;

@end
