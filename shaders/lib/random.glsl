#ifndef _INCLUDE_RANDOM_GLSL_
#define _INCLUDE_RANDOM_GLSL_

#include "includes.glsl"

int flat_idx = int(dot(gl_FragCoord.xy, vec2(1, 4096)));
void encrypt_tea(inout uvec2 arg) {
	uvec4 key = uvec4(0xa341316c, 0xc8013ea4, 0xad90777d, 0x7e95761e);
	uint v0 = arg[0], v1 = arg[1];
	uint sum = 0u;
	uint delta = 0x9e3779b9u;

	for(int i = 0; i < 32; i++) {
		sum += delta;
		v0 += ((v1 << 4) + key[0]) ^ (v1 + sum) ^ ((v1 >> 5) + key[1]);
		v1 += ((v0 << 4) + key[2]) ^ (v0 + sum) ^ ((v0 >> 5) + key[3]);
	}
	arg[0] = v0;
	arg[1] = v1;
}

vec2 get_random(inout uint seed) {
  	uvec2 arg = uvec2(flat_idx, seed++);
  	encrypt_tea(arg);
  	return fract(vec2(arg) / vec2(0xffffffffu));
}

//UE4 fast random
float fast(vec2 v) {
    v = (1./4320.) * v + vec2(0.25,0.);
    float state = fract( dot( v * v, vec2(3571)));
    return fract( state * state * (3571. * 2.));
}

//Yoinked from xirreal in shaderLABS
float hash(inout uint s) {
    s = (1664525u * s + 1013904223u);
    return float(s & 0x00FFFFFF) / float(0x01000000);
}

vec2 WangHash(uvec2 seed) {
    seed = (seed ^ 61) ^ (seed >> 16);
    seed *= 9;
    seed = seed ^ (seed >> 4);
    seed *= 0x27d4eb2d;
    seed = seed ^ (seed >> 15);
    return vec2(seed) / 4294967296.0;
}

vec2 random_vec2(inout uvec2 seed) {
	vec2 r = WangHash(seed);
	seed *= 1046527;
	return r;
}

vec2 random_vec2(inout uint seed) {
	float u = hash(seed);
	float v = hash(seed);
	return vec2(u,v);
}

#endif
