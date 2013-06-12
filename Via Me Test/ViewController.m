//
//  ViewController.m
//  Via Me Test
//
//  Created by Robert Ryan on 6/12/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "ViewController.h"
#import "ViaMeManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self authorizeViaMeIfNeeded];
}

- (void)authorizeViaMeIfNeeded
{
    ViaMeManager *viaMeManager = [ViaMeManager sharedManager];
    
    if (viaMeManager.isAuthorized)
    {
        self.uploadImageButton.enabled = YES;
        self.uploadImageButton.alpha = 1.0;
    }
    else
    {
        self.uploadImageButton.enabled = NO;
        self.uploadImageButton.alpha = 0.0;
        
        [viaMeManager authorize:^(BOOL success, NSError *error) {
            if (success)
            {
                NSLog(@"authorized");
                self.uploadImageButton.enabled = YES;
                self.uploadImageButton.alpha = 1.0;
            }
            else
            {
                NSLog(@"not authorized");
            }
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIImagePickerControllerDelegate

- (IBAction)didTouchUpInsideUploadImageButton:(id)sender
{
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    controller.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    controller.allowsEditing = NO;
    controller.delegate = self;
    
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *imageToUse;
    
    // Handle a still image picked from a photo album
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo)
    {
        editedImage = (UIImage *) [info objectForKey:UIImagePickerControllerEditedImage];
        originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
        
        if (editedImage) {
            imageToUse = editedImage;
        } else {
            imageToUse = originalImage;
        }

        NSString *filename = [[info objectForKey:UIImagePickerControllerReferenceURL] lastPathComponent];
        [[ViaMeManager sharedManager] uploadData:UIImageJPEGRepresentation(imageToUse, 0.8) filename:filename text:@"Test image" completion:^(BOOL success, NSError *error) {
            NSLog(@"success = %@", (success ? @"Yes" : @"No"));
        }];
        
        // Do something with imageToUse
    }
    
    // Handle a movied picked from a photo album
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo)
    {
        // NSString *moviePath = [[info objectForKey:UIImagePickerControllerMediaURL] path];
        
        [[[UIAlertView alloc] initWithTitle:nil message:@"Uploading of videos not implemented" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }

    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}
@end
