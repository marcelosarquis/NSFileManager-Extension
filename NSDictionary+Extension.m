//
//  NSDictionary+Extension.h
//  Binaries Studio
//
//  Created by Marcelo Sarquis
//  Copyright © 2019 Binaries Studio. All rights reserved.
//


#import "NSDictionary+Extension.h"

@implementation NSDictionary (Extension)

- (NSString *)jsonString
{
    NSData *data = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil];
    return data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
}

@end
