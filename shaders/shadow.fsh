#include "version.glsl"

flat in vec4 data0;
flat in vec4 data1; //Currently unused

void main() {
	gl_FragData[0] = data0;
}
