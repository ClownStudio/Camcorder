//
//  EffectManager.m
//  Camcorder
//
//  Created by 张文洁 on 2018/6/26.
//  Copyright © 2018年 JamStudio. All rights reserved.
//

#import "EffectManager.h"

static EffectManager * sharedManager;

@implementation EffectManager

+ (EffectManager *) sharedThemeManager {
    @synchronized(self) {
        if (nil == sharedManager) {
            sharedManager = [[EffectManager alloc] init];
        }
    }
    return sharedManager;
}

- (id)init {
    if(self = [super init]) {
        NSString *filterPath = [[NSBundle mainBundle] pathForResource:@"filter" ofType:@"plist"];
        self.filterPlistArray = [NSArray arrayWithContentsOfFile:filterPath];
        NSString *texturePath = [[NSBundle mainBundle] pathForResource:@"texture" ofType:@"plist"];
        self.texturePlistArray = [NSArray arrayWithContentsOfFile:texturePath];
        NSString *bonderPath = [[NSBundle mainBundle] pathForResource:@"bonder" ofType:@"plist"];
        self.bonderPlistArray = [NSArray arrayWithContentsOfFile:bonderPath];
        NSString *datePath = [[NSBundle mainBundle] pathForResource:@"date" ofType:@"plist"];
        self.datePlistArray = [NSArray arrayWithContentsOfFile:datePath];
    }
    
    return self;
}

@end
