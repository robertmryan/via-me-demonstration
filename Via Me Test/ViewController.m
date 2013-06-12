//
//  ViewController.m
//  Via Me Test
//
//  Created by Robert Ryan on 6/12/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "ViewController.h"
#import "ViaMeManager.h"


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    ViaMeManager *viaMeManager = [ViaMeManager sharedManager];
    if (!viaMeManager.isAuthorized)
    {
        [viaMeManager authorize:^(BOOL success, NSError *error) {
            if (success)
                NSLog(@"authorized");
            else
                NSLog(@"not authorized");
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
