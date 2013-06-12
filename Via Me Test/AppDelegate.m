//
//  AppDelegate.m
//  Via Me Test
//
//  Created by Robert Ryan on 6/12/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "AppDelegate.h"
#import "ViaMeManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Handle custom URL scheme

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    ViaMeManager *viaMeManager = [ViaMeManager sharedManager];

    if ([[url host] isEqualToString:viaMeManager.host])
    {
        [viaMeManager handleViaMeResponse:[self parseQueryString:[url query]]];

        return YES;
    }

    return NO;
}

- (NSDictionary *)parseQueryString:(NSString *)query
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    NSArray *queryParameters = [query componentsSeparatedByString:@"&"];

    for (NSString *queryParameter in queryParameters) {
        NSArray *elements = [queryParameter componentsSeparatedByString:@"="];
        NSString *key     = [elements[0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *value   = [elements[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        value             = [[value componentsSeparatedByString:@"+"] componentsJoinedByString:@" "];

        [dictionary setObject:value forKey:key];
    }
    return dictionary;
}


@end
