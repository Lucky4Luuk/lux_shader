#ifndef _INCLUDE_DENOISE_GLSL_
#define _INCLUDE_DENOISE_GLSL_

#include "includes.glsl"
// #include "random.glsl"

vec3 denoiseTexture(sampler2D tex, vec2 texcoord, vec3 c) {
    return texture(tex, texcoord, 0).rgb;
}

#endif
