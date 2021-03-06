//
//  SystemInfo+AssetsLibrary.m
//  SystemInfo
//
//  Created by Ken M. Haggerty on 9/25/15.
//  Copyright (c) 2015 MCMDI. All rights reserved.
//

#pragma mark - // NOTES (Private) //

#pragma mark - // IMPORTS (Private) //

#import "SystemInfo+AssetsLibrary.h"
#import "SystemInfo+PRIVATE.h"
#import "AKDebugger.h"
#import "AKGenerics.h"
#import <objc/runtime.h>
#import <Photos/Photos.h>

#pragma mark - // DEFINITIONS (Private) //

#define THUMBNAIL_SIZE CGSizeMake(157.0, 157.0)

@implementation SystemInfo (AssetsLibrary)

#pragma mark - // SETTERS AND GETTERS //

- (void)setSharedLibrary:(ALAssetsLibrary *)sharedLibrary
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetter tags:@[AKD_UI] message:nil];
    
    objc_setAssociatedObject(self, @selector(sharedLibrary), sharedLibrary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (sharedLibrary) [userInfo setObject:sharedLibrary forKey:NOTIFICATION_OBJECT_KEY];
    [AKGenerics postNotificationName:NOTIFICATION_ASSETSLIBRARY_DID_CHANGE object:nil userInfo:userInfo];
}

- (ALAssetsLibrary *)sharedLibrary
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    ALAssetsLibrary *sharedLibrary = objc_getAssociatedObject(self, @selector(sharedLibrary));
    if (!sharedLibrary)
    {
        sharedLibrary = [ALAssetsLibrary new];
        [self setSharedLibrary:sharedLibrary];
    }
    return sharedLibrary;
}

#pragma mark - // INITS AND LOADS //

#pragma mark - // PUBLIC METHODS //

+ (ALAssetsLibrary *)assetsLibrary
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_DATA] message:nil];
    
    return [[SystemInfo sharedInfo] sharedLibrary];
}

+ (void)getLastPhotoThumbnailFromCameraRollWithCompletion:(void (^)(UIImage *))completion
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_DATA] message:nil];
    
    if ([SystemInfo iOSVersion] < 9.0)
    {
        __block BOOL foundThumbnail = NO;
        [[SystemInfo assetsLibrary] enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (!group)
            {
                *stop = YES;
                if (!foundThumbnail)
                {
                    completion(nil);
                }
                return;
            }
            
            NSInteger numberOfAssets = [group numberOfAssets];
            if (numberOfAssets)
            {
                NSInteger lastIndex = numberOfAssets-1;
                [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:lastIndex] options:0 usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    UIImage *thumbnail = [UIImage imageWithCGImage:[result thumbnail]];
                    if (thumbnail && thumbnail.size.width > 0)
                    {
                        *stop = YES;
                        foundThumbnail = YES;
                        completion(thumbnail);
                        return;
                    }
                }];
            }
        } failureBlock:^(NSError *error){
            [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeError methodType:AKMethodTypeGetter tags:@[AKD_DATA] message:[NSString stringWithFormat:@"%@, %@", error, error.userInfo]];
        }];
    }
    else
    {
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
        PHAsset *lastAsset = [fetchResult lastObject];
        PHImageRequestOptions *options = PHImageRequestOptionsVersionCurrent;
        [options setSynchronous:YES];
        [[PHImageManager defaultManager] requestImageForAsset:lastAsset
                                                   targetSize:THUMBNAIL_SIZE
                                                  contentMode:PHImageContentModeAspectFill
                                                      options:options
                                                resultHandler:^(UIImage *result, NSDictionary *info){
                                                    completion(result);
                                                }];
    }
}

#pragma mark - // CATEGORY METHODS //

#pragma mark - // DELEGATED METHODS //

#pragma mark - // OVERWRITTEN METHODS //

- (void)addObserversForAssetsLibraryCategory
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:nil message:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryDidChange:) name:ALAssetsLibraryChangedNotification object:nil];
}

- (void)removeObserversForAssetsLibraryCategory
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:nil message:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
}

#pragma mark - // PRIVATE METHODS (Responders) //

- (void)assetsLibraryDidChange:(NSNotification *)notification
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    [[SystemInfo sharedInfo] setSharedLibrary:[ALAssetsLibrary new]];
}

@end
