#ifndef _INCLUDE_DENOISE_GLSL_
#define _INCLUDE_DENOISE_GLSL_

#include "includes.glsl"
// #include "random.glsl"

vec4 denoiseTexture(sampler2D tex, vec2 texcoord) {
    
    return texture(tex, texcoord, 0);
}

#endif
