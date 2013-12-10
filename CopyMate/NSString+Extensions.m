//
//  NSString+Extensions.m
//  CopyMate
//
//  Created by hewig on 12/10/13.
//  Copyright (c) 2013 kernelpanic.im. All rights reserved.
//

#import "NSString+Extensions.h"

@implementation NSString (Extensions)

- (NSInteger)countOccurencesOfString:(NSString*)searchString
{
    NSUInteger strCount = [self length] - [[self stringByReplacingOccurrencesOfString:searchString withString:@""] length];
    return strCount / [searchString length];
}

- (NSString *)stringByEscapeControlCharacters
{
    NSMutableString *oldString = [[NSMutableString alloc] initWithString:self];
    NSRange range = NSMakeRange(0, [oldString length]);
    NSArray *toReplace = @[@"\0", @"\t", @"\n", @"\f", @"\r", @"\e"];
    NSArray *replaceWith = @[@"\\0", @"\\t", @"\\n", @"\\f", @"\\r", @"\\e"];
    for (NSUInteger i = 0, count = [toReplace count]; i < count; ++i) {
        [oldString replaceOccurrencesOfString:[toReplace objectAtIndex:i] withString:[replaceWith objectAtIndex:i] options:0 range:range];
    }
    NSString *newString = [NSString stringWithFormat:@"%@", oldString];
    return newString;
}

- (NSString *)stringByUnescapeControlCharacters
{
    NSMutableString *oldString = [[NSMutableString alloc] initWithString:self];
    NSArray *toReplace = @[@"\\0", @"\\t", @"\\n", @"\\f", @"\\r", @"\\e"];
    NSArray *replaceWith = @[@"\0", @"\t", @"\n", @"\f", @"\r", @"\e"];
    for (NSUInteger i = 0, count = [toReplace count]; i < count; ++i) {
        NSRange range = NSMakeRange(0, [oldString length]);
        [oldString replaceOccurrencesOfString:[toReplace objectAtIndex:i] withString:[replaceWith objectAtIndex:i] options:0 range:range];
    }
    NSString *newString = [NSString stringWithFormat:@"%@", oldString];
    return newString;
}

@end
