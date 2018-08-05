//
//  metal.metal
//  LearningMetal02
//
//  Created by feixiaku on 5/8/2018.
//  Copyright © 2018 feixiaku. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex{
    float4 position [[position]];
    float4 color;
};

vertex Vertex vertex_main(device Vertex *vertices[[buffer(0)]],
                          uint vid [[vertex_id]])
{
    return vertices[vid];
}

fragment float4 fragment_main(Vertex inVertex [[stage_in]])
{
    return inVertex.color;
}
