//
//  NSString+Extensions.h
//  CopyMate
//
//  Created by hewig on 12/10/13.
//  Copyright (c) 2013 kernelpanic.im. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extensions)

- (NSInteger)countOccurencesOfString:(NSString*)searchString;
- (NSString *)stringByEscapeControlCharacters;
- (NSString *)stringByUnescapeControlCharacters;

@end
