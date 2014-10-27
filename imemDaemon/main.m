//
//  main.m
//  imemXpcService
//
//  Created by luobin on 14-7-10.
//  Copyright (c) 2014年 __MyCompanyName__. All rights reserved.
//

// XPC Service: Lightweight helper tool that performs work on behalf of an application.
// see http://developer.apple.com/library/mac/#documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingXPCServices.html

#include <Foundation/Foundation.h>
#import "GMMemManager.h"
#import "GMStorageManager.h"
#import "GMAppSwitchUtils.h"
#import <dlfcn.h>
#import <sys/types.h>

typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);
#if !defined(PT_DENY_ATTACH)
#define PT_DENY_ATTACH 31
#endif  // !defined(PT_DENY_ATTACH)

static void disable_gdb() {
    void* handle = dlopen(0, RTLD_GLOBAL | RTLD_NOW);
    ptrace_ptr_t ptrace_ptr = dlsym(handle, "ptrace");
    ptrace_ptr(PT_DENY_ATTACH, 0, 0, 0);
    dlclose(handle);
}

static void processMessage(SInt32 messageId, mach_port_t replyPort, CFDataRef dataRef) {
    
    NSLog(@"processMessage messageId:%d", (int)messageId);
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    switch (messageId) {
        case GMMessageIdGetPid: {
            LMSendIntegerReply(replyPort, [GMMemManager shareInstance].pid);
            break;
        }
        case GMMessageIdCheckValid: {
            int pid;
            NSData *data = (NSData *)dataRef;
            [data getBytes:&pid range:NSMakeRange(0, sizeof(pid))];
            BOOL ok = [[GMMemManager shareInstance] isValid:pid];
            LMSendIntegerReply(replyPort, ok);
            break;
        }
        case GMMessageIdSetPid: {
            int pid;
            NSData *data = (NSData *)dataRef;
            [data getBytes:&pid range:NSMakeRange(0, sizeof(pid))];
            BOOL ok = [[GMMemManager shareInstance] setPid:pid];
            LMSendIntegerReply(replyPort, ok);
            break;
        }
        case GMMessageIdSearch: {
            NSData *data = (NSData *)dataRef;
            int value; BOOL isFirst;
            [data getBytes:&value range:NSMakeRange(0, sizeof(value))];
            [data getBytes:&isFirst range:NSMakeRange(sizeof(value), sizeof(isFirst))];
            NSArray *result = [[GMMemManager shareInstance] search:value isFirst:isFirst];
            UInt64 resultCount = [GMMemManager shareInstance].resultCount;
            if (result) {
                NSMutableData *data = [NSMutableData data];
                [data appendBytes:&resultCount length:sizeof(resultCount)];
                NSData *resultData = [NSPropertyListSerialization dataFromPropertyList:result format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
                [data appendData:resultData];
                LMSendNSDataReply(replyPort, data);
            } else {
                LMSendReply(replyPort, NULL, 0);
            }
            break;
        }
        case GMMessageIdGetMemoryAccessObject: {
            uint64_t address;
            NSData *data = (NSData *)dataRef;
            [data getBytes:&address range:NSMakeRange(0, sizeof(address))];
            GMMemoryAccessObject *accessObject = [[GMMemManager shareInstance] getMemoryAccessObject:address];
            LMSendArchiverObjectReply(replyPort, accessObject);
            break;
        }
        case GMMessageIdModify: {
            GMMemoryAccessObject *accessObject = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)dataRef];
            BOOL ok = NO;
            if (accessObject) {
                ok = [[GMMemManager shareInstance] modifyMemory:accessObject];
            }
            LMSendIntegerReply(replyPort, ok);
            break;
        }
        case GMMessageIdReset: {
            BOOL ok = [[GMMemManager shareInstance] reset];
            LMSendIntegerReply(replyPort, ok);
            break;
        }
        case GMMessageIdClearSearchData: {
            BOOL ok = [[GMMemManager shareInstance] clearSearchData];
            LMSendIntegerReply(replyPort, ok);
            break;
        }
        case GMMessageIdGetLockedList: {
            NSArray *lockList = [[GMStorageManager shareInstance] getLockedObjects];
            if (lockList) {
                LMSendArchiverObjectReply(replyPort, lockList);
            } else {
                LMSendReply(replyPort, NULL, 0);
            }
            break;
        }
        case GMMessageIdGetStoredList: {
            NSArray *storedList = [[GMStorageManager shareInstance] getStoredObjects];
            if (storedList) {
                LMSendArchiverObjectReply(replyPort, storedList);
            } else {
                LMSendReply(replyPort, NULL, 0);
            }
            break;
        }
        case GMMessageIdRemoveLockedOrStoredObjects: {
            BOOL ok = NO;
            if (dataRef) {
                NSArray *accessObjects = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)dataRef];
                if (accessObjects) {
                    [[GMStorageManager shareInstance] removeObjects:accessObjects];
                    ok = YES;
                }
            }
            LMSendIntegerReply(replyPort, ok);
            break;
        }
        case GMMessageIdAddAppIdentifier: {
            BOOL ok = NO;
            if (dataRef) {
                NSString *appIdentifier = [[[NSString alloc ] initWithData:(NSData *)dataRef encoding:NSUTF8StringEncoding] autorelease];
                if (appIdentifier) {
                    [GMAppSwitchUtils addAppIdentifier:appIdentifier];
                    ok = YES;
                }
            }
            LMSendIntegerReply(replyPort, ok);
            break;
        }
        case GMMessageIdRemoveAppIdentifier: {
            BOOL ok = NO;
            if (dataRef) {
                NSString *appIdentifier = [[[NSString alloc ] initWithData:(NSData *)dataRef encoding:NSUTF8StringEncoding] autorelease];
                if (appIdentifier) {
                    [GMAppSwitchUtils removeAppIdentifier:appIdentifier];
                    ok = YES;
                }
            }
            LMSendIntegerReply(replyPort, ok);
            break;
        }
        case GMMessageIdGetAppIdentifiers: {
            NSArray *appIdentifiers = [GMAppSwitchUtils getAppIdentifiers];
            if (appIdentifiers) {
                LMSendPropertyListReply(replyPort, appIdentifiers);
            } else {
                LMSendReply(replyPort, NULL, 0);
            }
            break;
        }
            
        default:
            LMSendReply(replyPort, NULL, 0);
            break;
    }
    [pool release];
}

static void machPortCallback(CFMachPortRef port, void *bytes, CFIndex size, void *info) {
	LMMessage *request = bytes;
	if (size < sizeof(LMMessage)) {
		LMSendReply(request->head.msgh_remote_port, NULL, 0);
		LMResponseBufferFree(bytes);
		return;
	}
	// Send Response
	const void *data = LMMessageGetData(request);
	size_t length = LMMessageGetDataLength(request);
	mach_port_t replyPort = request->head.msgh_remote_port;
	CFDataRef cfdata = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, data ?: &data, length, kCFAllocatorNull);
	processMessage(request->head.msgh_id, replyPort, cfdata);
	if (cfdata)
		CFRelease(cfdata);
	LMResponseBufferFree(bytes);
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
#ifdef __OPTIMIZE__
        disable_gdb();
#endif
        
        NSLog(@"Service start...");
        while (YES) {
            kern_return_t err = LMStartService(connection.serverName, CFRunLoopGetCurrent(), machPortCallback);
            if (err) {
                NSLog(@"Unable to register mach server with error %x", err);
                [NSThread sleepForTimeInterval:60];
            } else {
                NSLog(@"Register mach server:%s with succeed.", connection.serverName);
                [[NSRunLoop currentRunLoop] run];
            }
        }
        NSLog(@"Service end...");
    }
    return EXIT_SUCCESS;
}
