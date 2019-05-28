//
//  Macro.h
//  Camcorder
//
//  Created by 张文洁 on 2018/6/7.
//  Copyright © 2018年 JamStudio. All rights reserved.
//

#ifndef Macro_h
#define Macro_h

#define kThemeIndexKey @"theme"
#define kDateType @"DateType"
#define APP_ID @"1039766045"

#define kStoreProductKey [NSString stringWithFormat:@"storeProduct%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]
//相册名字 会去去本地化语言的AlbumName字段
#define kAlbumName (NSLocalizedString(@"AlbumName", nil))
//录制时候按钮的旋转速度
#define kRocateSpeed 1.0

#endif /* Macro_h */
