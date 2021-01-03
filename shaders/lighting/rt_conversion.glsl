#ifndef _INCLUDE_RT_CONVERSION_GLSL_
#define _INCLUDE_RT_CONVERSION_GLSL_

#include "../settings.glsl"

vec2 ATLAS_SIZE = textureSize(TEXTURE_ATLAS, 0).xy;

vec2 atlasUVfromBlockUV(vec2 uv, vec2 blockUV) {
	vec2 uvScale = vec2(TEXTURE_RESOLUTION * TEXTURE_RESOLUTION) / ATLAS_SIZE * 0.5; //TODO: Check other resolutions
	vec2 finalUV = uv + blockUV * uvScale;
	return finalUV;
}

//From Octray
// Packing functions for sending midTexCoord through the shadow depth buffer
// Outputs a float in the range (-1.0, 1.0), which is what gl_Position.z takes in
const vec3 bits = vec3(0.0, 12.0, 12.0);
float packTexcoord(vec2 coord) {
	float matID = floor(255.0)*0;

	coord.rg = floor(coord.rg * exp2(bits.gb));

	float result = 0.0;

	result += matID;
	result += coord.r * exp2(bits.r);
	result += coord.g * exp2(bits.r + bits.g);

	result = exp2(bits.r + bits.g + bits.b) - result; // Flip the priority ordering of textures. This causes the top-grass texture to have priority over side-grass
	result = result / exp2(bits.r + bits.g + bits.b - 1.0) - 1.0; // Compact into range (-1.0, 1.0)

	return result;
}

// The unpacking function takes a float in the range (0.0, 1.0), since this is what is read from the depth buffer
vec2 unpackTexcoord(float enc) {
	enc *= exp2(bits.r + bits.g + bits.b); // Expand from range (-1.0, 1.0)
	enc  = exp2(bits.r + bits.g + bits.b) - enc; // Undo the priority flip

	vec2 coord;
	float matID = mod(floor(enc), exp2(bits.r));
	coord.r = mod(floor(enc / exp2(bits.r      )), exp2(bits.g));
	coord.g = mod(floor(enc / exp2(bits.r + bits.g)), exp2(bits.b));

	return coord * (exp2(-bits.gb));
}

#endif
