#include "version.glsl"

varying vec2 texcoord;

uniform float timeAngle;
uniform mat4 gbufferModelView;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
