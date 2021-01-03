#include "version.glsl"

flat in vec4 shadowMapData;

void main() {
	gl_FragData[0] = shadowMapData;
}
