//
//  ViewController.h
//  Via Me Test
//
//  Created by Robert Ryan on 6/12/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *uploadImageButton;

- (IBAction)didTouchUpInsideUploadImageButton:(id)sender;

@end
