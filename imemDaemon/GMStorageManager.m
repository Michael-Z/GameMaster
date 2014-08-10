//
//  GMLockManager.m
//  imem
//
//  Created by luobin on 14-7-27.
//
//

#import "GMStorageManager.h"
#import <libkern/OSAtomic.h>
#import "GMLockThread.h"
#import "ALApplicationList.h"

static OSSpinLock spinLock;

@interface GMStorageManager()

@property (nonatomic, retain) NSMutableArray *objectList;
@property (nonatomic, retain) NSString *basePath;
@property (nonatomic, retain) NSString *savedPlistPath;
@property (nonatomic, retain) GMLockThread *lockThread;

@end

@implementation GMStorageManager

+ (instancetype)shareInstance {
    @synchronized(self){
        static GMStorageManager *sharedManager = nil;
        if (!sharedManager) {
            sharedManager = [[GMStorageManager alloc] init];
        }
        return sharedManager;
    }
}

- (id)init {
    self = [super init];
    if (self) {
        NSString *documentPath = @"/private/var/mobile/Documents";
        NSString *path = [documentPath stringByAppendingPathComponent:@"com.binge.imem.daemon/"];
        BOOL isDirectory;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory) {
            [fileManager removeItemAtPath:path error:nil];
            
            NSError *error = nil;
            [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                NSLog(@"error %@", error);
            }
        }
        self.basePath = path;
        self.lockThread = [[[GMLockThread alloc] init] autorelease];
        [self.lockThread start];
    }
    return self;
}

- (void)setPid:(int)pid {
    if (_pid != pid) {
        _pid = pid;
        if (pid <= 0) {
            self.savedPlistPath = nil;
            self.objectList = [NSMutableArray array];
        } else {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            NSString *identifier = [self getIdentifierWithPid:pid];
            NSAssert(identifier, @"identifier must not be null.");
            self.savedPlistPath = [self.basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_storageObjects.plist", identifier]];
            if ([fileManager fileExistsAtPath:self.savedPlistPath isDirectory:nil]) {
                NSMutableArray *objectList = [NSKeyedUnarchiver unarchiveObjectWithFile:self.savedPlistPath];
                if (objectList) {
                    self.objectList = objectList;
                } else {
                    [fileManager removeItemAtPath:self.savedPlistPath error:nil];
                    self.objectList = [NSMutableArray array];
                }
                self.objectList = objectList;
            } else {
                self.objectList = [NSMutableArray array];
            }
        }
        [self updateLockThreadState];
    }
}

- (NSString *)getIdentifierWithPid:(int)pid {
	ALApplicationList *appList = [ALApplicationList sharedApplicationList];
	NSDictionary *applications = [appList applicationsFilteredUsingPredicate:[NSPredicate predicateWithFormat:@"pid = %d", pid]];
    NSArray *displayIdentifiers = applications.allKeys;
    if (displayIdentifiers.count) {
        return [displayIdentifiers firstObject];
    }
    return nil;
}

- (void)synchronize {
    NSLog(@"synchronize :%@", self.objectList);
    BOOL ok = [NSKeyedArchiver archiveRootObject:self.objectList toFile:self.savedPlistPath];
    NSLog(@"synchronize result:%d", ok);
}

- (void)dealloc {
    [self.objectList removeObserver:self forKeyPath:nil context:nil];
    self.savedPlistPath = nil;
    self.basePath = nil;
    [self.lockThread cancel];
    self.lockThread = nil;
    self.objectList = nil;
    [super dealloc];
}

- (NSUInteger)findIndexOfObject:(GMMemoryAccessObject *)accessObject {
    NSUInteger index = [self.objectList indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[GMMemoryAccessObject class]]) {
            GMMemoryAccessObject *object = (GMMemoryAccessObject *)obj;
            if (object.address == accessObject.address) {
                *stop = YES;
                return YES;
            }
        }
        *stop = NO;
        return NO;
    }];
    return index;
}

- (void)addObject:(GMMemoryAccessObject *)accessObject {
    OSSpinLockLock(&spinLock);
    NSUInteger index = [self findIndexOfObject:accessObject];
    if (index != NSNotFound) {
        [self.objectList removeObjectAtIndex:index];
    }
    [self.objectList addObject:accessObject];
    [self synchronize];
    OSSpinLockUnlock(&spinLock);
    if (accessObject.optType == GMOptTypeEditAndLock) {
        [self.lockThread resume];
    }
}

- (void)removeObject:(GMMemoryAccessObject *)accessObject {
    if (accessObject) {
        [self removeObjects:@[accessObject]];
    }
}

- (void)removeObjects:(NSArray *)accessObjects {
    if (!accessObjects) {
        return;
    }
    OSSpinLockLock(&spinLock);
    BOOL isLockedObject = NO;
    for (GMMemoryAccessObject *accessObject in accessObjects) {
        NSUInteger index = [self findIndexOfObject:accessObject];
        if (index != NSNotFound) {
            GMMemoryAccessObject *oriAccessObject = [self.objectList objectAtIndex:index];
            if (oriAccessObject.optType == GMOptTypeEditAndLock) {
                isLockedObject = YES;
            }
            [self.objectList removeObjectAtIndex:index];
        }
    }
    [self synchronize];
    OSSpinLockUnlock(&spinLock);
    if (isLockedObject && ![self getLockedObjects].count) {
        [self.lockThread suspend];
    }
}

- (NSArray *)getAllObjects {
    return self.objectList;
}

- (NSArray *)getStoredObjects {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"optType = %d", GMOptTypeEditAndSave];
    OSSpinLockLock(&spinLock);
    NSArray *ret = [self.objectList filteredArrayUsingPredicate:predicate];
    OSSpinLockUnlock(&spinLock);
    return ret;
}

- (NSArray *)getLockedObjects {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"optType = %d", GMOptTypeEditAndLock];
    OSSpinLockLock(&spinLock);
    NSArray *ret = [self.objectList filteredArrayUsingPredicate:predicate];
    OSSpinLockUnlock(&spinLock);
    return ret;
}

- (void)removeAllLock {
    OSSpinLockLock(&spinLock);
    [self.objectList removeAllObjects];
    [self synchronize];
    OSSpinLockUnlock(&spinLock);
    [self updateLockThreadState];
}

- (void)updateLockThreadState {
    OSSpinLockLock(&spinLock);
    BOOL isLockedObject = NO;
    for (GMMemoryAccessObject *accessObject in self.objectList) {
        if (accessObject.optType == GMOptTypeEditAndLock) {
            isLockedObject = YES;
            break;
        }
    }
    [self synchronize];
    OSSpinLockUnlock(&spinLock);
    if (isLockedObject) {
        [self.lockThread resume];
    } else {
        [self.lockThread suspend];
    }
}

@end