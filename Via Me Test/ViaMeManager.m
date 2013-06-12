//
//  ViaMeManager.m
//  Via Me Test
//
//  Created by Robert Ryan on 6/12/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "ViaMeManager.h"
#import "NSString+UrlEncode.h"

// app specific constants for Via Me App

#warning register your app at http://via.me/developers and fill client ID/secret here

static NSString * const kClientID = @"ch9n272yaxmwc4ydlu4f5jhh6";
static NSString * const kClientSecret = @"dgxusjgkivm06zy3wba1398nx";
static NSString * const kHost = @"viame";

// constants for NSUserDefaults

static NSString * const kViaMeUserDefaultKeyCode = @"ViaMe Code";
static NSString * const kViaMeUserDefaultKeyAccessToken = @"ViaMe Access Key";




@interface ViaMeManager ()

@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, copy) AuthorizationCompletionBlock authorizationCompletionBlock;

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

- (void)authorize:(AuthorizationCompletionBlock)block
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

    NSMutableArray *paramsArray = [NSMutableArray array];
    [paramsDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        [paramsArray addObject:[NSString stringWithFormat:@"%@=%@", key, [obj stringByAddingPercentEscapesForURLParameterUsingEncoding:NSUTF8StringEncoding]]];
    }];

    NSData *paramsData = [[paramsArray componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
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
        NSLog(@"%s: parameters = %@", __FUNCTION__, parameters);

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
