//
//  main.m
//  GameMaster
//
//  Created by LuoBin on 14-7-4.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import <UI7Kit/UI7Kit.h>

int main(int argc, char *argv[]) {
    @autoreleasepool {
        [UI7Kit patchIfNeeded];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

