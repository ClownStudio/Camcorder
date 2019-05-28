//
//  ThemeManager.h
//  ThemeSkinSetupExample
//
//  Created by Macmini on 16/1/27.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ThemeManager : NSObject

@property (nonatomic) NSInteger themeIndex;           // 主题
@property (nonatomic, retain) NSArray * themePlistArray;    // 主题属性列表字典

+ (ThemeManager *) sharedThemeManager;
- (NSDictionary *) themePositionsWithStatus:(NSString *)status andResolution:(NSString *)resolution;
- (UIImage *) themeImageWithName:(NSString *)imageName;
- (NSMutableArray<UIImage *> *)getAllThumbSkin;

@end
