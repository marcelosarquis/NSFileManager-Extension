//
//  NSFileManager+Extension.m
//  Binaries Studio
//
//  Created by Marcelo Sarquis
//  Copyright © 2019 Binaries Studio. All rights reserved.
//


#import "NSFileManager+Extension.h"
#import "NSDictionary+Extension.h"
#import "NSTask+Extension.h"
#include <sys/stat.h>

@implementation NSFileManager (Extension)

- (BOOL)isDirectoryAtPath:(NSString *)path
{
    BOOL success = (path != nil);
    BOOL isDir = NO;
    if (success)
        success = ([self fileExistsAtPath:path isDirectory:&isDir] && isDir);
    
    return success;
}


- (unsigned long long)sizeOfDirectoryAtPath:(NSString *)path
{
    unsigned long long totalSize = 0;
    if ([self isDirectoryAtPath:path]) {
        NSArray *contents = [self contentsOfDirectoryAtPath:path error:nil];
        for (NSString *fileName in contents) {
            NSString *tmpPath = [path stringByAppendingPathComponent:fileName];
            totalSize += ([self isDirectoryAtPath:tmpPath] ? [self sizeOfDirectoryAtPath:tmpPath] : [self sizeOfFileAtPath:tmpPath]);
        }
    }
    
    return totalSize;
}


- (unsigned long long)sizeOfFileAtPath:(NSString *)path
{
    return [[self attributesOfItemAtPath:path error:nil] fileSize];
}


- (BOOL)zipItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)_error
{
    return [NSTask taskWithLaunchPath:@"/usr/bin/ditto" arguments:[NSArray arrayWithObjects:@"-c", @"-k", @"--noqtn", @"--sequesterRsrc", srcPath, dstPath, nil] error:_error];
}


- (BOOL)zipItemsArray:(NSArray *)itemsArray fromPath:(NSString *)fromPath toPath:(NSString *)dstPath error:(NSError **)_error
{
    NSMutableString *files = [NSMutableString string];
    for (NSString *onePath in itemsArray)
        [files appendFormat:@"%@ ", [[onePath stringByReplacingOccurrencesOfString:fromPath withString:@"."] stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]];
    
    return [NSTask taskWithLaunchPath:@"/bin/bash" arguments:[NSArray arrayWithObjects:@"-c", [NSString stringWithFormat:@"cd \"%@\"; /usr/bin/zip -q -r \"%@\" %@;", fromPath, dstPath, files], nil] error:_error];
}


- (BOOL)zipItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath withMaxArchiveSize:(unsigned long long)maxArchiveSize error:(NSError **)_error
{
    NSMutableDictionary *archiveList = [NSMutableDictionary dictionary];
    NSUInteger archiveCounter = 0;
    NSMutableArray *queueArray = [NSMutableArray array];
    [queueArray addObject:srcPath];
    NSMutableArray *itemsList = [NSMutableArray array];
    unsigned long long totalSize = 0;
    BOOL isDirectory = NO;
    NSString *fromPath = srcPath;
    if ([self fileExistsAtPath:srcPath isDirectory:&isDirectory]) {
        if (!isDirectory)
            fromPath = [srcPath stringByDeletingLastPathComponent];
        
    } else return NO;
    
    while (queueArray.count != 0) {
        NSString *onePath = [queueArray objectAtIndex:0];
        [queueArray removeObjectAtIndex:0];
        if (![onePath isEqualToString:@":"] && [self fileExistsAtPath:onePath isDirectory:&isDirectory]) {
            unsigned long long thisSize = (isDirectory ? [self sizeOfDirectoryAtPath:onePath] : [self sizeOfFileAtPath:onePath]);
            if (totalSize + thisSize <= maxArchiveSize) {
                totalSize += thisSize;
                [itemsList addObject:onePath];
                
            } else {
                if (isDirectory) {
                    if (thisSize <= maxArchiveSize) {
                        [queueArray addObject:onePath];
                        
                    } else {
                        [queueArray addObject:@":"];
                        for (NSString *fileName in [self contentsOfDirectoryAtPath:onePath error:_error]) [queueArray addObject:[onePath stringByAppendingPathComponent:fileName]];
                        [queueArray addObject:@":"];
                    }
                    
                } else {
                    if (thisSize <= maxArchiveSize) {
                        [queueArray addObject:onePath];
                        
                    } else {
                        NSString *uuid = [[NSUUID UUID] UUIDString];
                        [self copyItemAtPath:onePath toPath:[dstPath stringByAppendingPathComponent:uuid] error:_error];
                        NSString *relativePath = [onePath stringByReplacingOccurrencesOfString:srcPath withString:@""];
                        [archiveList setObject:[relativePath substringFromIndex:1] forKey:uuid];
                    }
                }
            }
            
            if ((queueArray.count != 0 || [[queueArray objectAtIndex:0] isEqualToString:@":"]) && (itemsList.count > 0)) {
                NSString *archiveName = [NSString stringWithFormat:@"archive_%lu.zip", archiveCounter];
                if (![self zipItemsArray:itemsList fromPath:fromPath toPath:[dstPath stringByAppendingPathComponent:archiveName] error:_error]) return NO;
                NSString *relativeSourcePath = @"";
                if (![onePath isEqualToString:srcPath]) {
                    relativeSourcePath = [onePath stringByReplacingOccurrencesOfString:srcPath withString:@""];
                    NSArray *comps = [relativeSourcePath componentsSeparatedByString:@"/"];
                    relativeSourcePath = (isDirectory ? comps[1] : comps[0]);
                }
                
                [archiveList setObject:relativeSourcePath forKey:archiveName];
                [itemsList removeAllObjects];
                totalSize = 0;
                archiveCounter++;
                [queueArray addObject:@":"];
            }
        }
    }
    
    return [[archiveList jsonString] writeToFile:[dstPath stringByAppendingPathComponent:@".archives.json"] atomically:NO encoding:NSUTF8StringEncoding error:_error];
}


- (BOOL)unzipItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)_error
{
    if (![self fileExistsAtPath:srcPath] || ![self createDirectoryAtPath:[dstPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:_error])
        return NO;
    
    return [NSTask taskWithLaunchPath:@"/usr/bin/ditto" arguments:[NSArray arrayWithObjects:@"-x", @"-k", srcPath, dstPath, nil] error:_error];
}


- (BOOL)unzipItemPathsAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)_error
{
    NSString *jsonPath = [srcPath stringByAppendingPathComponent:@".archives.json"];
    BOOL success = [self fileExistsAtPath:jsonPath];
    if (success) {
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath options: 0 error:_error];
        success = (jsonData != nil);
        if (success) {
            NSDictionary *archivesDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:_error];
            success = [self fileExistsAtPath:dstPath] ? YES : [self createDirectoryAtPath:dstPath withIntermediateDirectories:YES attributes:nil error:_error];
            if (success) {
                for (NSString *oneKey in [archivesDict allKeys]) {
                    if ([oneKey hasPrefix:@"archive_"]) {
                        success &= [self unzipItemAtPath:[srcPath stringByAppendingPathComponent:oneKey] toPath:dstPath error:_error];
                        if (!success)
                            break;
                    }
                }
                if (success) {
                    for (NSString *oneKey in [archivesDict allKeys]) {
                        if (![oneKey hasPrefix:@"archive_"]) {
                            success &= [self copyItemAtPath:[srcPath stringByAppendingPathComponent:oneKey] toPath:[dstPath stringByAppendingPathComponent:[archivesDict objectForKey:oneKey]] error:_error];
                            if (!success)
                                break;
                        }
                    }
                }
            }
        }
    }
    
    if (!success && _error && !*_error)
        *_error = [NSError errorWithDomain:@"kNSFileManagerExtensionDomain" code:-404 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"key_CouldUnzipItemPathsAtPath", nil), NSLocalizedDescriptionKey, nil]];
    
    return success;
}

@end
