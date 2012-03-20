//
//  UserSettingsViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 3/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserSettingsTableViewController.h"
#import "CPapi.h"
#import "User.h"
#import "SVProgressHUD.h"
#import "SignupController.h"

#define tableCellSubviewTag 7909
#define spinnerTag  7910

@interface UserSettingsTableViewController () <UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

-(void)syncWithWebData;
-(void)placeCurrentUserData;

@end

@implementation UserSettingsTableViewController
@synthesize nicknameTextField = _nicknameTextField;
@synthesize emailTextField = _emailTextField;
@synthesize pendingEmail = _pendingEmail;
@synthesize currentUser = _currentUser;
@synthesize imagePicker = _imagePicker;
@synthesize finishedSync = _finishedSync;
@synthesize newDataFromSync = _newDataFromSync;
@synthesize profileImageButton = _profileImageButton;
@synthesize profileImage = _profileImage;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

// lazily instantiate image picker when we call the getter
- (UIImagePickerController *)imagePicker
{
    if (!_imagePicker) {
        _imagePicker = [[UIImagePickerController alloc] init];        
    }
    return _imagePicker;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.separatorColor = [UIColor colorWithRed:(68/255.0) green:(68/255.0) blue:(68/255.0) alpha:1.0];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // be the delegate of the image picker
    self.imagePicker.delegate = self;
    
    // set our current user to the user in NSUserDefaults
    self.currentUser = [CPAppDelegate currentUser];
    
    // hide the profile image button, it's going to get shown once we load the image
    self.profileImageButton.alpha = 0.0;
    
    // add an imageview to the profileImageButton
    self.profileImage = [[UIImageView alloc] initWithFrame:CGRectMake(1, 1, 31, 31)];
    
    // add the profile image imageview to the button
    [self.profileImageButton addSubview:self.profileImage];

    // put the local data on the card so it's there when it spins around
    [self placeCurrentUserData];
    
    // sync local data with data from web
    [self syncWithWebData];
}

- (void)viewDidUnload
{
    [self setNicknameTextField:nil];
    [self setEmailTextField:nil];
    [self setProfileImageButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.finishedSync) {
        // show a loading HUD
        [SVProgressHUD showWithStatus:@"Loading..."];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Web Data Sync

- (void)placeCurrentUserData
{
    // put the nickname
    self.nicknameTextField.text = self.currentUser.nickname;
    
    if (!self.pendingEmail) {
        // there's no pending email so put whatever the current email is
        self.emailTextField.text = self.currentUser.email;
    } else {
        // there's a pending email so show that to the user so they know it took
        self.emailTextField.text = self.pendingEmail;
    }
    
    // show the profile image we have and stop the spinner
    [self changeProfileImageAndStopSpinner];
}

- (void)syncWithWebData
{
    User *webSyncUser = [[User alloc] init];
    
    // load the user's data from the web by their id
    webSyncUser.userID = self.currentUser.userID;
   
    [webSyncUser loadUserResumeData:^(NSError *error) {
        if (!error) {
            // TODO: make this a better solution by checking for a problem with the PHP session cookie in CPApi
            // for now if the email comes back null this person isn't logged in so we're going to send them to do that.
            if ([webSyncUser.email isKindOfClass:[NSNull class]]) {
                [SVProgressHUD dismiss];
                
                NSString *message = @"There was a problem getting your data!\nPlease logout and login again.";
                // we had an error, let's tell the user and leave
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                                    message:message
                                                                   delegate:self 
                                                          cancelButtonTitle:@"OK" 
                                                          otherButtonTitles:nil];
                // give this alertView a tag so we can recognize this alertview in the
                // delegate function
                alertView.tag = 7879;
                [alertView show];
                
            } else {
                // let's update the local current user with any new data
                
                // check nickname
                if (![self.currentUser.nickname isEqualToString:webSyncUser.nickname]) {
                    self.currentUser.nickname = webSyncUser.nickname;
                    self.newDataFromSync = YES;
                }
                
                // check email
                if (![self.currentUser.email isEqualToString:webSyncUser.email]) {
                    self.currentUser.email = webSyncUser.email;
                    self.newDataFromSync = YES;
                }
                
                // check photo url
                if (![self.currentUser.urlPhoto isEqual:webSyncUser.urlPhoto]) {
                    // user photo is going to change
                    // show the spinner
                    [self addSpinnerToTableCell:self.profileImageButton.superview];
                    
                    self.currentUser.urlPhoto = webSyncUser.urlPhoto;
                    self.newDataFromSync = YES;
                }
                
                // if the sync brought us new data
                if (self.newDataFromSync) {
                    // save the changes to the local current user
                    [CPAppDelegate saveCurrentUserToUserDefaults:self.currentUser]; 
                    // place the current user data into the table
                    [self placeCurrentUserData];
                }
                
                // reset the newDataFromSync boolean
                self.newDataFromSync = NO;
                
                // we finshed our sync so set that boolean
                self.finishedSync = YES;
                // kill the hud if there is one
                [SVProgressHUD dismiss];
            }
            
                        

        } else {
            // kill the hud if there is one
            [SVProgressHUD dismiss];    
            NSString *message = @"There was a problem getting current data. Please try again in a little while.";
            // we had an error, let's tell the user and leave
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                                message:message
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            // give this alertView a tag so we can recognize this alertview in the
            // delegate function
            alertView.tag = 7879;
            [alertView show];            
        }      
    }];
    
}

#pragma mark - User Updating

- (void)updateCurrentUserWithNewData:(NSDictionary *)json
{
    NSDictionary *paramsDict = [json objectForKey:@"params"];
    if (paramsDict) {
        // update the current user in NSUserDefaults with the change
        NSString *newNickname = [paramsDict objectForKey:@"new_nickname"];
        if (newNickname) {
            self.currentUser.nickname = newNickname;
        }
        
        NSString *pendingEmail = [paramsDict objectForKey:@"pending_email"];
        if (pendingEmail) {
            // user wants to change email, set our pending email instance variable to that
            self.pendingEmail = pendingEmail;
            
            // show an alert if the update was to the user email so they know they have to confirm
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Email Change" 
                                                                message:[json objectForKey:@"message"]
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        NSURL *newPhoto = [NSURL URLWithString:[paramsDict objectForKey:@"picture"]];
        if (newPhoto) {
            // we have a new profile picture
            // update the user's photo url
            self.currentUser.urlPhoto = newPhoto;
        }
        
        // store the updated user in NSUserDefaults
        [CPAppDelegate saveCurrentUserToUserDefaults:self.currentUser];
    }  
    // place our current data, wether or not something changed
    [self placeCurrentUserData];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

#pragma mark - Spinner for Table Cells
- (void)addSpinnerToTableCell:(UIView *)tableCell
{
    
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[tableCell viewWithTag:spinnerTag];
    // only add the spinner for this cell if we don't already have one
    if (!spinner) {
        // alloc-init a spinner
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        
        // set the frame of the spinner so it's vertically centered on the right side of the row
        CGRect spinFrame = spinner.frame;
        spinFrame.origin.x = tableCell.frame.size.width - 10 - spinFrame.size.width;
        spinFrame.origin.y = (tableCell.frame.size.height / 2) - (spinFrame.size.height / 2) ;
        spinner.frame = spinFrame;
        
        // give the spinner a tag so we can kill it later
        spinner.tag = spinnerTag;
        
        [tableCell addSubview:spinner]; 
    }
    
    // grab the textfield or imageview we're hiding
    UIView *hideToSpin = [tableCell viewWithTag:tableCellSubviewTag];
    
    // hide the hideToSpin view
    hideToSpin.alpha = 0.0;
    
    // spin the spinner and drop the keyboard
    [spinner startAnimating];
}

- (void)stopTableCellSpinner:(UIView *)tableCell
{
    [[tableCell viewWithTag:spinnerTag] removeFromSuperview];
    [tableCell viewWithTag:tableCellSubviewTag].alpha = 1.0;
}


#pragma mark - UITextField delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    [self addSpinnerToTableCell:textField.superview];

    [textField resignFirstResponder];
    
    // disable user interaction with the keyboard
    textField.userInteractionEnabled = NO;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:nil];
    
    if (textField == self.nicknameTextField) {
        // this is the nickname text field
        [params setObject:textField.text forKey:@"nickname"];
    } else if (textField == self.emailTextField) {
        [params setObject:textField.text forKey:@"email"];
    }
    
    [CPapi setUserProfileDataWithDictionary:params andCompletion:^(NSDictionary *json, NSError *error) {
        if (!error) {
            // let's see if there was a successful change
            if ([[json objectForKey:@"succeeded"] boolValue]) {
                textField.userInteractionEnabled = YES;
                
                [self updateCurrentUserWithNewData:json];
            } else {
                // show the user the error message
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Uh Oh!" 
                                                                    message:[json objectForKey:@"message"]
                                                                   delegate:self 
                                                          cancelButtonTitle:@"OK" 
                                                          otherButtonTitles:nil];
                [alertView show];
                [self updateCurrentUserWithNewData:nil];
            }
            [self stopTableCellSpinner:textField.superview];
            textField.userInteractionEnabled = YES;
        } else {
            // error parsing JSON
        }
    }];
    
    return YES;
}

#pragma mark - IBActions

-(IBAction)gearPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)chooseNewProfileImage:(id)sender
{
    UIActionSheet *cameraSheet = [[UIActionSheet alloc] initWithTitle:@"Image Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera", @"Photo Library", nil];
    [cameraSheet showInView:self.view];
}

#pragma mark - Action Sheet Delegate

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0 || buttonIndex == 1) {
        if (buttonIndex == 0) {
            // user wants to pick from camera
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            // use the front camera by default (if we have one)
            // if there's no front camera we'll use the back (3GS)
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerCameraDeviceFront]) {
                 self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            }
           
        } else if (buttonIndex == 1) {
            // user wants to pick from photo library
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        // show the image picker
        [self presentModalViewController:self.imagePicker animated:YES];
    }    
}

#pragma mark - Image Picker Controller Delegate

- (void)changeProfileImageAndStopSpinner
{
    if (self.currentUser.urlPhoto) {
        NSURLRequest *request = [NSURLRequest requestWithURL:self.currentUser.urlPhoto];
        
        // avoid a retain cycle by using a weak pointer to call back to self
        __weak UserSettingsTableViewController *thisVC = self;
        [self.profileImage setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"texture-diagonal-noise-dark"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
            // image loaded ... stop the spinner
            [thisVC stopTableCellSpinner:self.profileImageButton.superview];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
            // failed to load the image
        }];
    }    
}

-(void)imagePickerController:(UIImagePickerController *)picker
       didFinishPickingImage:(UIImage *)image
                 editingInfo:(NSDictionary *)editingInfo
{
    // get rid of the image picker
    [picker dismissViewControllerAnimated:YES completion:^{
        // show a spinner on the profile image button now that the modal is gone
        [self addSpinnerToTableCell:self.profileImageButton.superview];
    }];
       
    
    // upload the image
    [CPapi uploadUserProfilePhoto:image withCompletion:^(NSDictionary *json, NSError *error) {
        if ([[json objectForKey:@"succeeded"] boolValue]) {
            // response was success ... we uploaded a new profile picture
            [self updateCurrentUserWithNewData:json];
        } else {
#if DEBUG
            NSLog(@"Error while uploading file. Here's the json: %@", json);
#endif
           
            NSString *message = [json objectForKey:@"message"];
            if ([message isKindOfClass:[NSNull class]]) {
                // blank message from server
                message = @"There was an problem uploading your image.\n Please try again.";
            }
            // show the user the error message
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Uh Oh!" 
                                                                message:message
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }];
}

#pragma mark - Alert View Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // dismiss the modal view controller if there was an error syncing the user data
    if (alertView.tag == 7879) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

@end