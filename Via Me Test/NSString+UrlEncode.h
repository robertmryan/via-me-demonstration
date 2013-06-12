//
//  NSString+UrlEncode.h
//  Via Me Test
//
//  Created by Robert Ryan on 6/12/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (UrlEncode)

+ (NSString *)stringByAddingPercentEscapesFor:(NSString *)string
                legalURLCharactersToBeEscaped:(NSString *)legalURLCharactersToBeEscaped
                                usingEncoding:(NSStringEncoding)encoding;

- (NSString *)stringByAddingPercentEscapesFor:(NSString *)legalURLCharactersToBeEscaped
                                usingEncoding:(NSStringEncoding)encoding;

- (NSString *)stringByAddingPercentEscapesForURLParameterUsingEncoding:(NSStringEncoding)encoding;


@end
