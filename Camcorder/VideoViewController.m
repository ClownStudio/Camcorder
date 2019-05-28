//
//  VideoViewController.m
//  Camcorder
//
//  Created by 张文洁 on 2018/6/7.
//  Copyright © 2018年 JamStudio. All rights reserved.
//

#import "VideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "GPUImage.h"
#import "FBGlowLabel.h"
#import "ThemeManager.h"
#import "Macro.h"
#import <Photos/Photos.h>
#import "YQAssetOperator.h"
#import "FWHudsonFilter.h"
#import "HCTestFilter.h"
#import <UIImage+GIF.h>
#import "ThemeManager.h"
#import "EffectManager.h"
#import <TZImagePickerController.h>
#import <MBProgressHUD+JDragon.h>
#import "GPUImageBeautifyFilter.h"
#import <StoreKit/StoreKit.h>
#import <CoreMotion/CoreMotion.h>

@interface VideoViewController () <TZImagePickerControllerDelegate>

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageUIElement *element;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) UIView *elementView;
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, strong) NSString *folderName;
@property (nonatomic, strong) YQAssetOperator *assetOperator;

@property (nonatomic, strong) GPUImageFilter *imageFilter;
@property (nonatomic, strong) GPUImageBeautifyFilter *beautyFilter;
@property (nonatomic, strong) HCTestFilter *textureFilter;
@property (nonatomic, strong) HCTestFilter *signFilter;
@property (nonatomic, strong) GPUImageAlphaBlendFilter *typeFilter;

@end

@implementation VideoViewController{
    NSString *_status;
    int _screenWidth;
    int _screenHeight;
    int _scale;
    NSString *_resolution;
    CGFloat _factor;
    BOOL _isAutoFlash;
    BOOL _isDateOn;
    BOOL _isBonderOn;
    UIImageView *_cameraSkin;
    UIView *_contentView;
    NSURL *_movieURL;
    BOOL _isMicro;
    BOOL _isRecording;
    int _imageviewAngle;
    
    UIButton *_textureBtn;
    UIButton *_shotBtn;
    UIButton *_settingBtn;
    UIButton *_typeBtn;
    UIButton *_filterBtn;
    UIButton *_filterSkinBtn;
    UIButton *_microBtn;
    UIButton *_flashBtn;
    UIButton *_albumBtn;
    UIButton *_recordBtn;
    UIButton *_changeBtn;
    UIButton *_animationRecordBtn;
    
    NSInteger _selectedFilter;
    NSInteger _selectedFilterItem;
    NSInteger _selectedTexture;
    NSInteger _selectedTextureItem;
    NSInteger _selectedBonder;
    NSInteger _selectedBonderItem;
    NSInteger _selectedDate;
    NSInteger _direction;
    
    GPUImageOutput <GPUImageInput> *_lastFilter;
    CMMotionManager *_motionManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configurationParams];
    [self configurationRecorder];
    [self configurationUI];
    
    [self startMotionManager];
    [self refreshCameraLayout];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    NSLog(@"viewSafeAreaInsetsDidChange: %@",NSStringFromUIEdgeInsets(self.view.safeAreaInsets));
}

- (void)startMotionManager{
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    _motionManager.deviceMotionUpdateInterval = 1/15.0;
    if (_motionManager.deviceMotionAvailable) {
        NSLog(@"Device Motion Available");
        [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                            withHandler: ^(CMDeviceMotion *motion, NSError *error){
                                                [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
                                            }];
    } else {
        NSLog(@"No device motion on device.");
    }
}

- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion{
    if (!_isDateOn || _isRecording) {
        return;
    }
    NSInteger value = 999;
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    if (fabs(y) >= fabs(x))
    {
        if (y >= 0){
            value = UIDeviceOrientationPortraitUpsideDown;
        }
        else{
            value = UIDeviceOrientationPortrait;
        }
    }
    else
    {
        if (x >= 0){
            value = UIDeviceOrientationLandscapeRight;
        }
        else{
            value = UIDeviceOrientationLandscapeLeft;
        }
    }
    if (value == 999) {
        return;
    }else{
        if (value == _direction) {
            return;
        }else{
            _direction = value;
            [self removeEffectTargets];
            [self addEffectTargets];
        }
    }
}

- (void)configurationParams{
    _screenWidth = [UIScreen mainScreen].bounds.size.width;
    _screenHeight = [UIScreen mainScreen].bounds.size.height;
    _scale = [UIScreen mainScreen].scale;
    
    _status = @"Back";
    _isMicro = YES;
    _isAutoFlash = NO;
    _isDateOn = YES;
    _isBonderOn = NO;
    _isRecording = NO;
    _selectedDate = 0;
    _selectedTexture = 0;
    _selectedTextureItem = 0;
    _imageviewAngle = 0;
    _direction = 0;
    
    self.folderName = kAlbumName;
    self.assetOperator = [[YQAssetOperator alloc] initWithFolderName:self.folderName];
}

- (IBAction)onTexture:(id)sender{
    NSArray *textures = [[[[EffectManager sharedThemeManager] texturePlistArray] objectAtIndex:_selectedTexture] objectForKey:@"textures"];
    _selectedTextureItem ++;
    if (_selectedTextureItem == [textures count]) {
        _selectedTextureItem = 0;
    }
    ThemeManager * themeManager = [ThemeManager sharedThemeManager];
    [_textureBtn setImage:[themeManager themeImageWithName:[[textures objectAtIndex:_selectedTextureItem] objectForKey:@"icon"]] forState:UIControlStateNormal];
    [self removeEffectTargets];
    [self addEffectTargets];
}

- (IBAction)onShot:(id)sender{
    
}

- (IBAction)onSetting:(id)sender{
    [MBProgressHUD showInfoMessage:NSLocalizedString(@"Expected", nil)];
}

- (IBAction)onType:(id)sender{
    ThemeManager * themeManager = [ThemeManager sharedThemeManager];
    if(_isDateOn){
        _isDateOn = NO;
        _isBonderOn = YES;
        [_typeBtn setImage:[themeManager themeImageWithName:@"Date_frame"] forState:UIControlStateNormal];
    }else if(_isBonderOn){
        _isDateOn = NO;
        _isBonderOn = NO;
        [_typeBtn setImage:[themeManager themeImageWithName:@"Date_watermark_off"] forState:UIControlStateNormal];
    }else{
        _isDateOn = YES;
        _isBonderOn = NO;
        [_typeBtn setImage:[themeManager themeImageWithName:@"Date_watermark_on"] forState:UIControlStateNormal];
    }
    [self removeEffectTargets];
    [self addEffectTargets];
}

- (IBAction)onFilter:(id)sender{
    NSArray *filters = [[[[EffectManager sharedThemeManager] filterPlistArray] objectAtIndex:_selectedFilter] objectForKey:@"filters"];
    _selectedFilterItem ++;
    if (_selectedFilterItem == [filters count]) {
        _selectedFilterItem = 0;
    }
    ThemeManager * themeManager = [ThemeManager sharedThemeManager];
    [_filterSkinBtn setImage:[themeManager themeImageWithName:[[filters objectAtIndex:_selectedFilterItem] objectForKey:@"icon"]] forState:UIControlStateNormal];
    [self removeEffectTargets];
    [self addEffectTargets];
}

- (IBAction)onMicro:(UIButton *)sender{
    if (_isMicro) {
        [_microBtn setImage:[UIImage imageNamed:@"Microphone_off"] forState:UIControlStateNormal];
        [self.videoCamera.captureSession beginConfiguration];
        NSArray *inputs = self.videoCamera.captureSession.inputs;
        for (AVCaptureDeviceInput *input in inputs) {
            if ([input.device hasMediaType:AVMediaTypeAudio]) {
                [self.videoCamera.captureSession removeInput:input];
            }
        }
        [self.videoCamera.captureSession commitConfiguration];
        _isMicro = NO;
    }else{
        [_microBtn setImage:[UIImage imageNamed:@"Microphone"] forState:UIControlStateNormal];
        [self.videoCamera.captureSession beginConfiguration];
        AVCaptureDevice *microphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:microphone error:nil];
        if ([self.videoCamera.captureSession canAddInput:audioInput]) {
            [self.videoCamera.captureSession addInput:audioInput];
        }
        [self.videoCamera.captureSession commitConfiguration];
        _isMicro = YES;
    }
    if ([self.videoCamera.inputCamera isTorchModeSupported:_isAutoFlash?AVCaptureTorchModeOn:AVCaptureTorchModeOff]) {
        [self.videoCamera.inputCamera lockForConfiguration:nil];
        [self.videoCamera.inputCamera setTorchMode:_isAutoFlash?AVCaptureTorchModeOn:AVCaptureTorchModeOff];
        [self.videoCamera.inputCamera unlockForConfiguration];
    }
}

- (IBAction)onFlash:(id)sender{
    _isAutoFlash = !_isAutoFlash;
    if ([self.videoCamera.inputCamera isTorchModeSupported:_isAutoFlash?AVCaptureTorchModeOn:AVCaptureTorchModeOff]) {
        [self.videoCamera.inputCamera lockForConfiguration:nil];
        [self.videoCamera.inputCamera setTorchMode:_isAutoFlash?AVCaptureTorchModeOn:AVCaptureTorchModeOff];
        [self.videoCamera.inputCamera unlockForConfiguration];
        if (_isAutoFlash) {
            [_flashBtn setImage:[UIImage imageNamed:@"Flash_automatic"] forState:UIControlStateNormal];
        }else{
            [_flashBtn setImage:[UIImage imageNamed:@"Flash_off"] forState:UIControlStateNormal];
        }
    }else{
        _isAutoFlash = !_isAutoFlash;
        [MBProgressHUD showWarnMessage:NSLocalizedString(@"NoSupportFlash", nil)];
    }
}

- (IBAction)onAlbum:(id)sender{
    TZImagePickerController *imagePC = [[TZImagePickerController alloc]initWithMaxImagesCount:1 delegate:self];//设置多选最多支持的最大数量，设置代理
    imagePC.sortAscendingByModificationDate = NO;
    imagePC.allowTakePicture = NO;
    [imagePC setNavLeftBarButtonSettingBlock:^(UIButton *leftButton) {
        [leftButton setHidden:YES];
    }];
    [imagePC setDidFinishPickingVideoHandle:^(UIImage *coverImage, id asset) {
        [self onAlertStoreProduct];
    }];
    [imagePC setImagePickerControllerDidCancelHandle:^{
        [self onAlertStoreProduct];
    }];
    [self presentViewController:imagePC animated:YES completion:nil];//跳转
}

- (BOOL)isAlbumCanSelect:(NSString *)albumName result:(id)result{
    if ([kAlbumName isEqualToString:albumName]) {
        return YES;
    }
    return NO;
}

- (BOOL)isAssetCanSelect:(id)asset{
    if (PHAssetMediaTypeVideo == [(PHAsset *)asset mediaType]) {
        return YES;
    }else{
        return NO;
    }
}

- (IBAction)onRecord:(id)sender{
    if (_isRecording) {
        _isRecording = NO;
        [self stopRecord];
    }else{
        _isRecording = YES;
        [self startRecord];
    }
}

- (IBAction)onChange:(id)sender{
    if ([@"Back" isEqualToString:_status]) {
        _status = @"Front";
        [self.videoCamera rotateCamera];
    }else{
        _status = @"Back";
        [self.videoCamera rotateCamera];
    }
}

- (CGRect)getFrameWithString:(NSString *)string{
    CGRect frame = CGRectFromString([NSString stringWithFormat:@"{%@}",string]);
    CGRect result = CGRectMake(frame.origin.x/_scale*_factor, frame.origin.y/_scale*_factor, frame.size.width/_scale*_factor, frame.size.height/_scale*_factor);
    return result;
}

- (void)refreshCameraLayout{
    ThemeManager * themeManager = [ThemeManager sharedThemeManager];
    NSString *imageName = [NSString stringWithFormat:@"Camera_%@_%@",_status,_resolution];
    UIImage *image = [themeManager themeImageWithName:imageName];
    if (image == nil) {
        image = [themeManager themeImageWithName:[NSString stringWithFormat:@"Camera_%@_1334X750",_status]];
    }
    [_cameraSkin setImage:image];
    
    NSDictionary *positions = [themeManager themePositionsWithStatus:_status andResolution:_resolution];
    
    [_textureBtn setFrame:[self getFrameWithString:[positions objectForKey:@"texture"]]];
    [_textureBtn setImage:[themeManager themeImageWithName:[[[[[[EffectManager sharedThemeManager] texturePlistArray] objectAtIndex:_selectedTexture] objectForKey:@"textures"] objectAtIndex:_selectedTextureItem] objectForKey:@"icon"]] forState:UIControlStateNormal];
    
    [_shotBtn setFrame:[self getFrameWithString:[positions objectForKey:@"shot"]]];
    
    [_settingBtn setFrame: [self getFrameWithString:[positions objectForKey:@"setting"]]];
    [_settingBtn setImage:[themeManager themeImageWithName:@"Set"] forState:UIControlStateNormal];
    
    [_typeBtn setFrame: [self getFrameWithString:[positions objectForKey:@"type"]]];
    if (_isDateOn) {
        [_typeBtn setImage:[themeManager themeImageWithName:@"Date_watermark_on"] forState:UIControlStateNormal];
    }else if(_isBonderOn){
        [_typeBtn setImage:[themeManager themeImageWithName:@"Date_frame"] forState:UIControlStateNormal];
    }else{
        [_typeBtn setImage:[themeManager themeImageWithName:@"Date_watermark_off"] forState:UIControlStateNormal];
    }
    
    [_filterBtn setFrame: [self getFrameWithString:[positions objectForKey:@"filter"]]];
    [_filterSkinBtn setFrame: [self getFrameWithString:[positions objectForKey:@"filter"]]];
    [_filterSkinBtn setImage:[themeManager themeImageWithName:[[[[[[EffectManager sharedThemeManager] filterPlistArray] objectAtIndex:_selectedFilter] objectForKey:@"filters"] objectAtIndex:_selectedFilterItem] objectForKey:@"icon"]] forState:UIControlStateNormal];
    
    [_microBtn setFrame: [self getFrameWithString:[positions objectForKey:@"microphone"]]];
    if (_isMicro) {
        [_microBtn setImage:[themeManager themeImageWithName:@"Microphone"] forState:UIControlStateNormal];
    }else{
        [_microBtn setImage:[themeManager themeImageWithName:@"Microphone_off"] forState:UIControlStateNormal];
    }
    
    [_flashBtn setFrame: [self getFrameWithString:[positions objectForKey:@"flashlight"]]];
    if (_isAutoFlash) {
        [_flashBtn setImage:[themeManager themeImageWithName:@"Flash_automatic"] forState:UIControlStateNormal];
    }else{
        [_flashBtn setImage:[themeManager themeImageWithName:@"Flash_off"] forState:UIControlStateNormal];
    }
    
    [_recordBtn setFrame: [self getFrameWithString:[positions objectForKey:@"record"]]];
    [_recordBtn setImage:[themeManager themeImageWithName:@"Cam_button"] forState:UIControlStateNormal];
    [_recordBtn setImage:[themeManager themeImageWithName:@"Cam_button_press"] forState:UIControlStateHighlighted];
    
    [_animationRecordBtn setFrame: [self getFrameWithString:[positions objectForKey:@"record"]]];
    [_animationRecordBtn setImage:[themeManager themeImageWithName:@"Cam_button_rec"] forState:UIControlStateNormal];
    
    if (_lastFilter) {
        [_lastFilter removeAllTargets];
        [self.filterView setFrame:[self getFrameWithString:[positions objectForKey:@"shot"]]];
        [_lastFilter addTarget:self.filterView];
    }
    
    [_changeBtn setFrame: [self getFrameWithString:[positions objectForKey:@"change"]]];
    [_changeBtn setImage:[themeManager themeImageWithName:@"Camera_changes"] forState:UIControlStateNormal];
    
    [_albumBtn setFrame: [self getFrameWithString:[positions objectForKey:@"album"]]];
    [_albumBtn setImage:[themeManager themeImageWithName:@"Album_button"] forState:UIControlStateNormal];
}

- (void)configurationUI{
    _contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_contentView];
    
    _cameraSkin = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [_cameraSkin setUserInteractionEnabled:YES];
    _resolution = [NSString stringWithFormat:@"%dX%d",_screenWidth*_scale,_screenHeight*_scale];
    if ([@"2001X1125" isEqualToString:_resolution]) {
        _factor = 1.5;
    }else{
        _factor = 1;
    }
    [_contentView addSubview:_cameraSkin];
    
    _textureBtn = [[UIButton alloc] init];
    [_textureBtn addTarget:self action:@selector(onTexture:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraSkin addSubview:_textureBtn];
    
    _shotBtn = [[UIButton alloc] init];
    [_shotBtn addTarget:self action:@selector(onShot:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraSkin addSubview:_shotBtn];
    
    _settingBtn = [[UIButton alloc] init];
    [_settingBtn addTarget:self action:@selector(onSetting:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraSkin addSubview:_settingBtn];
    
    _typeBtn = [[UIButton alloc] init];
    [_typeBtn addTarget:self action:@selector(onType:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraSkin addSubview:_typeBtn];
    
    _filterBtn = [[UIButton alloc] init];
    [_filterBtn addTarget:self action:@selector(onFilter:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraSkin addSubview:_filterBtn];
    
    _filterSkinBtn = [[UIButton alloc] init];
    [_contentView insertSubview:_filterSkinBtn belowSubview:_cameraSkin];
    
    _microBtn = [[UIButton alloc] init];
    [_microBtn addTarget:self action:@selector(onMicro:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraSkin addSubview:_microBtn];
    
    _flashBtn = [[UIButton alloc] init];
    [_flashBtn addTarget:self action:@selector(onFlash:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraSkin addSubview:_flashBtn];
    
    _albumBtn = [[UIButton alloc] init];
    [_albumBtn addTarget:self action:@selector(onAlbum:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraSkin addSubview:_albumBtn];
    
    _recordBtn = [[UIButton alloc] init];
    [_recordBtn addTarget:self action:@selector(onRecord:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraSkin addSubview:_recordBtn];
    
    _animationRecordBtn = [[UIButton alloc] init];
    [_animationRecordBtn addTarget:self action:@selector(onRecord:) forControlEvents:UIControlEventTouchUpInside];
    [_animationRecordBtn setHidden:YES];
    [_cameraSkin addSubview:_animationRecordBtn];
    
    _changeBtn = [[UIButton alloc] init];
    [_changeBtn addTarget:self action:@selector(onChange:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraSkin addSubview:_changeBtn];
}

- (void)configurationRecorder{
    // 摄像头
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    [self.videoCamera addAudioInputsAndOutputs];
    
    self.filterView = [[GPUImageView alloc] init];
    self.filterView.center = self.view.center;
    [self.view addSubview:self.filterView];
    
    [self configurationEffects];
    
    [self initMovieWriter];
    
    [self.videoCamera startCameraCapture];
}

- (void)configurationEffects{
    [self addEffectTargets];
}

- (void)addEffectTargets{
    EffectManager *effectManager = [EffectManager sharedThemeManager];
    NSDictionary *filters = [[[effectManager.filterPlistArray objectAtIndex:_selectedFilter] objectForKey:@"filters"] objectAtIndex:_selectedFilterItem];
    NSString *imageFilterName = [filters objectForKey:@"filterName"];
    if ([@"" isEqualToString:imageFilterName]) {
        self.imageFilter = [[GPUImageFilter alloc] init];
    }else{
        self.imageFilter = [[NSClassFromString(imageFilterName) alloc] init];
    }
    
    NSString *beautyFilterName = [filters objectForKey:@"level"];
    if (![@"0" isEqualToString:beautyFilterName]) {
        self.beautyFilter = [[GPUImageBeautifyFilter alloc] init];
    }else{
        self.beautyFilter = nil;
    }
    
    NSDictionary *textures = [[[effectManager.texturePlistArray objectAtIndex:_selectedTexture] objectForKey:@"textures"] objectAtIndex:_selectedTextureItem];
    
    NSString *textureFilterName = [textures objectForKey:@"texture"];
    if ([@"" isEqualToString:textureFilterName]) {
        self.textureFilter = nil;
    }else{
        self.textureFilter = [[HCTestFilter alloc] initWithTextureImage:[UIImage imageNamed:textureFilterName]];
    }
    
    NSString *signFilterName = [textures objectForKey:@"sign"];
    if ([@"" isEqualToString:signFilterName]) {
        self.signFilter = nil;
    }else{
        self.signFilter = [[HCTestFilter alloc] initWithTextureImage:[UIImage imageNamed:signFilterName]];
    }
    
    if (_isDateOn || _isBonderOn) {
        self.elementView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 720, 1280)];
        self.element = [[GPUImageUIElement alloc] initWithView:self.elementView];
        self.typeFilter = [[GPUImageAlphaBlendFilter alloc] init];
        [self.typeFilter setMix:1.0];
        if (_isDateOn) {
            [self showTimeLabel];
        }else{
            [self showBonder];
        }
    }else{
        self.typeFilter = nil;
    }
    
    GPUImageOutput <GPUImageInput> *filter = self.imageFilter;
    [self.videoCamera addTarget:self.imageFilter];
    if (self.beautyFilter) {
        [filter addTarget:self.beautyFilter];
        filter = self.beautyFilter;
    }
    
    if (self.textureFilter) {
        [filter addTarget:self.textureFilter];
        filter = self.textureFilter;
    }
    
    if (self.signFilter) {
        [filter addTarget:self.signFilter];
        filter = self.signFilter;
    }
    
    if (_isDateOn || _isBonderOn) {
        [filter addTarget:self.typeFilter];
        [self.element addTarget:self.typeFilter];
        __weak typeof (self) weakSelf = self;
        [filter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
            __strong typeof (self) strongSelf = weakSelf;
            [strongSelf.element update];
        }];
        filter = self.typeFilter;
    }
    _lastFilter = filter;
    [filter addTarget:self.filterView];
}

- (void)showBonder{
    NSDictionary *bonders = [[[EffectManager.sharedThemeManager.bonderPlistArray objectAtIndex:_selectedBonder] objectForKey:@"Bonders"] objectAtIndex:_selectedBonderItem];
    NSString *bonderName = [bonders objectForKey:@"bonder"];
    UIImage *image = [UIImage imageNamed:bonderName];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.elementView.bounds];
    [imageView setImage:image];
    [self.elementView addSubview:imageView];
}

- (void)disableOtherFuction{
    [_textureBtn setUserInteractionEnabled:NO];
    [_settingBtn setUserInteractionEnabled:NO];
    [_typeBtn setUserInteractionEnabled:NO];
    [_filterBtn setUserInteractionEnabled:NO];
    [_microBtn setUserInteractionEnabled:NO];
    [_flashBtn setUserInteractionEnabled:NO];
    [_albumBtn setUserInteractionEnabled:NO];
}

- (void)enableOtherFuction{
    [_textureBtn setUserInteractionEnabled:YES];
    [_settingBtn setUserInteractionEnabled:YES];
    [_typeBtn setUserInteractionEnabled:YES];
    [_filterBtn setUserInteractionEnabled:YES];
    [_microBtn setUserInteractionEnabled:YES];
    [_flashBtn setUserInteractionEnabled:YES];
    [_albumBtn setUserInteractionEnabled:YES];
}

- (void)removeEffectTargets{
    if (self.imageFilter) {
        [self.videoCamera removeAllTargets];
        if (self.imageFilter) {
            [self.imageFilter removeAllTargets];
        }
        if (self.beautyFilter) {
            [self.beautyFilter removeAllTargets];
        }
        if (self.textureFilter) {
            [self.textureFilter removeAllTargets];
        }
        if (self.signFilter) {
            [self.signFilter removeAllTargets];
        }
        if (self.typeFilter) {
            [self.typeFilter removeAllTargets];
        }
    }
}

- (void)initMovieWriter
{
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.m4v",[self getFileName]]];
    unlink([pathToMovie UTF8String]);
    _movieURL = [NSURL fileURLWithPath:pathToMovie];
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:_movieURL size:CGSizeMake(720, 1280)];
    self.movieWriter.encodingLiveVideo = YES;
}

- (NSArray *)imagesWithGif:(NSString *)gifNameInBundle {
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:gifNameInBundle withExtension:@"gif"];
    
    CGImageSourceRef gifSource = CGImageSourceCreateWithURL((CFURLRef)fileUrl, NULL);
    size_t gifCount = CGImageSourceGetCount(gifSource);
    NSMutableArray *frames = [[NSMutableArray alloc]init];
    for (size_t i = 0; i< gifCount; i++) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(gifSource, i, NULL);
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        [frames addObject:image];
        CGImageRelease(imageRef);
    }
    return frames;
}

- (void)startRecord{
    if (_lastFilter) {
        [_animationRecordBtn setHidden:NO];
        [self rotateAnimate];
        [_lastFilter addTarget:_movieWriter];
        self.videoCamera.audioEncodingTarget = self.movieWriter;
        [self.movieWriter startRecording];
        [self disableOtherFuction];
    }
}

-(void)rotateAnimate{
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * kRocateSpeed];
    rotationAnimation.duration = 1;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 99999;
    [_animationRecordBtn.imageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopRecord{
    NSLog(@"Movie completed");
    if (_lastFilter) {
        [_animationRecordBtn setHidden:YES];
        [_animationRecordBtn.imageView.layer removeAllAnimations];
        [MBProgressHUD showSuccessMessage:NSLocalizedString(@"RecordSuccess", nil)];
        [_lastFilter removeTarget:self.movieWriter];
        self.videoCamera.audioEncodingTarget = nil;
        [self.movieWriter finishRecording];
        [self.assetOperator saveVideoPath:_movieURL.path];
        [self initMovieWriter];
        [_lastFilter addTarget:self.movieWriter];
        [self enableOtherFuction];
    }
}

- (void)onAlertStoreProduct{
    if ([@"1" isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:kStoreProductKey]]) {
        return;
    }
    [self loadAppStoreController];
}

- (void)loadAppStoreController{
    if (@available(iOS 10.3, *)) {
        if([SKStoreReviewController respondsToSelector:@selector(requestReview)]) {
            [[UIApplication sharedApplication].keyWindow endEditing:YES];
            [SKStoreReviewController requestReview];
        }else{
            [self layoutAlertOrder];
        }
    } else {
        [self layoutAlertOrder];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"1" forKey:kStoreProductKey];
    [defaults synchronize];
}

- (void)layoutAlertOrder{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tip", nil) message:NSLocalizedString(@"Evaluate", nil) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
            [self goToAppStore];
        }else{
            NSString *urlStr = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@&pageNumber=0&sortOrdering=2&mt=8", APP_ID];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
        }
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)goToAppStore{
    NSString *itunesurl = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/cn/app/id%@?mt=8&action=write-review",APP_ID];;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:itunesurl]];
}

- (NSString *)getFileName{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYYMMddHHmmssSSS"];
    NSDate *datenow = [NSDate date];
    NSString *fileName = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]*1000];
    return fileName;
}

- (void)showTimeLabel{
    if (self.elementView) {
        NSDictionary *fontProperty = [[[EffectManager sharedThemeManager] datePlistArray] objectAtIndex:_selectedDate];
        
        FBGlowLabel *timeLabel = [[FBGlowLabel alloc] init];
        timeLabel.text = [self getCurrentTimeWithDate:[NSDate date]];
        
        UIFont *font = [UIFont fontWithName:[fontProperty objectForKey:@"fontName"] size:[[fontProperty objectForKey:@"fontSize"] floatValue]];
        if (font == nil) {
            NSLog(@"没找到您配置的字体哦！！！");
            font = [UIFont fontWithName:@"DS-Digital" size:[[fontProperty objectForKey:@"fontSize"] floatValue]];
        }
        [timeLabel setFont:font];
        //描边
        NSArray *strokes = [[fontProperty objectForKey:@"strokeColor"] componentsSeparatedByString:@","];
        if (strokes!=nil && [strokes count] == 4) {
            timeLabel.strokeColor = [UIColor colorWithRed:[strokes[0] floatValue]/255 green:[strokes[1] floatValue]/255 blue:[strokes[2] floatValue]/255 alpha:[strokes[3] floatValue]];
        }else{
            timeLabel.strokeColor = [UIColor colorWithRed:0.937 green:0.337 blue:0.157 alpha:0.7];
        }
        
        timeLabel.strokeWidth = [[fontProperty objectForKey:@"strokeWidth"] floatValue];
        //发光
        timeLabel.layer.shadowRadius = [[fontProperty objectForKey:@"shadowRadius"] floatValue];
        
        NSArray *shadows = [[fontProperty objectForKey:@"shadowColor"] componentsSeparatedByString:@","];
        if (shadows!=nil && [shadows count] == 4) {
            timeLabel.layer.shadowColor = [UIColor colorWithRed:[shadows[0] floatValue]/255 green:[shadows[1] floatValue]/255 blue:[shadows[2] floatValue]/255 alpha:[shadows[3] floatValue]].CGColor;
        }else{
            timeLabel.layer.shadowColor = [UIColor colorWithRed:0.937 green:0.337 blue:0.157 alpha:1].CGColor;
        }
        
        timeLabel.layer.shadowOffset = CGSizeFromString([fontProperty objectForKey:@"shadowOffset"]);
        timeLabel.layer.shadowOpacity = [[fontProperty objectForKey:@"shadowOpacity"] floatValue];
        
        NSArray *fontColors = [[fontProperty objectForKey:@"fontColor"] componentsSeparatedByString:@","];
        if (fontColors!=nil && [fontColors count] == 4) {
            [timeLabel setTextColor:[UIColor colorWithRed:[fontColors[0] floatValue]/255 green:[fontColors[1] floatValue]/255 blue:[fontColors[2] floatValue]/255 alpha:[fontColors[3] floatValue]]];
        }else{
            [timeLabel setTextColor:[UIColor colorWithRed:0.937 green:0.337 blue:0.157 alpha:0.7]];
        }
        
        [timeLabel setText:[self getCurrentTimeWithDate:[NSDate new]]];
        
        CGSize size = [timeLabel.text sizeWithAttributes:@{NSFontAttributeName: font}];
        
        CGSize adaptionSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
        
        CGSize gap = CGSizeFromString([fontProperty objectForKey:@"position"]);
        
        if (_direction == UIDeviceOrientationPortraitUpsideDown) {
            [timeLabel setTransform:CGAffineTransformMakeRotation(M_PI)];
            timeLabel.frame = CGRectMake(gap.width, gap.height - adaptionSize.height, adaptionSize.width, adaptionSize.height);
        }else if (_direction == UIDeviceOrientationLandscapeLeft){
            [timeLabel setTransform:CGAffineTransformMakeRotation(M_PI_2)];
            timeLabel.frame = CGRectMake(gap.height - adaptionSize.height * 1.5, 1280 - gap.width - adaptionSize.width - adaptionSize.height * 0.5, adaptionSize.height, adaptionSize.width);
        }else if (_direction == UIDeviceOrientationLandscapeRight){
            [timeLabel setTransform:CGAffineTransformMakeRotation(-M_PI_2)];
            timeLabel.frame = CGRectMake(720 - gap.height + adaptionSize.height * 0.5, gap.width + adaptionSize.height * 0.5, adaptionSize.height, adaptionSize.width);
        }else{
            timeLabel.frame = CGRectMake(720 - adaptionSize.width - gap.width, 1280 - gap.height, adaptionSize.width, adaptionSize.height);
        }
        
        [self.elementView addSubview:timeLabel];
    }
}

//获取当地时间
- (NSString *)getCurrentTimeWithDate:(NSDate *)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSString *dateType = [[NSUserDefaults standardUserDefaults] objectForKey:kDateType];
    NSMutableString *whiteSpace = [NSMutableString new];
    NSDictionary *fontProperty = [[[EffectManager sharedThemeManager] datePlistArray] objectAtIndex:_selectedDate];
    NSInteger count = [[fontProperty objectForKey:@"distance"] integerValue];
    for (int i = 0; i < count; i++) {
        [whiteSpace appendString:@" "];
    }
    if ([@"1" isEqualToString:dateType]) {
        [formatter setDateFormat:[NSString stringWithFormat:@"MM%@dd%@yy",whiteSpace,whiteSpace]];
    }else if ([@"2" isEqualToString:dateType]){
        [formatter setDateFormat:[NSString stringWithFormat:@"dd%@MM%@yy",whiteSpace,whiteSpace]];
    }else{
        [formatter setDateFormat:[NSString stringWithFormat:@"yy%@MM%@dd",whiteSpace,whiteSpace]];
    }
    
    NSString *dateTime = [formatter stringFromDate:date];
    NSString *result = [NSString stringWithFormat:@"' %@",dateTime];
    return result;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
