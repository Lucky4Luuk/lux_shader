#include "version.glsl"

in vec4 shadowMapData;

void main() {
	gl_FragData[0] = shadowMapData;
}
