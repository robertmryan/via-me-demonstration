//
//  ViaMeManager.h
//  Via Me Test
//
//  Created by Robert Ryan on 6/12/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^ViaMeCompletionBlock)(BOOL success, NSError *error);


@interface ViaMeManager : NSObject

/// ----------------------------------------------------------------------
/// @name Properties
/// ----------------------------------------------------------------------

@property (nonatomic, strong, readonly) NSString *host;
@property (nonatomic, strong, readonly) NSString *code;
@property (nonatomic, strong, readonly) NSString *accessToken;
@property (nonatomic, readonly, getter = isAuthorized) BOOL authorized;

/// ----------------------------------------------------------------------
/// @name Basic operations
/// ----------------------------------------------------------------------

/// Retrieve access to singleton

+ (id)sharedManager;

/// ----------------------------------------------------------------------
/// @name Authorization
/// ----------------------------------------------------------------------

/// Authorize App

- (void)authorize:(ViaMeCompletionBlock)block;

/** Handle the response from Via Me
 
 This is called by app delegate when it receives a Via Me response.
 */

- (void)handleViaMeResponse:(NSDictionary *)parameters;

/** Host name used in app's custom URL scheme for viame related requests
 
 This is how the app delegate knows whether a URL request is from for Via Me or not.
 */

- (NSString *)host;

/// ----------------------------------------------------------------------
/// @name Uploading
/// ----------------------------------------------------------------------

- (void)uploadData:(NSData *)data filename:(NSString *)filename text:(NSString *)text completion:(ViaMeCompletionBlock)completion;

@end
