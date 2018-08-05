//
//  CustomMetalView.m
//  LearningMetal01
//
//  Created by feixiaku on 5/8/2018.
//  Copyright © 2018 feixiaku. All rights reserved.
//

#import "CustomMetalView.h"
@import Metal;

@interface CustomMetalView()

@property (readonly) id<MTLDevice> device;

@end

@implementation CustomMetalView

- (CAMetalLayer *)metalLayer {
    return (CAMetalLayer *)self.layer;
}

//告诉UIView 需要一个CAMatalLayer 不是需要一个CALayer
//CAMatalLayer 是UIview 和 Metal的bridge
+ (id)layerClass {
    return [CAMetalLayer class];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _device = MTLCreateSystemDefaultDevice();
        self.metalLayer.device = _device;
        self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    }
    return self;
}

- (void)didMoveToWindow {
    [self redraw];
}

- (void)redraw {
    //drawable 为了获得texture
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    id<MTLTexture> texture = drawable.texture;
    //render pass descriptor
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    passDescriptor.colorAttachments[0].texture = texture;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0);
    
    //command queue
    id<MTLCommandQueue> commandQueue = [self.device newCommandQueue];
    
    //command buffer: 每一个command buffer 都需要对应一个command Queue
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    
    //command encoding: 把一些渲染参数传给command buffer
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    [commandEncoder endEncoding];
    
    //commandBuffer 通知drawable 准备显示
    [commandBuffer presentDrawable:drawable];
    //command buffer完成 存放进command queue, 等待gpu去执行
    [commandBuffer commit];
}

@end
