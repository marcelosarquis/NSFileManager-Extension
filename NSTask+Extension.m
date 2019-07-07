//
//  NSTask+Extension.m
//  Binaries Studio
//
//  Created by Marcelo Sarquis
//  Copyright © 2019 Binaries Studio. All rights reserved.
//


#import "NSTask+Extension.h"

@implementation NSTask (Extension)

+ (BOOL)taskWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)arguments error:(NSError **)error
{
    NSTask *task = [[NSTask alloc] init];
    NSPipe *standardErrorPipe = [NSPipe pipe];
    [task setStandardError:standardErrorPipe];
    [task setLaunchPath:launchPath];
    [task setArguments:arguments];
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [task setTerminationHandler:^(NSTask *task) {
        dispatch_group_leave(group);
    }];
    [task launch];
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    int terminationStatus = [task terminationStatus];
    BOOL success = ((terminationStatus == 0) && ([task terminationReason] == NSTaskTerminationReasonExit));
    if (!success && error)
        *error = [NSError errorWithDomain:@"kNSTaskExtensionErrorDomain" code:terminationStatus userInfo:[NSDictionary dictionaryWithObject:[[NSString alloc] initWithData:[[standardErrorPipe fileHandleForReading] readDataToEndOfFile] encoding:[NSString defaultCStringEncoding]] forKey:NSLocalizedDescriptionKey]];
    
    return success;
}

@end
