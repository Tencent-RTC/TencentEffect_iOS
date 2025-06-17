//
//  TEUIDefine.h
//  BeautyDemo
//
//  Created by tao yue on 2024/1/16.
//

#ifndef TEUIDefine_h
#define TEUIDefine_h


static NSString * const  TEUI_BEAUTY  = @"BEAUTY";
static NSString * const  TEUI_BEAUTY_IMAGE = @"BEAUTY_IMAGE";
static NSString * const  TEUI_BEAUTY_SHAPE = @"BEAUTY_SHAPE";
static NSString * const  TEUI_BEAUTY_BODY = @"BEAUTY_BODY";
static NSString * const  TEUI_BEAUTY_MAKEUP = @"BEAUTY_MAKEUP";
static NSString * const  TEUI_MAKEUP = @"MAKEUP";
static NSString * const  TEUI_LIGHT_MAKEUP = @"LIGHT_MAKEUP";
static NSString * const  TEUI_LIGHT_MOTION = @"LIGHT_MOTION";
static NSString * const  TEUI_MOTION_2D = @"MOTION_2D";
static NSString * const  TEUI_MOTION_3D = @"MOTION_3D";
static NSString * const  TEUI_MOTION_GESTURE = @"MOTION_GESTURE";
static NSString * const  TEUI_MOTION_CAMERA_MOVE = @"MOTION_CAMERA_MOVE";
static NSString * const  TEUI_SEGMENTATION = @"SEGMENTATION";
static NSString * const  TEUI_LUT = @"LUT";
static NSString * const  TEUI_PORTRAIT_SEGMENTATION = @"PORTRAIT_SEGMENTATION";
static NSString * const  TEUI_BEAUTY_TEMPLATE = @"BEAUTY_TEMPLATE";
static NSString * const  TEUI_GESTURE_DETECTION = @"GESTURE_DETECTION";
static NSString * const  TEUI_FACE_DETECTION = @"FACE_DETECTION";
static NSString * const  TEUI_GAN_BEAUTY_SKIN = @"BEAUTY_GAN";

typedef NS_ENUM(NSInteger, TEShoppingType) {
    TE_NONE,
    TE_2D_MOTION,
    TE_3D_MOTION,
    TE_MAKEUP,
    TE_HAND_MOTION,
    TE_LUT,
    TE_SEGMENTATION,
};




#endif /* TEUIDefine_h */
