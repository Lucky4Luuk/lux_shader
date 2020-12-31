#version 120

varying vec2 texcoord;
varying vec3 sunVec;

uniform float timeAngle;
uniform mat4 gbufferModelView;

const float sunPathRotation = -40.0;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
