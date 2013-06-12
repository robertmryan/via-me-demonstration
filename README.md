# Via Me Demonstration

--

## Introduction

This illustrates the basic operation of Via Me (http://www.via.me) authentication and posting of images. This code sample based upon a beta interface as of 12 June 2013. For more information, please refer to http://via.me/developers/.

## Installation instructions

To integrate Via Me in your app, you must undertake the following steps:

1. Create a [custom URL scheme](http://developer.apple.com/library/ios/documentation/iphone/conceptual/iphoneosprogrammingguide/AdvancedAppTricks/AdvancedAppTricks.html#//apple_ref/doc/uid/TP40007072-CH7-SW50) 
for your app by editing the appropriate entries in t. Via Me will use this after the user has been authenticated, to return to your app. In my example, I created one called "robviame://", but you should obviously use a scheme that is logical for your app.

2. Knowing what your custom URL scheme is, register your app at http://via.me/developers. This will provide you with a client id and a client secret that you will use in your code.

3. Update the constants at the start of ViaMeManager.m with the identifier and secret you obtained in the prior step.

The basic flow of the app is as follows:

1. If the app determines it hasn't been authorized yet, it initiates an authorization:

        NSString *redirectUri = [[self redirectURI] stringByAddingPercentEscapesForURLParameterUsingEncoding:NSUTF8StringEncoding];
        NSString *urlString = [NSString stringWithFormat:@"https://api.via.me/oauth/authorize/?client_id=%@&redirect_uri=%@&response_type=code", kClientID, redirectUri];
        NSURL *url = [NSURL URLWithString:urlString];
        [[UIApplication sharedApplication] openURL:url];

 When Via.Me is done authorizing the user, it uses the custom URL scheme you configured above, to relaunch your application, passing it a "code". Thus, you need an `application:openURL:sourceApplication:annotation:` method:

        - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
        {
            // do whatever you want here to parse the code provided back to the app
        }

 This particular sample app tries to isolate the app delegate from some of the gory Via Me code, so I've moved that code into a `ViaMeManager` singleton object.

2. Upon getting a call to `openURL`, this sample code initiates the process of taking that "code" and obtaining an "accessToken" in the `requestToken` instance method of the `ViaMeManager` class. This illustrates a relatively simplistic HTTP POST request.

3. When done, if everything was successful, the upload image button will be enabled. This lets you pick an image from your device's image library and upload it as outlined in the API. The `uploadData` method should illustrate how to perform a request based upon HTTP multi-part forms.

It should be noted that this is a minimalist implementation. For example, according to the documentation, requests, such as more robust error handling (e.g. what if authorization was subsequently denied ... app should really identify authentication/authorization errors that take place between initial authorization and subsequent posts/queries.) But, the intent here is to simply illustrate some of the key technologies and concepts.


--

Robert M. Ryan

12 June 2013
