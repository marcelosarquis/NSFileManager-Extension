//
//  NSFileManager+Extension.h
//  Binaries Studio
//
//  Created by Marcelo Sarquis
//  Copyright © 2019 Binaries Studio. All rights reserved.
//


#import <Foundation/NSDictionary.h>
#import <Cocoa/Cocoa.h>

@interface NSFileManager (Extension)

- (BOOL)isDirectoryAtPath:(NSString *)path;
- (unsigned long long)sizeOfDirectoryAtPath:(NSString *)path;
- (unsigned long long)sizeOfFileAtPath:(NSString *)path;
- (BOOL)zipItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)_error;
- (BOOL)zipItemsArray:(NSArray *)itemsArray fromPath:(NSString *)fromPath toPath:(NSString *)dstPath error:(NSError **)_error;
- (BOOL)zipItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath withMaxArchiveSize:(unsigned long long)maxArchiveSize error:(NSError **)_error;
- (BOOL)unzipItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)_error;
- (BOOL)unzipItemPathsAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)_error;

@end
