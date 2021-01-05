#include "version.glsl"

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 normal;
varying vec3 lightDir;
flat out int blockID;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;

attribute vec3 mc_Entity;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
	normal = normalize(gl_Normal);
	lightDir = normalize(shadowLightPosition);
	blockID = int(mc_Entity.x);
}
