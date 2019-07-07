//
//  NSTask+Extension.h
//  Binaries Studio
//
//  Created by Marcelo Sarquis
//  Copyright © 2019 Binaries Studio. All rights reserved.
//


#import <Foundation/NSDictionary.h>
#import <Cocoa/Cocoa.h>

@interface NSTask (Extension)

+ (BOOL)taskWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)arguments error:(NSError **)error;

@end
