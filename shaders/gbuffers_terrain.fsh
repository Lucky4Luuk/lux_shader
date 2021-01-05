#include "version.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform sampler2D normalmap;
uniform sampler2D specular;
uniform sampler2D shadow;

uniform mat4 gbufferModelViewInverse;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 normal;
varying vec3 lightDir;
flat in int blockID;

#include "lib/common.glsl"

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;

	gl_FragData[0] = color; //gcolor
	gl_FragData[2] = vec4(to_uv(normal), float(blockID) / 255.0, 1.0); //gnormal
}

//attribute vec3 at_tangent;
//at_tangent.xyz, cross(normal, at_tangent.xyz) * at_tangent.w
