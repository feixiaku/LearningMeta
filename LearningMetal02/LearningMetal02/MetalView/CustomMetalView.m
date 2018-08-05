//
//  CustomMetalView.m
//  LearningMetal02
//
//  Created by feixiaku on 5/8/2018.
//  Copyright © 2018 feixiaku. All rights reserved.
//

#import "CustomMetalView.h"
@import Metal;
@import simd;

typedef struct {
    vector_float4 vertex;
    vector_float4 color;
}CustomVertex;

@interface CustomMetalView()

@property (nonatomic, strong) CADisplayLink *displaylink;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineStat;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;

@end

@implementation CustomMetalView

- (CAMetalLayer *)metalLayer {
    return (CAMetalLayer *)self.layer;
}

+ (id)layerClass {
    return [CAMetalLayer class];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self makeDevice];
        [self makeBuffers];
        [self makePipeline];
    }
    return self;
}

- (void)dealloc
{
    [self.displaylink invalidate];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (self.superview) {
        self.displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire:)];
        [self.displaylink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }else {
        [self.displaylink invalidate];
        self.displaylink = nil;
    }
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    CGFloat scale = [UIScreen mainScreen].scale;
    if (self.window) {
        scale = self.window.screen.scale;
    }

    CGSize drawableSize = self.bounds.size;

    // Since drawable size is in pixels, we need to multiply by the scale to move from points to pixels
    drawableSize.width *= scale;
    drawableSize.height *= scale;

    self.metalLayer.drawableSize = drawableSize;
}

#pragma --mark render function
- (void)makeDevice {
    _device = MTLCreateSystemDefaultDevice();
    self.metalLayer.device = _device;
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
}

- (void)makeBuffers {
    static const CustomVertex vertices[] = {
        { .vertex = {-0.5, -0.5, 0, 1}, .color = {1.0, 0.0, 0.0, 1.0} },
        { .vertex = {0.0,  0.5,  0, 1}, .color = {0.0, 1.0, 0.0, 1.0} },
        { .vertex = {0.5,  -0.5, 0, 1}, .color = {0.0, 0.0, 1.0, 1.0} },
    };

    self.vertexBuffer = [_device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceCPUCacheModeDefaultCache];
}

- (void)makePipeline {
    id<MTLLibrary> library = [_device newDefaultLibrary];

    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_main"];

    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;

    NSError *error = nil;
    self.pipelineStat = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if(!self.pipelineStat){
        NSLog(@"Error occurred when creating render pipeline state: %@", error);
    }

    _commandQueue = [_device newCommandQueue];
}

- (void)redraw {
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    id<MTLTexture> framebufferTexture = drawable.texture;

    if(drawable) {
        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.85, 0.85, 0.85, 1.0);
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
        passDescriptor.colorAttachments[0].texture = framebufferTexture;

        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        [commandEncoder setRenderPipelineState:_pipelineStat];
        [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        [commandEncoder endEncoding];

        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

#pragma --mark displaylink selector
- (void)displayLinkDidFire: (CADisplayLink*)displayLink {
    [self redraw];
}

@end
