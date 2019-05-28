//
//  EffectManager.h
//  Camcorder
//
//  Created by 张文洁 on 2018/6/26.
//  Copyright © 2018年 JamStudio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EffectManager : NSObject

@property (nonatomic, retain) NSArray * filterPlistArray;
@property (nonatomic, retain) NSArray * texturePlistArray;
@property (nonatomic, retain) NSArray * bonderPlistArray;
@property (nonatomic, retain) NSArray * datePlistArray;

+ (EffectManager *) sharedThemeManager;

@end
