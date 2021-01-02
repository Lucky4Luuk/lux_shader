#include "version.glsl"

uniform sampler2D colortex0;

uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;

varying vec2 texcoord;

void main() {
	// if(texcoord.x > 0.5 || texcoord.y > 0.5) {
    //     gl_FragData[0] = texture2D(colortex0, texcoord);
    // }else {
	// 	vec4 shadow_data = texture2D(shadowcolor0, texcoord * 2);
    //     gl_FragData[0] = vec4(shadow_data.rgb * (1.0 - shadow_data.a), 1.0);
    // }
	gl_FragData[0] = texture2D(colortex0, texcoord);
}
