#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform sampler2D normalmap;
uniform sampler2D specular;
uniform sampler2D shadow;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 normal;

uniform vec3 sunPosition;

#include "lighting/common.glsl"

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	color *= texture2D(lightmap, lmcoord);

	gl_FragData[0] = color; //gcolor
	gl_FragData[2] = vec4(to_uv(normal), to_uv(normalize(sunPosition))); //gnormal
}

//attribute vec3 at_tangent;
//at_tangent.xyz, cross(normal, at_tangent.xyz) * at_tangent.w
