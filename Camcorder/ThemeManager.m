//
//  ThemeManager.m
//  ThemeSkinSetupExample
//
//  Created by Macmini on 16/1/27.
//
//

#import "ThemeManager.h"
#import "Macro.h"
static ThemeManager * sharedThemeManager;

@implementation ThemeManager

- (id) init {
    if(self = [super init]) {
        NSString * themePath = [[NSBundle mainBundle] pathForResource:@"theme" ofType:@"plist"];
        self.themePlistArray = [NSArray arrayWithContentsOfFile:themePath];
        self.themeIndex = 0;
    }
    
    return self;
}

+ (ThemeManager *) sharedThemeManager {
    @synchronized(self) {
        if (nil == sharedThemeManager) {
            sharedThemeManager = [[ThemeManager alloc] init];
        }
    }
    
    return sharedThemeManager;
}

// Override 重写themeName的set方法
- (void) setThemeIndex:(NSInteger)themeIndex {
    _themeIndex = themeIndex;
}

- (UIImage *) themeImageWithName:(NSString *)imageName {
    if (imageName == nil) {
        return nil;
    }
    
    NSString * themePath = [self themePath];
    NSString * themeImagePath = [themePath stringByAppendingPathComponent:imageName];
    UIImage * themeImage = [UIImage imageWithContentsOfFile:themeImagePath];
    
    return themeImage;
}

- (NSDictionary *) themePositionsWithStatus:(NSString *)status andResolution:(NSString *)resolution {
    NSDictionary *themeDict = [[self.themePlistArray objectAtIndex:self.themeIndex] objectForKey:status];
    NSDictionary * themePositions = [themeDict objectForKey:resolution];
    if (themePositions == nil) {
        return [themeDict objectForKey:@"1334X750"];
    }
    return themePositions;
}

- (NSMutableArray<UIImage *> *)getAllThumbSkin{
    NSMutableArray *skins = [NSMutableArray new];
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
    for (NSDictionary *skinDict in self.themePlistArray) {
        NSString * themeSubPath = [NSString stringWithFormat:@"%@/cam_skin.png",[skinDict objectForKey:@"Path"]];
        NSString * themeFilePath = [resourcePath stringByAppendingPathComponent:themeSubPath];
        UIImage *image = [UIImage imageWithContentsOfFile:themeFilePath];
        [skins addObject:image];
    }
    return skins;
}

// 返回主题路径
- (NSString *)themePath {
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
    
    NSString * themeSubPath = [[self.themePlistArray objectAtIndex:self.themeIndex] objectForKey:@"Path"];
    NSString * themeFilePath = [resourcePath stringByAppendingPathComponent:themeSubPath];
    
    return themeFilePath;
}
@end
