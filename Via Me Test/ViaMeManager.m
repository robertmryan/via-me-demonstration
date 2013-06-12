//
//  ViaMeManager.m
//  Via Me Test
//
//  Created by Robert Ryan on 6/12/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "ViaMeManager.h"
#import "NSString+UrlEncode.h"
#import <MobileCoreServices/MobileCoreServices.h>

// app specific constants for Via Me App

#warning register your app at http://via.me/developers and fill client ID/secret and the host here

static NSString * const kClientID     = @"xxx";    // obtained when you register your app
static NSString * const kClientSecret = @"xxx";    // obtained when you register your app
static NSString * const kHost         = @"viame";  // if the custom scheme is myapp://, then register the URI of myapp://xyz, and "xyz" will be the kHost specified here

// constants for NSUserDefaults

static NSString * const kViaMeUserDefaultKeyCode = @"ViaMe Code";
static NSString * const kViaMeUserDefaultKeyAccessToken = @"ViaMe Access Key";




@interface ViaMeManager ()

@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, copy) ViaMeCompletionBlock authorizationCompletionBlock;

@end

@implementation ViaMeManager

#pragma mark - initialization

+ (id)sharedManager
{
    static id sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _code        = [[NSUserDefaults standardUserDefaults] objectForKey:kViaMeUserDefaultKeyCode];
        _accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:kViaMeUserDefaultKeyAccessToken];
        _host        = kHost;
    }
    return self;
}

#pragma mark - Authorization

- (BOOL)isAuthorized
{
    return self.accessToken != nil;
}

- (void)authorize:(ViaMeCompletionBlock)block
{
    self.authorizationCompletionBlock = block;
    
    NSString *redirectUri = [[self redirectURI] stringByAddingPercentEscapesForURLParameterUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat:@"https://api.via.me/oauth/authorize/?client_id=%@&redirect_uri=%@&response_type=code", kClientID, redirectUri];
    NSURL *url = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)requestToken
{
    NSURL *url = [NSURL URLWithString:@"https://api.via.me/oauth/access_token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];

    NSDictionary *paramsDictionary = @{@"client_id"     : kClientID,
                                       @"client_secret" : kClientSecret,
                                       @"grant_type"    : @"authorization_code",
                                       @"redirect_uri"  : [self redirectURI],
                                       @"code"          : self.code,
                                       @"response_type" : @"token"
                                       };

    NSData *paramsData = [self parameterDataFromDictionary:paramsDictionary];
    [request setHTTPBody:paramsData];

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error)
        {
            NSLog(@"%s: NSURLConnection error = %@", __FUNCTION__, error);
            if (self.authorizationCompletionBlock)
                self.authorizationCompletionBlock(NO, error);
            return;
        }

        NSError *parseError;
        id results = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];

        if (parseError)
        {
            NSLog(@"%s: NSJSONSerialization error = %@", __FUNCTION__, parseError);
            if (self.authorizationCompletionBlock)
                self.authorizationCompletionBlock(NO, parseError);
            return;
        }

        self.accessToken = results[@"access_token"];
        NSLog(@"results = %@", results);
        
        if (self.accessToken)
        {
            [[NSUserDefaults standardUserDefaults] setValue:self.accessToken forKey:kViaMeUserDefaultKeyAccessToken];
            [[NSUserDefaults standardUserDefaults] synchronize];
            if (self.authorizationCompletionBlock)
                self.authorizationCompletionBlock(YES, nil);
        }
        else
        {
            if (self.authorizationCompletionBlock)
                self.authorizationCompletionBlock(NO, [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                                                          code:-1
                                                                      userInfo:@{@"description":@"no token found"}]);
        }
    }];
}

- (NSData *)parameterDataFromDictionary:(NSDictionary *)dictionary
{
    NSMutableArray *paramsArray = [NSMutableArray array];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        [paramsArray addObject:[NSString stringWithFormat:@"%@=%@", key, [obj stringByAddingPercentEscapesForURLParameterUsingEncoding:NSUTF8StringEncoding]]];
    }];
    
    return [[paramsArray componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)handleViaMeResponse:(NSDictionary *)parameters
{
    self.code = parameters[@"code"];

    if (self.code)
    {
        // save the code

        [[NSUserDefaults standardUserDefaults] setValue:self.code forKey:kViaMeUserDefaultKeyCode];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // now let's authenticate the user and get an access key

        [self requestToken];
    }
    else
    {
        NSString *errorCode = parameters[@"error"];
        if ([errorCode isEqualToString:@"access_denied"])
        {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:@"Via Me functions will not be enabled because you did not authorize this app"
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:@"Unknown Via Me authorization error"
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
        
        if (self.authorizationCompletionBlock)
            self.authorizationCompletionBlock(NO, [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                                                      code:-1
                                                                  userInfo:parameters]);

    }
}

#pragma mark - Uploading

- (void)uploadData:(NSData *)data filename:(NSString *)filename text:(NSString *)text completion:(ViaMeCompletionBlock)completion
{
    NSURL *url = [NSURL URLWithString:@"http://api.via.me/v1/post"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSDictionary *paramsDictionary = @{@"text"         : text,
                                       @"access_token" : self.accessToken,
                                       @"media_type"   : @"photo"
                                       };
    
    NSString *boundary = [self generateBoundaryString];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *postBody = [NSMutableData data];

    // first, let's add the paramsDictionary fields
    
    [paramsDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[[NSString stringWithFormat:@"%@\r\n", obj] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    // next, let's append the image data
    
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", [self mimeTypeForPath:filename]] dataUsingEncoding:NSUTF8StringEncoding]];

    // finally, let's end and save the body
    
    [postBody appendData:data];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:postBody];

    // let's initiate the request
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error)
        {
            NSLog(@"%s: NSURLConnection error = %@", __FUNCTION__, error);
            if (completion)
                completion(NO, error);
            return;
        }
        
        NSError *parseError;
        NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        
        if (parseError)
        {
            NSLog(@"%s: NSJSONSerialization error = %@", __FUNCTION__, parseError);
            if (completion)
                completion(NO, parseError);
            return;
        }
        
        // the beta docs don't make error handling obvious, so I'll just check
        // to see if there is a post dictionary inside a response dictionary,
        // and if so, I'll assume it was successful
        
        NSDictionary *postDetails = results[@"response"][@"post"];
        
        if (postDetails)
        {
            if (completion)
                completion(YES, nil);
        }
        else
        {
            if (completion)
                completion(NO, [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                                   code:-1
                                               userInfo:results]);
        }
    }];
}

- (NSString *)generateBoundaryString
{
    // generate boundary string
    //
    // adapted from http://developer.apple.com/library/ios/#samplecode/SimpleURLConnections
    
    CFUUIDRef  uuid;
    NSString  *uuidStr;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    assert(uuidStr != NULL);
    
    CFRelease(uuid);
    
    return [NSString stringWithFormat:@"Boundary-%@", uuidStr];
}

- (NSString *)mimeTypeForPath:(NSString *)path
{
    // Get a mime type for an extension using MobileCoreServices.framework.
    //
    // You could hard code this instead, but I like using MobileCoreServices as
    // it increases my code reuse possibilities in the future.
    
    CFStringRef extension = (__bridge CFStringRef)[path pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
    assert(UTI != NULL);
    
    NSString *mimetype = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    assert(mimetype != NULL);
    
    CFRelease(UTI);
    
    return mimetype;
}

#pragma mark - Custom URL scheme

// create redirect URI based upon custom URL scheme and the "host" identifier for via me requests

- (NSString *)redirectURI
{
    return [[self urlScheme] stringByAppendingFormat:@"://%@", [self host]];
}

// look up URL scheme in bundle

- (NSString *)urlScheme
{
    NSArray *bundleTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    NSAssert(bundleTypes, @"You must specify a URL Types entry in your bundle's plist");

    NSDictionary *urlTypeDictionary = bundleTypes[0];
    NSArray *urlSchemes = urlTypeDictionary[@"CFBundleURLSchemes"];
    NSAssert(urlSchemes, @"You must specify a URL scheme in your URL types entry");

    return urlSchemes[0];
}

@end
